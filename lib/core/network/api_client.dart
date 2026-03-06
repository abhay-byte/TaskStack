import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taskstack/core/config/app_config.dart';
import 'package:taskstack/features/auth/data/repositories/auth_repository_impl.dart';

/// Retries up to [maxRetries] times when the server returns 502/503/504
/// (Render free-tier cold-start bounce). Waits [delay] between attempts.
class _RenderWakeInterceptor extends Interceptor {
  _RenderWakeInterceptor(
    this._dio, {
    this.maxRetries = 6,
    this.delay = const Duration(seconds: 10),
  });
  final Dio _dio;
  final int maxRetries;
  final Duration delay;

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final statusCode = err.response?.statusCode;
    final attempt = (err.requestOptions.extra['_retryCount'] as int?) ?? 0;

    debugPrint('[API] Error interceptor: status=$statusCode, attempt=$attempt');

    if ((statusCode == 502 || statusCode == 503 || statusCode == 504 ||
        err.type == DioExceptionType.connectionTimeout) &&
        attempt < maxRetries) {
      err.requestOptions.extra['_retryCount'] = attempt + 1;
      debugPrint('[API] Retrying (attempt ${attempt + 1}/$maxRetries)...');
      await Future.delayed(delay);
      try {
        final response = await _dio.fetch(err.requestOptions);
        handler.resolve(response);
      } catch (e) {
        handler.next(err);
      }
      return;
    }
    handler.next(err);
  }
}

/// Dio singleton wired with a JWT Bearer interceptor.
/// All feature repositories should depend on this provider.
final apiClientProvider = Provider<Dio>((ref) {
  final storage = ref.watch(storageProvider);

  final dio = Dio(BaseOptions(
    baseUrl: AppConfig.apiBaseUrl,
    connectTimeout: const Duration(seconds: 60),  // Increased for Render cold start
    receiveTimeout: const Duration(seconds: 30),
    headers: {'Content-Type': 'application/json'},
  ));

  // Add retry interceptor for Render cold start
  dio.interceptors.add(_RenderWakeInterceptor(dio));

  // ── JWT Interceptor ──────────────────────────────────────────────────────
  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) async {
      final token = await storage.read(key: 'auth_token');
      debugPrint('[API] Token from storage: ${token != null ? "present" : "null"}');
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
        debugPrint('[API] Added Authorization header');
      }
      handler.next(options);
    },
    onError: (error, handler) {
      debugPrint('[API] Error: ${error.message}');
      // 401 responses are propagated; auth notifier will catch and logout.
      handler.next(error);
    },
  ));

  return dio;
});
