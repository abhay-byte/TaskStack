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

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        id: json['id'] as String,
        username: json['username'] as String,
        displayName: (json['display_name'] as String?) ?? json['username'] as String,
        bio: json['bio'] as String?,
        avatarUrl: json['avatar_url'] as String?,
        isPublic: (json['is_public'] as bool?) ?? false,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}
