/// Domain entity for a pending group invite.
class Invite {
  const Invite({
    required this.id,
    required this.status,
    required this.groupId,
    required this.groupName,
    required this.inviterUsername,
    required this.createdAt,
  });

  final String id;
  final String status;
  final String groupId;
  final String groupName;
  final String inviterUsername;
  final DateTime createdAt;

  factory Invite.fromJson(Map<String, dynamic> json) => Invite(
        id: json['id'] as String,
        status: json['status'] as String,
        groupId: json['group_id'] as String,
        groupName: json['group_name'] as String,
        inviterUsername: json['inviter_username'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}
