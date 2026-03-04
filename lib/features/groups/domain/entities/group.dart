/// Domain entity for a group and its members.
class Group {
  const Group({
    required this.id,
    required this.name,
    this.description,
    required this.inviteCode,
    required this.createdAt,
    this.role,
    this.members = const [],
    this.qrBase64,
  });

  final String id;
  final String name;
  final String? description;
  final String inviteCode;
  final DateTime createdAt;
  final String? role; // 'owner' | 'member'
  final List<GroupMember> members;
  final String? qrBase64;

  factory Group.fromJson(Map<String, dynamic> json) => Group(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String?,
        inviteCode: json['invite_code'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
        role: json['role'] as String?,
        members: (json['members'] as List<dynamic>?)
                ?.map((m) =>
                    GroupMember.fromJson(m as Map<String, dynamic>))
                .toList() ??
            [],
      );

  Group copyWith({String? qrBase64, List<GroupMember>? members}) => Group(
        id: id,
        name: name,
        description: description,
        inviteCode: inviteCode,
        createdAt: createdAt,
        role: role,
        members: members ?? this.members,
        qrBase64: qrBase64 ?? this.qrBase64,
      );
}

class GroupMember {
  const GroupMember({
    required this.id,
    required this.username,
    this.displayName,
    this.avatarUrl,
    required this.role,
    required this.joinedAt,
  });

  final String id;
  final String username;
  final String? displayName;
  final String? avatarUrl;
  final String role;
  final DateTime joinedAt;

  factory GroupMember.fromJson(Map<String, dynamic> json) => GroupMember(
        id: json['id'] as String,
        username: json['username'] as String,
        displayName: json['display_name'] as String?,
        avatarUrl: json['avatar_url'] as String?,
        role: json['role'] as String,
        joinedAt: DateTime.parse(json['joined_at'] as String),
      );
}
