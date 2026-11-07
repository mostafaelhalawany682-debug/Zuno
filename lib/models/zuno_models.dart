class ZunoProfile {
  const ZunoProfile({
    required this.id,
    required this.username,
    required this.displayName,
    required this.avatarUrl,
    required this.bio,
  });

  final String id;
  final String username;
  final String displayName;
  final String avatarUrl;
  final String bio;

  factory ZunoProfile.fromMap(Map<String, dynamic> row) {
    final username = (row['username'] as String?)?.trim() ?? '';
    final displayName =
        ((row['display_name'] as String?)?.trim().isNotEmpty == true
                ? row['display_name'] as String
                : (row['full_name'] as String?)?.trim()) ??
            '';
    return ZunoProfile(
      id: row['id'] as String,
      username: username.isEmpty ? 'zuno_user' : username,
      displayName: displayName.isEmpty ? 'مستخدم ZUNO' : displayName,
      avatarUrl: (row['avatar_url'] as String?) ?? '',
      bio: (row['bio'] as String?) ?? '',
    );
  }
}

class ZunoVideo {
  const ZunoVideo({
    required this.id,
    required this.userId,
    required this.videoUrl,
    required this.caption,
    required this.createdAt,
    required this.creatorName,
    required this.username,
    required this.avatarUrl,
    required this.likeCount,
    required this.commentCount,
    required this.isLiked,
    required this.isFollowing,
  });

  final String id;
  final String userId;
  final String videoUrl;
  final String caption;
  final DateTime? createdAt;
  final String creatorName;
  final String username;
  final String avatarUrl;
  final int likeCount;
  final int commentCount;
  final bool isLiked;
  final bool isFollowing;
}

class ZunoComment {
  const ZunoComment({
    required this.id,
    required this.userId,
    required this.username,
    required this.displayName,
    required this.content,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String username;
  final String displayName;
  final String content;
  final DateTime? createdAt;
}
