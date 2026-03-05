import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taskstack/features/auth/domain/entities/auth_user.dart';
import 'package:taskstack/features/auth/domain/repositories/auth_repository.dart';
import 'package:taskstack/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:taskstack/features/sync/domain/repositories/sync_repository.dart';

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

// ── Notifier ──────────────────────────────────────────────────────────────────

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._repo, this._ref) : super(const AuthInitial()) {
    _restore();
  }

  final AuthRepository _repo;
  final Ref _ref;

  SyncRepository get _sync => _ref.read(syncRepositoryProvider);

  /// Restore session on cold start
  Future<void> _restore() async {
    final user = await _repo.currentUser();
    if (user != null) {
      state = AuthAuthenticated(user);
      _sync.pullCloudToLocal(); // fire-and-forget pull on session restore
    } else {
      state = const AuthUnauthenticated();
    }
  }

  Future<void> login({required String email, required String password}) async {
    state = const AuthLoading();
    try {
      final user = await _repo.login(email: email, password: password);
      state = AuthAuthenticated(user);
      _sync.pullCloudToLocal(); // fire-and-forget pull on login
    } on DioException catch (e) {
      final msg = _parseError(e);
      state = AuthUnauthenticated(msg);
    } catch (_) {
      state = const AuthUnauthenticated('An unexpected error occurred.');
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
      state = AuthAuthenticated(user);
      _sync.pushLocalToCloud(); // push any local data after first sign-up
    } on DioException catch (e) {
      final msg = _parseError(e);
      state = AuthUnauthenticated(msg);
    } catch (_) {
      state = const AuthUnauthenticated('An unexpected error occurred.');
    }
  }

  Future<void> logout() async {
    await _repo.logout();
    state = const AuthUnauthenticated();
  }

  /// Update cached user after profile edits
  void updateUser(AuthUser user) {
    if (state is AuthAuthenticated) {
      state = AuthAuthenticated(user);
    }
  }

  String _parseError(DioException e) {
    final data = e.response?.data;
    if (data is Map && data.containsKey('error')) {
      return data['error'].toString();
    }
    return e.message ?? 'Network error.';
  }
}

// ── Provider ──────────────────────────────────────────────────────────────────

final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.watch(authRepositoryProvider), ref);
});

/// Convenience: emit the authenticated user or null.
final currentUserProvider = Provider<AuthUser?>((ref) {
  final state = ref.watch(authNotifierProvider);
  return state is AuthAuthenticated ? state.user : null;
});
