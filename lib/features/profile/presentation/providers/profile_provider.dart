import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taskstack/core/network/api_client.dart';
import 'package:taskstack/features/auth/domain/entities/auth_user.dart';
import 'package:taskstack/features/profile/domain/entities/user_profile.dart';

// ── Profile Repository ─────────────────────────────────────────────────────────

class ProfileRepository {
  ProfileRepository(this._dio);
  final Dio _dio;

  Future<UserProfile> fetchMe() async {
    final res = await _dio.get('/users/me');
    return UserProfile.fromJson(res.data as Map<String, dynamic>);
  }

  Future<AuthUser> updateMe({
    String? displayName,
    String? bio,
    String? avatarUrl,
    bool? isPublic,
  }) async {
    final res = await _dio.put('/users/me', data: {
      if (displayName != null) 'displayName': displayName,
      if (bio != null) 'bio': bio,
      if (avatarUrl != null) 'avatarUrl': avatarUrl,
      if (isPublic != null) 'isPublic': isPublic,
    });
    return AuthUser.fromJson(res.data as Map<String, dynamic>);
  }

  Future<UserProfile> fetchUser(String userId) async {
    final res = await _dio.get('/users/$userId');
    return UserProfile.fromJson(res.data as Map<String, dynamic>);
  }
}

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(ref.watch(apiClientProvider));
});

// ── Profile Providers ─────────────────────────────────────────────────────────

final myProfileProvider =
    FutureProvider.autoDispose<UserProfile>((ref) {
  return ref.watch(profileRepositoryProvider).fetchMe();
});

final userProfileProvider =
    FutureProvider.autoDispose.family<UserProfile, String>((ref, userId) {
  return ref.watch(profileRepositoryProvider).fetchUser(userId);
});
