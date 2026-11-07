import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/zuno_repository.dart';
import '../zuno_theme.dart';

class UploadPage extends StatefulWidget {
  const UploadPage(
      {super.key, required this.repository, required this.onPublished});
  final ZunoRepository repository;
  final VoidCallback onPublished;

  @override
  State<UploadPage> createState() => _UploadPageState();
}

class _UploadPageState extends State<UploadPage> {
  final _picker = ImagePicker();
  final _caption = TextEditingController();
  XFile? _selected;
  bool _busy = false;

  @override
  void dispose() {
    _caption.dispose();
    super.dispose();
  }

  Future<void> _chooseVideo() async {
    try {
      final video = await _picker.pickVideo(
          source: ImageSource.gallery, maxDuration: const Duration(minutes: 2));
      if (video != null && mounted) setState(() => _selected = video);
    } catch (error) {
      if (mounted) _showMessage('تعذّر اختيار الفيديو: $error', error: true);
    }
  }

  String? _contentType(String extension) => switch (extension) {
        'mp4' => 'video/mp4',
        'mov' => 'video/quicktime',
        'webm' => 'video/webm',
        _ => null,
      };

  Future<void> _publish() async {
    final file = _selected;
    if (file == null || _busy) return;
    final extension =
        file.name.contains('.') ? file.name.split('.').last.toLowerCase() : '';
    final contentType = _contentType(extension);
    if (contentType == null) {
      _showMessage('اختر ملف MP4 أو MOV أو WebM.', error: true);
      return;
    }

    setState(() => _busy = true);
    String? objectPath;
    try {
      final size = await File(file.path).length();
      if (size > 100 * 1024 * 1024) {
        throw StateError('حجم الفيديو أكبر من 100 ميغابايت.');
      }
      final userId = widget.repository.currentUserId;
      final safeName = file.name.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
      objectPath = '$userId/${DateTime.now().millisecondsSinceEpoch}_$safeName';
      final storage = Supabase.instance.client.storage.from('zuno-videos');
      await storage.upload(
        objectPath,
        File(file.path),
        fileOptions: FileOptions(contentType: contentType, upsert: false),
      );
      final publicUrl = storage.getPublicUrl(objectPath);
      await widget.repository
          .publishVideo(publicUrl: publicUrl, caption: _caption.text);
      if (!mounted) return;
      _showMessage('تم نشر الفيديو بنجاح.');
      _selected = null;
      _caption.clear();
      widget.onPublished();
    } catch (error) {
      if (objectPath != null) {
        try {
          await Supabase.instance.client.storage
              .from('zuno-videos')
              .remove([objectPath]);
        } catch (_) {}
      }
      if (mounted) _showMessage('تعذّر نشر الفيديو: $error', error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showMessage(String message, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(message),
          backgroundColor: error ? Colors.red.shade700 : null),
    );
  }

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
        children: [
          const Icon(Icons.video_call_rounded, color: zunoGold, size: 66),
          const SizedBox(height: 10),
          const Text('شارك لحظتك',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('ارفع فيديو قصير ليظهر في خلاصة ZUNO.',
              textAlign: TextAlign.center, style: TextStyle(color: zunoMuted)),
          const SizedBox(height: 26),
          OutlinedButton.icon(
            onPressed: _busy ? null : _chooseVideo,
            icon: const Icon(Icons.video_library_outlined),
            label: Text(_selected == null
                ? 'اختيار فيديو من الهاتف'
                : 'اختيار فيديو آخر'),
          ),
          if (_selected != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                  color: zunoPanel, borderRadius: BorderRadius.circular(14)),
              child: Row(
                children: [
                  const Icon(Icons.movie_outlined, color: zunoGold),
                  const SizedBox(width: 10),
                  Expanded(
                      child: Text(_selected!.name,
                          maxLines: 2, overflow: TextOverflow.ellipsis)),
                  IconButton(
                      onPressed:
                          _busy ? null : () => setState(() => _selected = null),
                      icon: const Icon(Icons.close)),
                ],
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _caption,
              maxLength: 300,
              maxLines: 3,
              decoration: const InputDecoration(
                  labelText: 'وصف الفيديو', hintText: 'اكتب وصفًا قصيرًا...'),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _busy ? null : _publish,
              icon: _busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.cloud_upload_outlined),
              label: Text(_busy ? 'جارٍ رفع الفيديو...' : 'نشر الفيديو'),
            ),
          ],
          const SizedBox(height: 20),
          const Text('الحد الأعلى 100 ميغابايت. المقاطع تكون عامة في الخلاصة.',
              textAlign: TextAlign.center,
              style: TextStyle(color: zunoMuted, fontSize: 12)),
        ],
      );
}
