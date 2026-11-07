import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/zuno_models.dart';

class ZunoRepository {
  ZunoRepository([SupabaseClient? client])
      : client = client ?? Supabase.instance.client;

  final SupabaseClient client;

  String get currentUserId {
    final id = client.auth.currentUser?.id;
    if (id == null) throw StateError('يجب تسجيل الدخول أولاً.');
    return id;
  }

  Future<List<ZunoVideo>> loadFeed({bool followingOnly = false}) async {
    final uid = currentUserId;
    final followingRows = await client
        .from('follows')
        .select('following_id')
        .eq('follower_id', uid)
        .limit(1000);
    final followingIds = <String>{
      for (final row in followingRows) row['following_id'] as String,
    };

    final List<Map<String, dynamic>> rows;
    if (followingOnly) {
      followingIds.add(uid);
      if (followingIds.isEmpty) return const [];
      rows = await client
          .from('videos')
          .select('id,user_id,video_url,caption,created_at')
          .inFilter('user_id', followingIds.toList())
          .order('created_at', ascending: false)
          .limit(40);
    } else {
      rows = await client
          .from('videos')
          .select('id,user_id,video_url,caption,created_at')
          .order('created_at', ascending: false)
          .limit(40);
    }
    return _hydrateVideos(rows, followingIds: followingIds);
  }

  Future<List<ZunoVideo>> searchVideos(String query) async {
    final clean = query.trim();
    if (clean.isEmpty) return const [];
    final uid = currentUserId;
    final followingRows = await client
        .from('follows')
        .select('following_id')
        .eq('follower_id', uid)
        .limit(1000);
    final followingIds = <String>{
      for (final row in followingRows) row['following_id'] as String,
    };
    final rows = await client
        .from('videos')
        .select('id,user_id,video_url,caption,created_at')
        .ilike('caption', '%$clean%')
        .order('created_at', ascending: false)
        .limit(20);
    return _hydrateVideos(rows, followingIds: followingIds);
  }

  Future<List<ZunoProfile>> searchProfiles(String query) async {
    final clean = query.trim();
    if (clean.isEmpty) return const [];
    const fields = 'id,username,display_name,full_name,avatar_url,bio';
    final byUsername = await client
        .from('profiles')
        .select(fields)
        .ilike('username', '%$clean%')
        .limit(15);
    final byName = await client
        .from('profiles')
        .select(fields)
        .ilike('display_name', '%$clean%')
        .limit(15);
    final unique = <String, Map<String, dynamic>>{};
    for (final row in [...byUsername, ...byName]) {
      unique[row['id'] as String] = row;
    }
    return unique.values.map(ZunoProfile.fromMap).toList();
  }

  Future<List<ZunoVideo>> _hydrateVideos(
    List<Map<String, dynamic>> rows, {
    required Set<String> followingIds,
  }) async {
    if (rows.isEmpty) return const [];
    final videoIds = rows.map((row) => row['id'] as String).toList();
    final userIds =
        rows.map((row) => row['user_id'] as String).toSet().toList();
    final profileRows = await client
        .from('profiles')
        .select('id,username,display_name,full_name,avatar_url,bio')
        .inFilter('id', userIds);
    final likesRows = await client
        .from('likes')
        .select('video_id,user_id')
        .inFilter('video_id', videoIds)
        .limit(5000);
    final commentRows = await client
        .from('comments')
        .select('video_id')
        .inFilter('video_id', videoIds)
        .limit(5000);
    final profiles = <String, Map<String, dynamic>>{
      for (final row in profileRows) row['id'] as String: row,
    };
    final likeCounts = <String, int>{};
    final commentCounts = <String, int>{};
    final likedIds = <String>{};
    final currentId = client.auth.currentUser?.id;
    for (final row in likesRows) {
      final videoId = row['video_id'] as String;
      likeCounts.update(videoId, (count) => count + 1, ifAbsent: () => 1);
      if (row['user_id'] == currentId) likedIds.add(videoId);
    }
    for (final row in commentRows) {
      final videoId = row['video_id'] as String;
      commentCounts.update(videoId, (count) => count + 1, ifAbsent: () => 1);
    }

    return rows.map((row) {
      final id = row['id'] as String;
      final userId = row['user_id'] as String;
      final profile = profiles[userId] ?? const <String, dynamic>{};
      final name =
          ((profile['display_name'] as String?)?.trim().isNotEmpty == true
                  ? (profile['display_name'] as String).trim()
                  : (profile['full_name'] as String?)?.trim()) ??
              '';
      final username = (profile['username'] as String?)?.trim() ?? '';
      return ZunoVideo(
        id: id,
        userId: userId,
        videoUrl: row['video_url'] as String,
        caption: (row['caption'] as String?) ?? '',
        createdAt: DateTime.tryParse((row['created_at'] as String?) ?? ''),
        creatorName: name.isEmpty ? 'مستخدم ZUNO' : name,
        username: username.isEmpty ? 'zuno_user' : username,
        avatarUrl: (profile['avatar_url'] as String?) ?? '',
        likeCount: likeCounts[id] ?? 0,
        commentCount: commentCounts[id] ?? 0,
        isLiked: likedIds.contains(id),
        isFollowing: followingIds.contains(userId),
      );
    }).toList();
  }

