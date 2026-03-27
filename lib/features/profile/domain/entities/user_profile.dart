/// Domain entity for viewing a user's public profile.
class UserProfile {
  const UserProfile({
    required this.id,
    required this.username,
    required this.displayName,
    this.bio,
    this.avatarUrl,
    this.isPublic = false,
    required this.createdAt,
  });

  final String id;
  final String username;
  final String displayName;
  final String? bio;
  final String? avatarUrl;
  final bool isPublic;
  final DateTime createdAt;

  /// Parse from Firestore document data (camelCase fields).
  factory UserProfile.fromFirestore(
    String uid,
    Map<String, dynamic> data,
  ) =>
      UserProfile(
        id: uid,
        username: data['username'] as String? ?? '',
        displayName: data['displayName'] as String? ?? data['username'] as String? ?? '',
        bio: data['bio'] as String?,
        avatarUrl: data['avatarUrl'] as String?,
        isPublic: data['isPublic'] as bool? ?? false,
        createdAt: data['createdAt'] != null
            ? DateTime.tryParse(data['createdAt'].toString()) ?? DateTime.now()
            : DateTime.now(),
      );

  /// Legacy JSON parser (kept for compatibility with any remaining usage).
  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        id: json['id'] as String? ?? '',
        username: json['username'] as String? ?? '',
        displayName:
            (json['displayName'] as String?) ??
            (json['display_name'] as String?) ??
            json['username'] as String? ??
            '',
        bio: json['bio'] as String?,
        avatarUrl: (json['avatarUrl'] as String?) ?? json['avatar_url'] as String?,
        isPublic: (json['isPublic'] as bool?) ?? (json['is_public'] as bool?) ?? false,
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
            : DateTime.now(),
      );
}
