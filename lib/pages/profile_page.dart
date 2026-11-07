import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/zuno_repository.dart';
import '../widgets/profile_avatar.dart';
import '../zuno_theme.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key, required this.repository});
  final ZunoRepository repository;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _displayName = TextEditingController();
  final _bio = TextEditingController();
  Map<String, dynamic>? _profile;
  Map<String, int> _stats = const {};
  bool _loading = true;
  bool _saving = false;
  bool _editing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _displayName.dispose();
    _bio.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final profileFuture = widget.repository.loadMyProfile();
      final statsFuture = widget.repository.loadMyStats();
      final profile = await profileFuture;
      final stats = await statsFuture;
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _stats = stats;
        _displayName.text =
            ((profile?['display_name'] as String?)?.trim().isNotEmpty == true
                    ? (profile?['display_name'] as String).trim()
                    : (profile?['full_name'] as String?)?.trim()) ??
                '';
        _bio.text = (profile?['bio'] as String?) ?? '';
        _loading = false;
      });
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = 'تعذّر تحميل الملف الشخصي: $error';
          _loading = false;
        });
      }
    }
  }

  Future<void> _save() async {
    if (_displayName.text.trim().isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('اكتب اسمًا ظاهرًا.')));
      return;
    }
    setState(() => _saving = true);
    try {
      await widget.repository
          .updateMyProfile(displayName: _displayName.text, bio: _bio.text);
      if (mounted) {
        setState(() {
          _editing = false;
          _profile = {
            ...?_profile,
            'display_name': _displayName.text.trim(),
            'full_name': _displayName.text.trim(),
            'bio': _bio.text.trim(),
          };
        });
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم حفظ الملف الشخصي.')));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('تعذّر حفظ التعديلات: $error')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _cancelEdit() {
    final profile = _profile;
    _displayName.text =
        ((profile?['display_name'] as String?)?.trim().isNotEmpty == true
                ? (profile?['display_name'] as String).trim()
                : (profile?['full_name'] as String?)?.trim()) ??
            '';
    _bio.text = (profile?['bio'] as String?) ?? '';
    setState(() => _editing = false);
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final username = (_profile?['username'] as String?) ?? 'zuno_user';
    final displayName =
        ((_profile?['display_name'] as String?)?.trim().isNotEmpty == true
                ? (_profile?['display_name'] as String).trim()
                : (_profile?['full_name'] as String?)?.trim()) ??
            '';
    final avatarUrl = (_profile?['avatar_url'] as String?) ?? '';

    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: zunoGold));
    }
    if (_error != null && _profile == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh),
                label: const Text('إعادة المحاولة')),
          ]),
        ),
      );
    }

    return RefreshIndicator(
      color: zunoGold,
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
        children: [
          Row(
            children: [
              const Expanded(
                  child: Text('حسابي',
                      style: TextStyle(
                          fontSize: 26, fontWeight: FontWeight.bold))),
              IconButton(
                tooltip: 'تسجيل الخروج',
                onPressed: () => Supabase.instance.client.auth.signOut(),
                icon: const Icon(Icons.logout, color: zunoMuted),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Center(child: ProfileAvatar(url: avatarUrl, radius: 46)),
          const SizedBox(height: 12),
          Center(
              child: Text(displayName.isEmpty ? 'مستخدم ZUNO' : displayName,
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold))),
          Center(
              child:
                  Text('@$username', style: const TextStyle(color: zunoMuted))),
          if ((user?.email ?? '').isNotEmpty) ...[
            const SizedBox(height: 3),
            Center(
                child: Text(user!.email!,
                    style: const TextStyle(color: zunoMuted, fontSize: 12))),
          ],
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
            decoration: BoxDecoration(
                color: zunoPanel, borderRadius: BorderRadius.circular(16)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _Stat(value: _stats['followers'] ?? 0, label: 'متابع'),
                _Stat(value: _stats['following'] ?? 0, label: 'يتابع'),
                _Stat(value: _stats['videos'] ?? 0, label: 'مقطع'),
                _Stat(value: _stats['likes'] ?? 0, label: 'إعجاب'),
              ],
            ),
          ),
          const SizedBox(height: 22),
          if (_editing) ...[
            TextField(
                controller: _displayName,
                maxLength: 60,
                decoration: const InputDecoration(labelText: 'الاسم الظاهر')),
            const SizedBox(height: 12),
            TextField(
                controller: _bio,
                maxLength: 160,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'نبذة عنك')),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(
                  child: FilledButton(
                      onPressed: _saving ? null : _save,
                      child:
                          Text(_saving ? 'جارٍ الحفظ...' : 'حفظ التعديلات'))),
              const SizedBox(width: 10),
              OutlinedButton(
                  onPressed: _saving ? null : _cancelEdit,
                  child: const Text('إلغاء')),
            ]),
          ] else ...[
            Card(
              color: zunoPanel,
              child: ListTile(
                leading: const Icon(Icons.notes_rounded, color: zunoGold),
                title: Text((_profile?['bio'] as String?)?.isNotEmpty == true
                    ? _profile!['bio'] as String
                    : 'أضف نبذة قصيرة عنك'),
                trailing: const Icon(Icons.edit_outlined, color: zunoMuted),
                onTap: () => setState(() => _editing = true),
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => setState(() => _editing = true),
              icon: const Icon(Icons.edit_outlined),
              label: const Text('تعديل الملف الشخصي'),
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: Colors.redAccent)),
          ],
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});
  final int value;
  final String label;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Text('$value',
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Text(label, style: const TextStyle(color: zunoMuted, fontSize: 12)),
        ],
      );
}
