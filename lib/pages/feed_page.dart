import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/zuno_repository.dart';
import '../models/zuno_models.dart';
import '../widgets/video_clip_card.dart';
import '../zuno_theme.dart';

class FeedPage extends StatefulWidget {
  const FeedPage({super.key, required this.repository, this.isVisible = true});
  final ZunoRepository repository;
  final bool isVisible;

  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  late Future<List<ZunoVideo>> _videos;
  bool _followingOnly = false;
  int _activeIndex = 0;

  @override
  void initState() {
    super.initState();
    _videos = widget.repository.loadFeed();
  }

  Future<void> _reload() async {
    final next = widget.repository.loadFeed(followingOnly: _followingOnly);
    setState(() {
      _activeIndex = 0;
      _videos = next;
    });
    await next;
  }

  void _selectFollowing(bool value) {
    if (_followingOnly == value) return;
    setState(() {
      _followingOnly = value;
      _activeIndex = 0;
      _videos = widget.repository.loadFeed(followingOnly: value);
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id ?? '';
    return FutureBuilder<List<ZunoVideo>>(
      future: _videos,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(
              child: CircularProgressIndicator(color: zunoGold));
        }
        if (snapshot.hasError) {
          return _ErrorState(message: 'تعذّر تحميل المقاطع.', onRetry: _reload);
        }
        final videos = snapshot.data ?? const <ZunoVideo>[];
        if (videos.isEmpty) return _EmptyFeed(onRefresh: _reload);
        return Stack(
          fit: StackFit.expand,
          children: [
            RefreshIndicator(
              color: zunoGold,
              onRefresh: _reload,
              child: PageView.builder(
                key: ValueKey(_followingOnly),
                scrollDirection: Axis.vertical,
                itemCount: videos.length,
                onPageChanged: (index) => setState(() => _activeIndex = index),
                itemBuilder: (context, index) => VideoClipCard(
                  key: ValueKey(videos[index].id),
                  video: videos[index],
                  active: index == _activeIndex && widget.isVisible,
                  currentUserId: currentUserId,
                  repository: widget.repository,
                ),
              ),
            ),
            const Positioned(
              top: 10,
              left: 16,
              child: Text(
                'ZUNO',
                style: TextStyle(
                    color: zunoGold,
                    fontWeight: FontWeight.w900,
                    fontSize: 22,
                    letterSpacing: 2),
              ),
            ),
            Positioned(
              top: 4,
              right: 12,
              child: SegmentedButton<bool>(
                showSelectedIcon: false,
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.resolveWith(
                    (states) => states.contains(WidgetState.selected)
                        ? zunoGold.withValues(alpha: .9)
                        : Colors.black.withValues(alpha: .24),
                  ),
                  foregroundColor: WidgetStateProperty.resolveWith(
                    (states) => states.contains(WidgetState.selected)
                        ? zunoInk
                        : Colors.white,
                  ),
                  visualDensity: VisualDensity.compact,
                  padding: const WidgetStatePropertyAll(
                      EdgeInsets.symmetric(horizontal: 8)),
                ),
                segments: const [
                  ButtonSegment(value: false, label: Text('لك')),
                  ButtonSegment(value: true, label: Text('أتابع')),
                ],
                selected: {_followingOnly},
                onSelectionChanged: (value) => _selectFollowing(value.first),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _EmptyFeed extends StatelessWidget {
  const _EmptyFeed({required this.onRefresh});
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) => RefreshIndicator(
        color: zunoGold,
        onRefresh: onRefresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 150),
            Icon(Icons.video_library_outlined, size: 64, color: zunoGold),
            SizedBox(height: 18),
            Center(
                child: Text('لسه مفيش مقاطع',
                    style:
                        TextStyle(fontSize: 22, fontWeight: FontWeight.bold))),
            SizedBox(height: 8),
            Center(
                child: Text('كن أول من يشارك فيديو على ZUNO.',
                    style: TextStyle(color: zunoMuted))),
          ],
        ),
      );
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_outlined, color: zunoMuted, size: 48),
              const SizedBox(height: 12),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('إعادة المحاولة')),
            ],
          ),
        ),
      );
}
