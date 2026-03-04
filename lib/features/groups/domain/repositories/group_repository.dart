import 'package:taskstack/features/groups/domain/entities/group.dart';
import 'package:taskstack/features/groups/domain/entities/invite.dart';

abstract class GroupRepository {
  Future<List<Group>> fetchMyGroups();
  Future<Group> createGroup({required String name, String? description});
  Future<Group> fetchGroup(String groupId);
  Future<String?> fetchGroupQr(String groupId); // returns base64 data URL
  Future<void> joinByCode(String inviteCode);
  Future<void> inviteByUsername(String groupId, String username);

  Future<List<Invite>> fetchInvites();
  Future<void> acceptInvite(String inviteId);
  Future<void> rejectInvite(String inviteId);
}
