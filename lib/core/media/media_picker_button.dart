import 'package:flutter/material.dart';

import 'media_service.dart';

class MediaPickerButton extends StatefulWidget {
  final String path;
  final Future<void> Function(String url) onUploaded;
  final IconData icon;
  final String tooltip;
  final bool enabled;

  const MediaPickerButton({
    super.key,
    required this.path,
    required this.onUploaded,
    this.icon = Icons.add_a_photo,
    this.tooltip = 'Fotoğraf ekle',
    this.enabled = true,
  });

  @override
  State<MediaPickerButton> createState() => _MediaPickerButtonState();
}

class _MediaPickerButtonState extends State<MediaPickerButton> {
  bool _busy = false;

  Future<void> _handlePickAndUpload() async {
    if (_busy || !widget.enabled) return;

    setState(() => _busy = true);

    try {
      final data = await MediaService.pickImage();
      if (data == null) return;

      final url = await MediaService.upload(
        data: data,
        path: widget.path,
      );

      await widget.onUploaded(url);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fotoğraf yüklendi.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fotoğraf yüklenemedi: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: (_busy || !widget.enabled) ? null : _handlePickAndUpload,
      tooltip: widget.tooltip,
      icon: _busy
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(widget.icon),
    );
  }
}
