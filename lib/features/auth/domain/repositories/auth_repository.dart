import 'package:taskstack/features/auth/domain/entities/auth_user.dart';

abstract class AuthRepository {
  /// Register a new account. Returns the created user.
  Future<AuthUser> register({
    required String username,
    required String email,
    required String password,
    String? displayName,
  });

  /// Login with email + password. Returns the logged-in user.
  Future<AuthUser> login({
    required String email,
    required String password,
  });

  /// Clear token + user from secure storage.
  Future<void> logout();

  /// Returns the currently stored user, or null if not logged in.
  Future<AuthUser?> currentUser();

  /// True if a JWT is stored.
  Future<bool> get isLoggedIn;

  /// Returns the stored raw JWT token, or null.
  Future<String?> token();
}
