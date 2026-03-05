import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:taskstack/core/config/app_config.dart';
import 'package:taskstack/features/auth/domain/entities/auth_user.dart';
import 'package:taskstack/features/auth/domain/repositories/auth_repository.dart';

const _kToken = 'auth_token';
const _kUser  = 'auth_user';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._dio, this._storage);

  final Dio _dio;
  final FlutterSecureStorage _storage;

  @override
  Future<AuthUser> register({
    required String username,
    required String email,
    required String password,
    String? displayName,
  }) async {
    final res = await _dio.post(
      '/auth/register',
      data: {
        'username': username,
        'email': email,
        'password': password,
        if (displayName != null && displayName.isNotEmpty)
          'displayName': displayName,
      },
    );
    final user = AuthUser.fromJson(res.data['user'] as Map<String, dynamic>);
    await _persist(res.data['token'] as String, user);
    return user;
  }

  @override
  Future<AuthUser> login({
    required String email,
    required String password,
  }) async {
    final res = await _dio.post('/auth/login', data: {
      'email': email,
      'password': password,
    });
    final user = AuthUser.fromJson(res.data['user'] as Map<String, dynamic>);
    await _persist(res.data['token'] as String, user);
    return user;
  }

  @override
  Future<void> logout() async {
    await _storage.delete(key: _kToken);
    await _storage.delete(key: _kUser);
  }

  @override
  Future<AuthUser?> currentUser() async {
    final raw = await _storage.read(key: _kUser);
    if (raw == null) return null;
    return AuthUser.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  @override
  Future<bool> get isLoggedIn async =>
      (await _storage.read(key: _kToken)) != null;

  @override
  Future<String?> token() => _storage.read(key: _kToken);

  Future<void> _persist(String token, AuthUser user) async {
    await _storage.write(key: _kToken, value: token);
    await _storage.write(key: _kUser, value: jsonEncode(user.toJson()));
  }
}

// ── Providers ─────────────────────────────────────────────────────────────────

final _storageProvider = Provider<FlutterSecureStorage>((_) =>
    const FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
    ));

/// Retries up to [maxRetries] times when the server returns 502
/// (Render free-tier cold-start bounce). Waits [delay] between attempts.
class _RenderWakeInterceptor extends Interceptor {
  const _RenderWakeInterceptor({this.maxRetries = 6, this.delay = const Duration(seconds: 5)});
  final int maxRetries;
  final Duration delay;

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final statusCode = err.response?.statusCode;
    final attempt = (err.requestOptions.extra['_retryCount'] as int?) ?? 0;

    if ((statusCode == 502 || statusCode == 503 || statusCode == 504) &&
        attempt < maxRetries) {
      err.requestOptions.extra['_retryCount'] = attempt + 1;
      await Future.delayed(delay);
      try {
        // fetch() replays the exact same RequestOptions (full URL + headers
        // already resolved) without needing a new Dio configuration.
        final response = await Dio().fetch(err.requestOptions);
        handler.resolve(response);
      } catch (e) {
        handler.next(err);
      }
      return;
    }
    handler.next(err);
  }
}

/// Base Dio instance — interceptor added in api_client.dart which wraps this.
/// Timeouts are generous (90 s) to survive Render free-tier cold starts.
/// _RenderWakeInterceptor retries on 502/503/504 up to 6× (≈30 s window).
final _baseDioProvider = Provider<Dio>((ref) {
  final dio = Dio(BaseOptions(
    baseUrl: AppConfig.apiBaseUrl,
    connectTimeout: const Duration(seconds: 90),
    receiveTimeout: const Duration(seconds: 90),
    headers: {'Content-Type': 'application/json'},
  ));
  dio.interceptors.add(const _RenderWakeInterceptor());
  return dio;
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    ref.watch(_baseDioProvider),
    ref.watch(_storageProvider),
  );
});

final storageProvider = _storageProvider;
