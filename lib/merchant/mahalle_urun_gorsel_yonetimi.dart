import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class MahalleUrunGorselYonetimiSayfasi extends StatefulWidget {
  final String urunId;
  final String urunAdi;

  const MahalleUrunGorselYonetimiSayfasi({
    super.key,
    required this.urunId,
    required this.urunAdi,
  });

  @override
  State<MahalleUrunGorselYonetimiSayfasi> createState() =>
      _MahalleUrunGorselYonetimiSayfasiState();
}

class _MahalleUrunGorselYonetimiSayfasiState
    extends State<MahalleUrunGorselYonetimiSayfasi> {
  static const Color _gold = Color(0xFFFFB300);

  final ImagePicker _picker = ImagePicker();
  bool _busy = false;

  DocumentReference<Map<String, dynamic>> get _docRef =>
      FirebaseFirestore.instance.collection('urunler').doc(widget.urunId);

  List<String> _readImages(Map<String, dynamic> data) {
    final raw = data['images'];
    if (raw is List) {
      return raw
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }

    final fallback = (data['img'] ?? '').toString().trim();
    if (fallback.isNotEmpty) return [fallback];
    return <String>[];
  }

  String _storagePathFromDownloadUrl(String url) {
    final uri = Uri.parse(url);
    final encodedPath = uri.pathSegments.last; // o/<encodedPath>
    return Uri.decodeComponent(encodedPath);
  }

  Future<String> _uploadBytes(Uint8List bytes, String ownerId) async {
    final ts = DateTime.now().millisecondsSinceEpoch;
    final ref =
        FirebaseStorage.instance.ref().child('urunler/$ownerId/urun_$ts.jpg');

    await ref.putData(
      bytes,
      SettableMetadata(contentType: 'image/jpeg'),
    );

    return ref.getDownloadURL();
  }

  Future<void> _addPhoto(Map<String, dynamic> data) async {
    if (_busy) return;

    try {
      setState(() => _busy = true);

      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (picked == null) return;

      final bytes = await picked.readAsBytes();

      final ownerId =
          (data['ownerId'] ?? data['sellerId'] ?? data['dukkanId'] ?? 'unknown')
              .toString()
              .trim();

      final uploadedUrl = await _uploadBytes(bytes, ownerId);

      final currentImages = _readImages(data);
      currentImages.add(uploadedUrl);

      await _docRef.update({
        'images': currentImages,
        'img': currentImages.isNotEmpty ? currentImages.first : '',
        'photoCount': currentImages.length,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Fotoğraf eklendi. Toplam: ${currentImages.length}'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Fotoğraf eklenemedi: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _deletePhoto(Map<String, dynamic> data, int index) async {
    if (_busy) return;

    try {
      setState(() => _busy = true);

      final currentImages = _readImages(data);
      if (index < 0 || index >= currentImages.length) return;

      final targetUrl = currentImages[index];

      try {
        final path = _storagePathFromDownloadUrl(targetUrl);
        await FirebaseStorage.instance.ref().child(path).delete();
      } catch (_) {
        try {
          await FirebaseStorage.instance.refFromURL(targetUrl).delete();
        } catch (_) {}
      }

      currentImages.removeAt(index);

      await _docRef.update({
        'images': currentImages,
        'img': currentImages.isNotEmpty ? currentImages.first : '',
        'photoCount': currentImages.length,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('🗑 Fotoğraf silindi')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Fotoğraf silinemedi: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
    required Color background,
    required Color foreground,
  }) {
    return Expanded(
      child: ElevatedButton.icon(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: background,
          foregroundColor: foreground,
          minimumSize: const Size(double.infinity, 48),
        ),
        icon: Icon(icon),
        label: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white12),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.photo_library_outlined,
            color: Colors.white38,
            size: 40,
          ),
          SizedBox(height: 10),
          Text(
            'Henüz galeri fotoğrafı yok',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _photoCard(Map<String, dynamic> data, List<String> images, int index) {
    final url = images[index];

    return Container(
      width: 190,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _gold.withAlpha(170)),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: Colors.white10,
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.broken_image_outlined,
                    color: Colors.white38,
                    size: 34,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 10,
            right: 10,
            child: InkWell(
              onTap: _busy ? null : () => _deletePhoto(data, index),
              borderRadius: BorderRadius.circular(99),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(170),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white24),
                ),
                child: _busy
                    ? const Padding(
                        padding: EdgeInsets.all(10),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.redAccent,
                        ),
                      )
                    : const Icon(
                        Icons.delete_outline,
                        color: Colors.redAccent,
                        size: 20,
                      ),
              ),
            ),
          ),
          Positioned(
            left: 10,
            bottom: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.black.withAlpha(165),
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text(
                '${index + 1}/${images.length}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          if (index == 0)
            Positioned(
              left: 10,
              top: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: _gold,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: const Text(
                  'KAPAK',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: _gold),
        title: Text(
          widget.urunAdi.isEmpty
              ? 'MAHALLE FOTO YÖNETİMİ'
              : 'MAHALLE FOTO • ${widget.urunAdi}',
          style: const TextStyle(
            color: _gold,
            fontWeight: FontWeight.w900,
            fontSize: 15,
          ),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _docRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: _gold),
            );
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(
              child: Text(
                'Ürün bulunamadı.',
                style: TextStyle(color: Colors.white70),
              ),
            );
          }

          final data = snapshot.data!.data() ?? <String, dynamic>{};
          final images = _readImages(data);

          return Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _actionButton(
                      icon: Icons.add_a_photo,
                      label: _busy ? 'BEKLEYİN...' : 'FOTO EKLE',
                      onPressed: _busy ? null : () => _addPhoto(data),
                      background: _gold,
                      foreground: Colors.black,
                    ),
                    const SizedBox(width: 12),
                    _actionButton(
                      icon: Icons.close,
                      label: 'KAPAT',
                      onPressed: () => Navigator.pop(context),
                      background: Colors.white10,
                      foreground: Colors.white,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Toplam fotoğraf: ${images.length}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: images.isEmpty
                      ? _emptyState()
                      : ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: images.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: 12),
                          itemBuilder: (_, index) =>
                              _photoCard(data, images, index),
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
