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
        id: _stringValue(json, 'id'),
        status: _stringValue(json, 'status'),
        groupId:
            _nullableStringValue(json, 'group_id') ??
            _nullableStringValue(json, 'groupId') ??
            '',
        groupName:
            _nullableStringValue(json, 'group_name') ??
            _nullableStringValue(json, 'groupName') ??
            '',
        inviterUsername:
            _nullableStringValue(json, 'inviter_username') ??
            _nullableStringValue(json, 'inviterUsername') ??
            '',
        createdAt:
            _dateTimeValue(json['created_at']) ??
            _dateTimeValue(json['createdAt']) ??
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