  Future<bool> toggleLike(String videoId) async {
    final uid = currentUserId;
    final row = await client
        .from('likes')
        .select('video_id')
        .eq('video_id', videoId)
        .eq('user_id', uid)
        .maybeSingle();
    if (row == null) {
      await client.from('likes').insert({'video_id': videoId, 'user_id': uid});
      return true;
    }
    await client
        .from('likes')
        .delete()
        .eq('video_id', videoId)
        .eq('user_id', uid);
    return false;
  }

  Future<bool> toggleFollow(String followingId) async {
    final uid = currentUserId;
    if (uid == followingId) throw StateError('لا يمكنك متابعة حسابك.');
    final row = await client
        .from('follows')
        .select('follower_id')
        .eq('follower_id', uid)
        .eq('following_id', followingId)
        .maybeSingle();
    if (row == null) {
      await client
          .from('follows')
          .insert({'follower_id': uid, 'following_id': followingId});
      return true;
    }
    await client
        .from('follows')
        .delete()
        .eq('follower_id', uid)
        .eq('following_id', followingId);
    return false;
  }

  Future<bool> isFollowing(String followingId) async {
    final row = await client
        .from('follows')
        .select('follower_id')
        .eq('follower_id', currentUserId)
        .eq('following_id', followingId)
        .maybeSingle();
    return row != null;
  }

  Future<List<ZunoComment>> loadComments(String videoId) async {
    final rows = await client
        .from('comments')
        .select('id,user_id,content,created_at')
        .eq('video_id', videoId)
        .order('created_at', ascending: false)
        .limit(100);
    if (rows.isEmpty) return const [];
    final userIds =
        rows.map((row) => row['user_id'] as String).toSet().toList();
    final profileRows = await client
        .from('profiles')
        .select('id,username,display_name,full_name')
        .inFilter('id', userIds);
    final profiles = <String, Map<String, dynamic>>{
      for (final row in profileRows) row['id'] as String: row,
    };
    return rows.map((row) {
      final profile =
          profiles[row['user_id'] as String] ?? const <String, dynamic>{};
      final displayName =
          ((profile['display_name'] as String?)?.trim().isNotEmpty == true
                  ? (profile['display_name'] as String).trim()
                  : (profile['full_name'] as String?)?.trim()) ??
              '';
      return ZunoComment(
        id: row['id'] as String,
        userId: row['user_id'] as String,
        username: (profile['username'] as String?) ?? 'zuno_user',
        displayName: displayName.isEmpty ? 'مستخدم ZUNO' : displayName,
        content: row['content'] as String,
        createdAt: DateTime.tryParse((row['created_at'] as String?) ?? ''),
      );
    }).toList();
  }

  Future<void> addComment(String videoId, String content) async {
    await client.from('comments').insert({
      'video_id': videoId,
      'user_id': currentUserId,
      'content': content.trim(),
    });
  }

  Future<void> publishVideo(
      {required String publicUrl, required String caption}) async {
    await client.from('videos').insert({
      'user_id': currentUserId,
      'video_url': publicUrl,
      'caption': caption.trim(),
    });
  }

  Future<Map<String, dynamic>?> loadMyProfile() async {
    return client
        .from('profiles')
        .select('id,username,display_name,full_name,avatar_url,bio')
        .eq('id', currentUserId)
        .maybeSingle();
  }

  Future<void> updateMyProfile(
      {required String displayName, required String bio}) async {
    final uid = currentUserId;
    await client.from('profiles').update({
      'display_name': displayName.trim(),
      'full_name': displayName.trim(),
      'bio': bio.trim(),
    }).eq('id', uid);
  }

  Future<Map<String, int>> loadMyStats() async {
    final uid = currentUserId;
    final followers = await client
        .from('follows')
        .select('follower_id')
        .eq('following_id', uid)
        .limit(5000);
    final following = await client
        .from('follows')
        .select('following_id')
        .eq('follower_id', uid)
        .limit(5000);
    final videos =
        await client.from('videos').select('id').eq('user_id', uid).limit(1000);
    var likes = 0;
    if (videos.isNotEmpty) {
      final videoIds = videos.map((row) => row['id'] as String).toList();
      final rows = await client
          .from('likes')
          .select('video_id')
          .inFilter('video_id', videoIds)
          .limit(5000);
      likes = rows.length;
    }
    return {
      'followers': followers.length,
      'following': following.length,
      'videos': videos.length,
      'likes': likes,
    };
  }
}
