import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/zuno_repository.dart';
import '../models/zuno_models.dart';
import '../widgets/profile_avatar.dart';
import '../widgets/video_clip_card.dart';
import '../zuno_theme.dart';

class DiscoverPage extends StatefulWidget {
  const DiscoverPage({super.key, required this.repository});
  final ZunoRepository repository;

  @override
  State<DiscoverPage> createState() => _DiscoverPageState();
}

class _DiscoverPageState extends State<DiscoverPage> {
  final _query = TextEditingController();
  List<ZunoProfile> _profiles = const [];
  List<ZunoVideo> _videos = const [];
  bool _loading = false;
  String? _error;
  bool _searched = false;

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  Future<void> _search(String value) async {
    final query = value.trim();
    if (query.isEmpty) {
      setState(() {
        _profiles = const [];
        _videos = const [];
        _searched = false;
        _error = null;
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
      _searched = true;
    });
    try {
      final profiles = await widget.repository.searchProfiles(query);
      final videos = await widget.repository.searchVideos(query);
      if (!mounted) return;
      setState(() {
        _profiles = profiles;
        _videos = videos;
      });
    } catch (error) {
      if (mounted) setState(() => _error = 'تعذّر إكمال البحث: $error');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
        children: [
          const Text('اكتشف',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 14),
          TextField(
            controller: _query,
            textInputAction: TextInputAction.search,
            onSubmitted: _search,
            decoration: InputDecoration(
              hintText: 'ابحث عن حساب أو مقطع',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(
                  onPressed: () => _search(_query.text),
                  icon: const Icon(Icons.arrow_forward_rounded)),
            ),
          ),
          const SizedBox(height: 16),
          if (_loading)
            const Center(
                child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(color: zunoGold))),
          if (_error != null)
            Text(_error!, style: const TextStyle(color: Colors.redAccent)),
          if (_searched &&
              !_loading &&
              _error == null &&
              _profiles.isEmpty &&
              _videos.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 36),
              child: Text('لا توجد نتائج. جرّب كلمة أخرى.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: zunoMuted)),
            ),
          if (_profiles.isNotEmpty) ...[
            const _SectionTitle(title: 'الحسابات'),
            ..._profiles.map((profile) => _ProfileResultTile(
                profile: profile, repository: widget.repository)),
          ],
          if (_videos.isNotEmpty) ...[
            const SizedBox(height: 10),
            const _SectionTitle(title: 'المقاطع'),
            ..._videos.map((video) =>
                _VideoResultTile(video: video, repository: widget.repository)),
          ],
          if (!_searched && !_loading)
            const Padding(
              padding: EdgeInsets.only(top: 30),
              child: Column(
                children: [
                  Icon(Icons.travel_explore, size: 48, color: zunoGold),
                  SizedBox(height: 12),
                  Text('ابحث عن اسم مستخدم أو كلمة في وصف فيديو.'),
                ],
              ),
            ),
        ],
      );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});
  final String title;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(title,
            style: const TextStyle(
                color: zunoGold, fontSize: 17, fontWeight: FontWeight.bold)),
      );
}

class _ProfileResultTile extends StatefulWidget {
  const _ProfileResultTile({required this.profile, required this.repository});
  final ZunoProfile profile;
  final ZunoRepository repository;
  @override
  State<_ProfileResultTile> createState() => _ProfileResultTileState();
}

class _ProfileResultTileState extends State<_ProfileResultTile> {
  late Future<bool> _following;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _following = widget.repository.isFollowing(widget.profile.id);
  }

  Future<void> _toggle() async {
    setState(() => _busy = true);
    try {
      final next = await widget.repository.toggleFollow(widget.profile.id);
      if (mounted) setState(() => _following = Future.value(next));
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('تعذّرت المتابعة: $error')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSelf =
        widget.profile.id == Supabase.instance.client.auth.currentUser?.id;
    return Card(
      color: zunoPanel,
      child: ListTile(
        leading: ProfileAvatar(url: widget.profile.avatarUrl),
        title: Text(widget.profile.displayName),
        subtitle: Text('@${widget.profile.username}',
            style: const TextStyle(color: zunoMuted)),
        trailing: isSelf
            ? const SizedBox.shrink()
            : FutureBuilder<bool>(
                future: _following,
                builder: (context, snapshot) {
                  final follows = snapshot.data ?? false;
                  return OutlinedButton(
                    onPressed: _busy ? null : _toggle,
                    child: Text(_busy
                        ? '...'
                        : follows
                            ? 'متابَعون'
                            : 'متابعة'),
                  );
                },
              ),
      ),
    );
  }
}

class _VideoResultTile extends StatelessWidget {
  const _VideoResultTile({required this.video, required this.repository});
  final ZunoVideo video;
  final ZunoRepository repository;

  @override
  Widget build(BuildContext context) => Card(
        color: zunoPanel,
        child: ListTile(
          leading: const CircleAvatar(
              backgroundColor: zunoInk,
              child: Icon(Icons.play_arrow, color: zunoGold)),
          title: Text(video.caption.isEmpty ? 'مقطع بدون وصف' : video.caption,
              maxLines: 2, overflow: TextOverflow.ellipsis),
          subtitle: Text('@${video.username}',
              style: const TextStyle(color: zunoMuted)),
          trailing: const Icon(Icons.chevron_left),
          onTap: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => Scaffold(
              appBar: AppBar(title: Text('@${video.username}')),
              body: VideoClipCard(
                video: video,
                active: true,
                currentUserId:
                    Supabase.instance.client.auth.currentUser?.id ?? '',
                repository: repository,
              ),
            ),
          )),
        ),
      );
}
