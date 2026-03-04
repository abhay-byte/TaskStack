import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taskstack/core/network/api_client.dart';
import 'package:taskstack/features/groups/domain/entities/group.dart';
import 'package:taskstack/features/groups/domain/entities/invite.dart';
import 'package:taskstack/features/groups/domain/repositories/group_repository.dart';

class GroupRepositoryImpl implements GroupRepository {
  GroupRepositoryImpl(this._dio);
  final Dio _dio;

  @override
  Future<List<Group>> fetchMyGroups() async {
    final res = await _dio.get('/groups');
    return (res.data as List)
        .map((g) => Group.fromJson(g as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<Group> createGroup({required String name, String? description}) async {
    final res = await _dio.post('/groups', data: {
      'name': name,
      if (description != null && description.isNotEmpty)
        'description': description,
    });
    return Group.fromJson(res.data as Map<String, dynamic>);
  }

  @override
  Future<Group> fetchGroup(String groupId) async {
    final res = await _dio.get('/groups/$groupId');
    return Group.fromJson(res.data as Map<String, dynamic>);
  }

  @override
  Future<String?> fetchGroupQr(String groupId) async {
    final res = await _dio.get('/groups/$groupId/qr');
    return res.data['qr_base64'] as String?;
  }

  @override
  Future<void> joinByCode(String inviteCode) async {
    await _dio.post('/groups/join', data: {'invite_code': inviteCode});
  }

  @override
  Future<void> inviteByUsername(String groupId, String username) async {
    await _dio.post('/groups/$groupId/invite', data: {'username': username});
  }

  @override
  Future<List<Invite>> fetchInvites() async {
    final res = await _dio.get('/invites');
    return (res.data as List)
        .map((i) => Invite.fromJson(i as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> acceptInvite(String inviteId) async {
    await _dio.post('/invites/$inviteId/accept');
  }

  @override
  Future<void> rejectInvite(String inviteId) async {
    await _dio.post('/invites/$inviteId/reject');
  }
}

// ── Providers ─────────────────────────────────────────────────────────────────

final groupRepositoryProvider = Provider<GroupRepository>((ref) {
  return GroupRepositoryImpl(ref.watch(apiClientProvider));
});
