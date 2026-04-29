import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class HomeBannerAdminSayfasi extends StatefulWidget {
  const HomeBannerAdminSayfasi({super.key});

  @override
  State<HomeBannerAdminSayfasi> createState() => _HomeBannerAdminSayfasiState();
}

class _HomeBannerAdminSayfasiState extends State<HomeBannerAdminSayfasi> {
  static const Color _bg = Color(0xFF0B0B0B);
  static const Color _card = Color(0xFF151515);
  static const Color _gold = Color(0xFFFFB300);

  bool _busy = false;

  DocumentReference<Map<String, dynamic>> get _bannerRef =>
      FirebaseFirestore.instance.collection('site_settings').doc('home_banner');

  Future<void> _pickAndUploadBanner() async {
    if (_busy) return;

    setState(() => _busy = true);

    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 88,
      );

      if (picked == null) return;

      final Uint8List bytes = await picked.readAsBytes();
      final fileName =
          'home_banner_${DateTime.now().millisecondsSinceEpoch}.jpg';

      final ref =
          FirebaseStorage.instance.ref('site_settings/home_banner/$fileName');

      await ref.putData(
        bytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      final url = await ref.getDownloadURL();

      await _bannerRef.set({
        'imageUrl': url,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      _showMessage('Ana banner güncellendi.');
    } catch (e) {
      _showMessage('Banner yüklenemedi: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _deleteBanner() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _card,
        title: const Text(
          'Banner silinsin mi?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Ana giriş üst fotoğrafı kaldırılacak.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Vazgeç'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Sil',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );

    if (ok != true) return;

    await _bannerRef.set({
      'imageUrl': '',
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    _showMessage('Banner kaldırıldı.');
  }

  void _showMessage(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: const Color(0xFF222222),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        iconTheme: const IconThemeData(color: _gold),
        title: const Text(
          'Ana Sayfa Banner Admin',
          style: TextStyle(
            color: _gold,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _bannerRef.snapshots(),
        builder: (context, snapshot) {
          final data = snapshot.data?.data() ?? {};
          final imageUrl = (data['imageUrl'] ?? '').toString();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _card,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0x33FFB300)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Ana Giriş Üst Fotoğrafı',
                      style: TextStyle(
                        color: _gold,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        height: 220,
                        width: double.infinity,
                        color: const Color(0xFF222222),
                        child: imageUrl.isEmpty
                            ? const Center(
                                child: Icon(
                                  Icons.image_outlined,
                                  color: Colors.white38,
                                  size: 54,
                                ),
                              )
                            : Image.network(
                                imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Center(
                                  child: Icon(
                                    Icons.broken_image_outlined,
                                    color: Colors.white38,
                                    size: 54,
                                  ),
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: _busy ? null : _pickAndUploadBanner,
                        icon: _busy
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.black,
                                ),
                              )
                            : const Icon(Icons.add_photo_alternate_rounded),
                        label: Text(_busy
                            ? 'Yükleniyor...'
                            : 'Banner Fotoğrafı Seç / Değiştir'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _gold,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          textStyle:
                              const TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (imageUrl.isNotEmpty)
                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: OutlinedButton.icon(
                          onPressed: _busy ? null : _deleteBanner,
                          icon: const Icon(Icons.delete_outline_rounded),
                          label: const Text('Bannerı Kaldır'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.redAccent,
                            side: const BorderSide(color: Colors.redAccent),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
