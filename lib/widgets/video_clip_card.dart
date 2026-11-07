import 'dart:async';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../data/zuno_repository.dart';
import '../models/zuno_models.dart';
import '../zuno_theme.dart';
import 'comments_sheet.dart';
import 'profile_avatar.dart';

class VideoClipCard extends StatefulWidget {
  const VideoClipCard({
    super.key,
    required this.video,
    required this.active,
    required this.currentUserId,
    required this.repository,
  });

  final ZunoVideo video;
  final bool active;
  final String currentUserId;
  final ZunoRepository repository;

  @override
  State<VideoClipCard> createState() => _VideoClipCardState();
}

class _VideoClipCardState extends State<VideoClipCard> {
  VideoPlayerController? _controller;
  bool _playerError = false;
  bool _liked = false;
  bool _following = false;
  bool _busyLike = false;
  bool _busyFollow = false;
  late int _likeCount;
  late int _commentCount;

  @override
  void initState() {
    super.initState();
    _liked = widget.video.isLiked;
    _following = widget.video.isFollowing;
    _likeCount = widget.video.likeCount;
    _commentCount = widget.video.commentCount;
    if (widget.active) _initializePlayer();
  }

  @override
  void didUpdateWidget(covariant VideoClipCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.video.id != widget.video.id) {
      _liked = widget.video.isLiked;
      _following = widget.video.isFollowing;
      _likeCount = widget.video.likeCount;
      _commentCount = widget.video.commentCount;
    }
    if (oldWidget.active != widget.active) {
      if (widget.active) {
        _initializePlayer();
      } else {
        _releasePlayer();
      }
    }
  }

  Future<void> _initializePlayer() async {
    if (_controller != null || _playerError || !widget.active) return;
    final controller =
        VideoPlayerController.networkUrl(Uri.parse(widget.video.videoUrl));
    _controller = controller;
    try {
      await controller.initialize();
      if (!mounted || !widget.active || controller != _controller) {
        await controller.dispose();
        return;
      }
      await controller.setLooping(true);
      await controller.play();
      if (mounted) setState(() {});
    } catch (_) {
      if (mounted) setState(() => _playerError = true);
      await controller.dispose();
      if (_controller == controller) _controller = null;
    }
  }

  void _releasePlayer() {
    final controller = _controller;
    _controller = null;
    if (controller != null) {
      unawaited(controller.pause());
      unawaited(controller.dispose());
    }
  }

  @override
  void dispose() {
    _releasePlayer();
    super.dispose();
  }

  Future<void> _togglePlayback() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    if (controller.value.isPlaying) {
      await controller.pause();
    } else {
      await controller.play();
    }
    if (mounted) setState(() {});
  }

  Future<void> _toggleLike() async {
    if (_busyLike) return;
    final wasLiked = _liked;
    setState(() {
      _busyLike = true;
      _liked = !wasLiked;
      _likeCount += wasLiked ? -1 : 1;
    });
    try {
      final serverState = await widget.repository.toggleLike(widget.video.id);
      if (mounted && serverState != _liked) {
        setState(() {
          _likeCount += serverState ? 1 : -1;
          _liked = serverState;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _liked = wasLiked;
          _likeCount += wasLiked ? 1 : -1;
        });
        _showError('تعذّر تحديث الإعجاب: $error');
      }
    } finally {
      if (mounted) setState(() => _busyLike = false);
    }
  }

  Future<void> _toggleFollow() async {
    if (_busyFollow) return;
    final wasFollowing = _following;
    setState(() {
      _busyFollow = true;
      _following = !wasFollowing;
    });
    try {
      final serverState =
          await widget.repository.toggleFollow(widget.video.userId);
      if (mounted) setState(() => _following = serverState);
    } catch (error) {
      if (mounted) {
        setState(() => _following = wasFollowing);
        _showError('تعذّرت متابعة الحساب: $error');
      }
    } finally {
      if (mounted) setState(() => _busyFollow = false);
    }
  }

  Future<void> _openComments() async {
    final added = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: zunoPanel,
      builder: (_) => CommentsSheet(
          videoId: widget.video.id, repository: widget.repository),
    );
    if (added == true && mounted) setState(() => _commentCount++);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    return GestureDetector(
      onTap: _togglePlayback,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(color: zunoInk),
          if (controller?.value.isInitialized == true)
            _VideoSurface(controller: controller!)
          else if (_playerError)
            const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.videocam_off_outlined, color: zunoMuted, size: 48),
                  SizedBox(height: 10),
                  Text('تعذّر تشغيل هذا المقطع',
                      style: TextStyle(color: Colors.white)),
                ],
              ),
            )
          else
            const Center(child: CircularProgressIndicator(color: zunoGold)),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x66000000),
                  Colors.transparent,
                  Color(0xB8000000)
                ],
                stops: [0, .38, 1],
              ),
            ),
          ),
          Positioned(
            right: 12,
            bottom: 88,
            child: Column(
              children: [
                ProfileAvatar(url: widget.video.avatarUrl, radius: 23),
                if (widget.video.userId != widget.currentUserId) ...[
                  const SizedBox(height: 5),
                  _CircleAction(
                    icon: _following ? Icons.check : Icons.add,
                    color: _following ? Colors.white : zunoGold,
                    size: 22,
                    onTap: _busyFollow ? null : _toggleFollow,
                    tooltip: _following ? 'إلغاء المتابعة' : 'متابعة',
                  ),
                ],
                const SizedBox(height: 20),
                _CircleAction(
                  icon: _liked ? Icons.favorite : Icons.favorite_border,
                  color: _liked ? Colors.redAccent : Colors.white,
                  onTap: _busyLike ? null : _toggleLike,
                  tooltip: 'إعجاب',
                ),
                Text(_compactCount(_likeCount),
                    style: const TextStyle(color: Colors.white, fontSize: 12)),
                const SizedBox(height: 18),
                _CircleAction(
                  icon: Icons.mode_comment_outlined,
                  color: Colors.white,
                  onTap: _openComments,
                  tooltip: 'التعليقات',
                ),
                Text(_compactCount(_commentCount),
                    style: const TextStyle(color: Colors.white, fontSize: 12)),
              ],
            ),
          ),
          Positioned(
            left: 18,
            right: 80,
            bottom: 28,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('@${widget.video.username}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 5),
                Text(widget.video.creatorName,
                    style:
                        const TextStyle(color: Colors.white70, fontSize: 13)),
                if (widget.video.caption.trim().isNotEmpty) ...[
                  const SizedBox(height: 7),
                  Text(widget.video.caption,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style:
                          const TextStyle(color: Colors.white, fontSize: 14)),
                ],
              ],
            ),
          ),
          if (controller?.value.isInitialized == true &&
              !controller!.value.isPlaying)
            const Center(
                child: Icon(Icons.play_arrow_rounded,
                    color: Colors.white70, size: 78)),
        ],
      ),
    );
  }

  String _compactCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return '$count';
  }
}

class _VideoSurface extends StatelessWidget {
  const _VideoSurface({required this.controller});
  final VideoPlayerController controller;

  @override
  Widget build(BuildContext context) {
    final size = controller.value.size;
    final width =
        size.width == 0 ? MediaQuery.sizeOf(context).width : size.width;
    final height =
        size.height == 0 ? MediaQuery.sizeOf(context).height : size.height;
    return FittedBox(
      fit: BoxFit.cover,
      child: SizedBox(
          width: width, height: height, child: VideoPlayer(controller)),
    );
  }
}

class _CircleAction extends StatelessWidget {
  const _CircleAction({
    required this.icon,
    required this.color,
    required this.onTap,
    required this.tooltip,
    this.size = 28,
  });

  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  final String tooltip;
  final double size;

  @override
  Widget build(BuildContext context) => IconButton(
        tooltip: tooltip,
        onPressed: onTap,
        iconSize: size,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 42, minHeight: 42),
        icon: Icon(icon, color: color),
      );
}
