import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taskstack/features/groups/domain/entities/group.dart';
import 'package:taskstack/features/groups/domain/entities/invite.dart';
import 'package:taskstack/features/groups/domain/repositories/group_repository.dart';
import 'package:uuid/uuid.dart';

class GroupRepositoryImpl implements GroupRepository {
  GroupRepositoryImpl(this._firestore, this._auth, this._rtdb);

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final FirebaseDatabase _rtdb;

  String get _uid => _auth.currentUser!.uid;

  // ── Groups ─────────────────────────────────────────────────────────────────

  @override
  Future<List<Group>> fetchMyGroups() async {
    final memberSnaps =
        await _firestore
            .collection('group_members')
            .where('userId', isEqualTo: _uid)
            .get();

    final groups = <Group>[];
    for (final memberDoc in memberSnaps.docs) {
      final data = memberDoc.data();
      final groupId =
          _stringOrNull(data['groupId']) ?? _groupIdFromMembershipDocId(memberDoc.id);
      if (groupId == null) {
        debugPrint(
          '[Groups] Skipping malformed membership ${memberDoc.id}: missing groupId. data=$data',
        );
        continue;
      }
      final groupSnap =
          await _firestore.collection('groups').doc(groupId).get();
      if (!groupSnap.exists) {
        debugPrint(
          '[Groups] Membership ${memberDoc.id} points to missing group $groupId. data=$data',
        );
        continue;
      }
      final g = groupSnap.data()!;
      debugPrint(
        '[Groups] Loaded group $groupId from membership ${memberDoc.id}: group=$g membership=$data',
      );

      // Fetch members for accurate count in list view
      final groupMemberSnaps =
          await _firestore
              .collection('group_members')
              .where('groupId', isEqualTo: groupId)
              .get();

      final members = <Map<String, dynamic>>[];
      for (final m in groupMemberSnaps.docs) {
        final mData = m.data();
        final userSnap =
            await _firestore.collection('users').doc(mData['userId']).get();
        if (!userSnap.exists) continue;
        final u = userSnap.data()!;
        members.add({
          'id': mData['userId'],
          'username': u['username'],
          'display_name': u['displayName'],
          'avatar_url': u['avatarUrl'],
          'role': mData['role'],
          'joined_at': mData['joinedAt'],
        });
      }

      groups.add(
        Group.fromJson({
          ...g,
          'id': groupId,
          'role': _stringOrNull(data['role']) ?? 'member',
          'joined_at': data['joinedAt'],
          'members': members,
        }),
      );
    }
    return groups;
  }

