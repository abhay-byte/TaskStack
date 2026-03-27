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

  /// Sign in with Google. Creates a Firestore profile on first sign-in.
  /// [username] is required only when registering a new Google account.
  Future<AuthUser> signInWithGoogle({String? username});

  /// Sign out the current user (and clears Google credential state).
  Future<void> logout();

  /// Permanently delete the account and all associated cloud data.
  Future<void> deleteAccount();

  /// Returns the currently logged-in user, or null if not authenticated.
  Future<AuthUser?> currentUser();

  /// Stream that emits auth state changes (user or null).
  Stream<AuthUser?> get authStateChanges;
}
