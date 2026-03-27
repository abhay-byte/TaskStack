import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taskstack/features/auth/domain/entities/auth_user.dart';
import 'package:taskstack/features/profile/domain/entities/user_profile.dart';

// ── Profile Repository ─────────────────────────────────────────────────────────

class ProfileRepository {
  ProfileRepository(this._firestore, this._auth);
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  String get _uid => _auth.currentUser!.uid;

  Future<UserProfile> fetchMe() async {
    final doc = await _firestore.collection('users').doc(_uid).get();
    if (!doc.exists) throw Exception('Profile not found.');
    return UserProfile.fromFirestore(doc.id, doc.data()!);
  }

  Future<AuthUser> updateMe({
    String? displayName,
    String? bio,
    String? avatarUrl,
    bool? isPublic,
  }) async {
    final updates = <String, dynamic>{};
    if (displayName != null) updates['displayName'] = displayName;
    if (bio != null) updates['bio'] = bio;
    if (avatarUrl != null) updates['avatarUrl'] = avatarUrl;
    if (isPublic != null) updates['isPublic'] = isPublic;

    if (updates.isNotEmpty) {
      await _firestore.collection('users').doc(_uid).update(updates);
    }

    final doc = await _firestore.collection('users').doc(_uid).get();
    final data = doc.data()!;
    return AuthUser(
      id: _uid,
      username: data['username'] as String? ?? '',
      email: data['email'] as String? ?? '',
      displayName: data['displayName'] as String? ?? '',
      avatarUrl: data['avatarUrl'] as String?,
      bio: data['bio'] as String?,
      isPublic: data['isPublic'] as bool? ?? false,
    );
  }

  Future<UserProfile> fetchUser(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    if (!doc.exists) throw Exception('User not found.');
    final data = doc.data()!;

    // Visibility: public profiles OR shared group membership
    final isPublic = data['isPublic'] as bool? ?? false;
    if (!isPublic && userId != _uid) {
      // Check shared group membership
      final myGroups = await _firestore
          .collection('group_members')
          .where('userId', isEqualTo: _uid)
          .get();
      final myGroupIds =
          myGroups.docs.map((d) => d.data()['groupId'] as String).toSet();

      final theirGroups = await _firestore
          .collection('group_members')
          .where('userId', isEqualTo: userId)
          .get();
      final theirGroupIds =
          theirGroups.docs.map((d) => d.data()['groupId'] as String).toSet();

      if (myGroupIds.intersection(theirGroupIds).isEmpty) {
        throw Exception('Profile is private.');
      }
    }
    return UserProfile.fromFirestore(userId, data);
  }
}

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(
    FirebaseFirestore.instance,
    FirebaseAuth.instance,
  );
});

// ── Profile Providers ─────────────────────────────────────────────────────────

final myProfileProvider = FutureProvider.autoDispose<UserProfile>((ref) {
  return ref.watch(profileRepositoryProvider).fetchMe();
});

final userProfileProvider =
    FutureProvider.autoDispose.family<UserProfile, String>((ref, userId) {
  return ref.watch(profileRepositoryProvider).fetchUser(userId);
});
