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

/// Base Dio instance — interceptor added in api_client.dart which wraps this.
/// Timeouts are generous (60 s) to survive Render free-tier cold starts.
final _baseDioProvider = Provider<Dio>((ref) {
  final dio = Dio(BaseOptions(
    baseUrl: AppConfig.apiBaseUrl,
    connectTimeout: const Duration(seconds: 60),
    receiveTimeout: const Duration(seconds: 60),
    headers: {'Content-Type': 'application/json'},
  ));
  return dio;
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    ref.watch(_baseDioProvider),
    ref.watch(_storageProvider),
  );
});

final storageProvider = _storageProvider;