  @override
  Future<Group> createGroup({required String name, String? description}) async {
    final groupId = const Uuid().v4();
    final inviteCode = _generateInviteCode();
    final now = FieldValue.serverTimestamp();

    final batch = _firestore.batch();
    final groupRef = _firestore.collection('groups').doc(groupId);
    final memberRef = _firestore
        .collection('group_members')
        .doc('${groupId}_$_uid');

    batch.set(groupRef, {
      'name': name,
      'description': description,
      'inviteCode': inviteCode,
      'createdBy': _uid,
      'createdAt': now,
    });
    batch.set(memberRef, {
      'groupId': groupId,
      'userId': _uid,
      'role': 'owner',
      'joinedAt': now,
    });
    await batch.commit();

    // Mirror invite codes into RTDB when available, but don't fail group
    // creation if that secondary write is unavailable.
    try {
      await _rtdb.ref('inviteCodes/$inviteCode').set(groupId);
    } catch (_) {}

    return Group.fromJson({
      'id': groupId,
      'name': name,
      'description': description,
      'invite_code': inviteCode,
      'role': 'owner',
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  @override
  Future<Group> fetchGroup(String groupId) async {
    // Verify membership
    final memberDoc =
        await _firestore
            .collection('group_members')
            .doc('${groupId}_$_uid')
            .get();
    if (!memberDoc.exists) throw Exception('Not a member of this group.');

    final groupSnap = await _firestore.collection('groups').doc(groupId).get();
    if (!groupSnap.exists) throw Exception('Group not found.');
    final g = groupSnap.data()!;

    // Fetch members
    final memberSnaps =
        await _firestore
            .collection('group_members')
            .where('groupId', isEqualTo: groupId)
            .get();

    final members = <Map<String, dynamic>>[];
    for (final m in memberSnaps.docs) {
      final mData = m.data();
      final userSnap =
          await _firestore.collection('users').doc(mData['userId']).get();
      if (!userSnap.exists) continue;
      final u = userSnap.data()!;
      members.add({
        'id': mData['userId'],
        'username': u['username'],
        'display_name': u['displayName'],
        'avatar_url': u['avatarUrl'],
        'role': mData['role'],
        'joined_at': mData['joinedAt'],
      });
    }

    return Group.fromJson({
      ...g,
      'id': groupId,
      'invite_code': g['inviteCode'],
      'members': members,
    });
  }

  @override
  Future<String?> fetchGroupQr(String groupId) async {
    final groupSnap = await _firestore.collection('groups').doc(groupId).get();
    if (!groupSnap.exists) return null;
    final inviteCode = groupSnap.data()!['inviteCode'] as String;
    // Return the deep-link that the QR encodes (qr_flutter renders it in the UI)
    return 'taskstack://join?code=$inviteCode';
  }

  @override
  Future<void> joinByCode(String inviteCode) async {
    final groupId = await _lookupGroupIdByInviteCode(inviteCode);

    // Check not already a member
    final existing =
        await _firestore
            .collection('group_members')
            .doc('${groupId}_$_uid')
            .get();
    if (existing.exists) throw Exception('Already a member of this group.');

    await _firestore.collection('group_members').doc('${groupId}_$_uid').set({
      'groupId': groupId,
      'userId': _uid,
      'role': 'member',
      'joinedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> inviteByUsername(String groupId, String username) async {
    // Check sender is member
    final senderDoc =
        await _firestore
            .collection('group_members')
            .doc('${groupId}_$_uid')
            .get();
    if (!senderDoc.exists) throw Exception('You are not a member.');

    // Find target user by username
    final usernameDoc =
        await _firestore.collection('usernames').doc(username).get();
    if (!usernameDoc.exists) throw Exception('User not found.');
    final targetUid = usernameDoc.data()!['uid'] as String;

    if (targetUid == _uid) throw Exception('Cannot invite yourself.');

    // Check not already in group
    final existingMember =
        await _firestore
            .collection('group_members')
            .doc('${groupId}_$targetUid')
            .get();
    if (existingMember.exists) throw Exception('User is already a member.');

    // Create invite (unique on groupId + targetUid)
    final inviteId = '${groupId}_$targetUid';
    final existing = await _firestore.collection('invites').doc(inviteId).get();
    if (existing.exists) throw Exception('Invite already pending.');

    await _firestore.collection('invites').doc(inviteId).set({
      'groupId': groupId,
      'invitedBy': _uid,
      'invitedUserId': targetUid,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Track invite ID on the group doc so the owner can clean it up on delete.
    try {
      await _firestore.collection('groups').doc(groupId).update({
        'inviteIds': FieldValue.arrayUnion([inviteId]),
      });
    } catch (_) {}
  }

  // ── Invites ────────────────────────────────────────────────────────────────

  @override
  Future<List<Invite>> fetchInvites() async {
    final snaps =
        await _firestore
            .collection('invites')
            .where('invitedUserId', isEqualTo: _uid)
            .where('status', isEqualTo: 'pending')
            .get();

    final invites = <Invite>[];
    for (final doc in snaps.docs) {
      final data = doc.data();
      final groupSnap =
          await _firestore.collection('groups').doc(data['groupId']).get();
      final inviterSnap =
          await _firestore.collection('users').doc(data['invitedBy']).get();

      invites.add(
        Invite.fromJson({
          'id': doc.id,
          'status': data['status'],
          'created_at': data['createdAt']?.toString(),
          'group_id': data['groupId'],
          'group_name': groupSnap.data()?['name'] ?? '',
          'inviter_id': data['invitedBy'],
          'inviter_username': inviterSnap.data()?['username'] ?? '',
        }),
      );
    }
    return invites;
  }

  @override
  Future<void> acceptInvite(String inviteId) async {
    await _firestore.runTransaction((tx) async {
      final inviteRef = _firestore.collection('invites').doc(inviteId);
      final inviteSnap = await tx.get(inviteRef);
      if (!inviteSnap.exists || inviteSnap.data()!['status'] != 'pending') {
        throw Exception('Invite not found or already processed.');
      }
      final groupId = inviteSnap.data()!['groupId'] as String;
      final memberRef = _firestore
          .collection('group_members')
          .doc('${groupId}_$_uid');
      tx.set(memberRef, {
        'groupId': groupId,
        'userId': _uid,
        'role': 'member',
        'joinedAt': FieldValue.serverTimestamp(),
      });
      tx.update(inviteRef, {'status': 'accepted'});
    });
  }

  @override
  Future<void> rejectInvite(String inviteId) async {
    final inviteRef = _firestore.collection('invites').doc(inviteId);
    final snap = await inviteRef.get();
    if (!snap.exists || snap.data()!['status'] != 'pending') {
      throw Exception('Invite not found or already processed.');
    }
    await inviteRef.update({'status': 'rejected'});
  }

  @override
  Future<void> deleteGroup(String groupId) async {
    // ── Verify ownership ───────────────────────────────────────────────────
    final membershipDoc =
        await _firestore
            .collection('group_members')
            .doc('${groupId}_$_uid')
            .get();
    if (!membershipDoc.exists || membershipDoc.data()?['role'] != 'owner') {
      throw Exception('Only the group owner can delete this group.');
    }

    final groupSnap =
        await _firestore.collection('groups').doc(groupId).get();
    if (!groupSnap.exists) throw Exception('Group not found.');
    final groupData = groupSnap.data()!;
    final inviteCode = groupData['inviteCode'] as String?;

    // Collect invite IDs tracked on the group doc (avoids querying invites
    // by groupId, which Firestore rules reject).
    final trackedInviteIds =
        (groupData['inviteIds'] as List<dynamic>?)
            ?.cast<String>() ??
        <String>[];

    // ── Collect group_members to delete ────────────────────────────────────
    final memberSnaps =
        await _firestore
            .collection('group_members')
            .where('groupId', isEqualTo: groupId)
            .get();

    // Firestore batches are capped at 500 writes. Most groups are tiny,
    // but split into chunks to stay safely under the limit.
    const batchLimit = 400;
    final allDeletes = <DocumentReference>[
      _firestore.collection('groups').doc(groupId),
      ...memberSnaps.docs.map((d) => d.reference),
      ...trackedInviteIds.map((id) => _firestore.collection('invites').doc(id)),
    ];

    for (var i = 0; i < allDeletes.length; i += batchLimit) {
      final batch = _firestore.batch();
      final chunk = allDeletes.skip(i).take(batchLimit);
      for (final ref in chunk) {
        batch.delete(ref);
      }
      await batch.commit();
    }

    // ── Clean up RTDB invite code mapping (best-effort) ────────────────────
    if (inviteCode != null && inviteCode.isNotEmpty) {
      try {
        await _rtdb.ref('inviteCodes/$inviteCode').remove();
      } catch (_) {}
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  String _generateInviteCode() {
    // 12 hex chars (same as the old Postgres `encode(gen_random_bytes(6),'hex')`)
    final rand = DateTime.now().millisecondsSinceEpoch;
    final uuid = const Uuid().v4().replaceAll('-', '');
    return (uuid + rand.toRadixString(16)).substring(0, 12);
  }

  Future<String> _lookupGroupIdByInviteCode(String inviteCode) async {
    try {
      final snapshot = await _rtdb.ref('inviteCodes/$inviteCode').get();
      if (snapshot.exists && snapshot.value is String) {
        return snapshot.value! as String;
      }
    } catch (_) {}

    final query =
        await _firestore
            .collection('groups')
            .where('inviteCode', isEqualTo: inviteCode)
            .limit(1)
            .get();
    if (query.docs.isEmpty) {
      throw Exception('Invalid invite code.');
    }
    return query.docs.first.id;
  }

  String? _stringOrNull(Object? value) {
    if (value == null) return null;
    final text = value.toString();
    return text.isEmpty ? null : text;
  }

  String? _groupIdFromMembershipDocId(String docId) {
    final separator = docId.indexOf('_');
    if (separator <= 0) return null;
    return docId.substring(0, separator);
  }
}

// ── Providers ──────────────────────────────────────────────────────────────────

final groupRepositoryProvider = Provider<GroupRepository>((ref) {
  return GroupRepositoryImpl(
    FirebaseFirestore.instance,
    FirebaseAuth.instance,
    FirebaseDatabase.instance,
  );
});
