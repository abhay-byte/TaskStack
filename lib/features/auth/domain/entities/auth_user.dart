/// Domain entity representing a logged-in user.
class AuthUser {
  const AuthUser({
    required this.id,
    required this.username,
    required this.email,
    required this.displayName,
    this.avatarUrl,
    this.bio,
    this.isPublic = false,
  });

  final String id;
  final String username;
  final String email;
  final String displayName;
  final String? avatarUrl;
  final String? bio;
  final bool isPublic;

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
        id: json['id'] as String,
        username: json['username'] as String,
        email: json['email'] as String,
        displayName: (json['display_name'] as String?) ?? json['username'] as String,
        avatarUrl: json['avatar_url'] as String?,
        bio: json['bio'] as String?,
        isPublic: (json['is_public'] as bool?) ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'email': email,
        'display_name': displayName,
        'avatar_url': avatarUrl,
        'bio': bio,
        'is_public': isPublic,
      };

  AuthUser copyWith({
    String? id,
    String? username,
    String? email,
    String? displayName,
    String? avatarUrl,
    String? bio,
    bool? isPublic,
  }) =>
      AuthUser(
        id: id ?? this.id,
        username: username ?? this.username,
        email: email ?? this.email,
        displayName: displayName ?? this.displayName,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        bio: bio ?? this.bio,
        isPublic: isPublic ?? this.isPublic,
      );
}
