import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taskstack/core/config/app_config.dart';
import 'package:taskstack/features/auth/data/repositories/auth_repository_impl.dart';

/// Dio singleton wired with a JWT Bearer interceptor.
/// All feature repositories should depend on this provider.
final apiClientProvider = Provider<Dio>((ref) {
  final storage = ref.watch(storageProvider);

  final dio = Dio(BaseOptions(
    baseUrl: AppConfig.apiBaseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 15),
    headers: {'Content-Type': 'application/json'},
  ));

  // ── JWT Interceptor ──────────────────────────────────────────────────────
  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) async {
      final token = await storage.read(key: 'auth_token');
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
      handler.next(options);
    },
    onError: (error, handler) {
      // 401 responses are propagated; auth notifier will catch and logout.
      handler.next(error);
    },
  ));

  return dio;
});
