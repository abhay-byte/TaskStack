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
        id: _stringValue(json, 'id'),
        name: _stringValue(json, 'name'),
        description: _nullableStringValue(json, 'description'),
        inviteCode:
            _nullableStringValue(json, 'invite_code') ??
            _nullableStringValue(json, 'inviteCode') ??
            '',
        createdAt:
            _dateTimeValue(json['created_at']) ??
            _dateTimeValue(json['createdAt']) ??
            DateTime.now(),
        role: _nullableStringValue(json, 'role'),
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
        id: _stringValue(json, 'id'),
        username: _stringValue(json, 'username'),
        displayName:
            _nullableStringValue(json, 'display_name') ??
            _nullableStringValue(json, 'displayName'),
        avatarUrl:
            _nullableStringValue(json, 'avatar_url') ??
            _nullableStringValue(json, 'avatarUrl'),
        role: _stringValue(json, 'role'),
        joinedAt:
            _dateTimeValue(json['joined_at']) ??
            _dateTimeValue(json['joinedAt']) ??
            DateTime.now(),
      );
}

String _stringValue(Map<String, dynamic> json, String key) {
  final value = json[key];
  return value?.toString() ?? '';
}

String? _nullableStringValue(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value == null) return null;
  final text = value.toString();
  return text.isEmpty ? null : text;
}

DateTime? _dateTimeValue(Object? value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
  try {
    final date = (value as dynamic).toDate();
    if (date is DateTime) return date;
  } catch (_) {}
  return null;
}
