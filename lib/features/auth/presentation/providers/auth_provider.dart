import 'package:firebase_auth/firebase_auth.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taskstack/core/providers/guest_mode_provider.dart';
import 'package:taskstack/features/auth/domain/entities/auth_user.dart';
import 'package:taskstack/features/auth/domain/repositories/auth_repository.dart';
import 'package:taskstack/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:taskstack/features/sync/domain/repositories/sync_repository.dart';
import 'package:taskstack/features/sync/data/repositories/sync_repository_impl.dart';

// ── State ─────────────────────────────────────────────────────────────────────

sealed class AuthState {
  const AuthState();
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthAuthenticated extends AuthState {
  const AuthAuthenticated(this.user);
  final AuthUser user;
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated([this.errorMessage]);
  final String? errorMessage;
}

/// User skipped login and is using the app offline (no cloud account).
class AuthGuest extends AuthState {
  const AuthGuest();
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    // Listen to Firebase auth state changes reactively
    _listenToAuthStream();
    return const AuthInitial();
  }

  AuthRepository get _repo => ref.read(authRepositoryProvider);
  SyncRepository get _sync => ref.read(syncRepositoryProvider);

  void _listenToAuthStream() {
    // Subscribes to Firebase authStateChanges — fires on login/logout/token-refresh
    ref.onDispose(
      FirebaseAuth.instance.authStateChanges().listen((firebaseUser) async {
        if (state is AuthLoading) return; // Let explicit calls finish first
        if (firebaseUser == null) {
          if (state is! AuthGuest) {
            state = const AuthUnauthenticated();
          }
        } else {
          final user = await _repo.currentUser();
          if (user != null && state is! AuthAuthenticated) {
            state = AuthAuthenticated(user);
            _sync.pullCloudToLocal(); // fire-and-forget on session restore
          }
        }
      }).cancel,
    );
  }

  /// Enter guest / offline mode — skips authentication entirely.
  void continueAsGuest() {
    ref.read(isGuestModeProvider.notifier).state = true;
    state = const AuthGuest();
  }

  Future<void> login({required String email, required String password}) async {
    final wasGuest = state is AuthGuest;
    state = const AuthLoading();
    try {
      final user = await _repo.login(email: email, password: password);
      ref.read(isGuestModeProvider.notifier).state = false;
      state = AuthAuthenticated(user);
      if (wasGuest) {
        _sync.pushLocalToCloud();
      } else {
        _sync.pullCloudToLocal();
      }
    } on FirebaseAuthException catch (e) {
      state = AuthUnauthenticated(e.message ?? 'Authentication error.');
    } catch (e) {
      state = AuthUnauthenticated(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> signInWithGoogle() async {
    final wasGuest = state is AuthGuest;
    state = const AuthLoading();
    try {
      final user = await _repo.signInWithGoogle();
      ref.read(isGuestModeProvider.notifier).state = false;
      state = AuthAuthenticated(user);
      if (wasGuest) {
        _sync.pushLocalToCloud();
      } else {
        _sync.pullCloudToLocal();
      }
    } on FirebaseAuthException catch (e) {
      state = AuthUnauthenticated(e.message ?? 'Google sign-in error.');
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      if (msg.contains('cancelled')) {
        state = const AuthUnauthenticated(); // silent cancel
      } else {
        state = AuthUnauthenticated(msg);
      }
    }
  }

  Future<void> register({
    required String username,
    required String email,
    required String password,
    String? displayName,
  }) async {
    state = const AuthLoading();
    try {
      final user = await _repo.register(
        username: username,
        email: email,
        password: password,
        displayName: displayName,
      );
      ref.read(isGuestModeProvider.notifier).state = false;
      state = AuthAuthenticated(user);
      _sync.pushLocalToCloud(); // push local data (including any guest data)
    } on FirebaseAuthException catch (e) {
      state = AuthUnauthenticated(e.message ?? 'Authentication error.');
    } catch (e) {
      state = AuthUnauthenticated(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> logout() async {
    await _repo.logout();
    ref.read(isGuestModeProvider.notifier).state = false;
    state = const AuthUnauthenticated();
  }

  /// Permanently delete the account and all cloud data, then sign out locally.
  Future<void> deleteAccount() async {
    state = const AuthLoading();
    try {
      await _repo.deleteAccount();
      ref.read(isGuestModeProvider.notifier).state = false;
      state = const AuthUnauthenticated();
    } catch (e) {
      // Restore authenticated state so user can try again
      final user = await _repo.currentUser();
      final msg = e.toString().replaceFirst('Exception: ', '');
      state = user != null ? AuthAuthenticated(user) : AuthUnauthenticated(msg);
      rethrow;
    }
  }

  /// Update cached user after profile edits
  void updateUser(AuthUser user) {
    if (state is AuthAuthenticated) {
      state = AuthAuthenticated(user);
    }
  }
}

// ── Provider ──────────────────────────────────────────────────────────────────

final authNotifierProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);

/// Convenience: emit the authenticated user or null.
final currentUserProvider = Provider<AuthUser?>((ref) {
  final state = ref.watch(authNotifierProvider);
  return state is AuthAuthenticated ? state.user : null;
});

/// True when the user is in guest / offline mode.
final isGuestProvider = Provider<bool>((ref) {
  return ref.watch(authNotifierProvider) is AuthGuest;
});
