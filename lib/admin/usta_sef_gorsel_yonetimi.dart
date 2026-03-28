import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

class UstaSefGorselYonetimi extends StatefulWidget {
  final String chefId;

  const UstaSefGorselYonetimi({
    super.key,
    required this.chefId,
  });

  @override
  State<UstaSefGorselYonetimi> createState() => _UstaSefGorselYonetimiState();
}

class _UstaSefGorselYonetimiState extends State<UstaSefGorselYonetimi> {
  static const Color gold = Color(0xFFFFB300);
  static const Color cardBg = Color(0xFF171717);
  static const Color bg = Colors.black;

  Uint8List? _localBytes;
  String _profileUrl = '';
  bool _isBusy = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('chefs')
          .doc(widget.chefId)
          .get();

      if (!doc.exists) return;

      final data = doc.data();
      final imageUrl =
          (data?['media']?['profileImage'] ?? '').toString().trim();

      if (!mounted) return;
      setState(() {
        _profileUrl = imageUrl;
      });
    } catch (e) {
      debugPrint('Şef görsel verisi okunamadı: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Veri okunamadı: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _pickAndUpload() async {
    if (_isBusy) return;

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;

      final pickedFile = result.files.first;
      final bytes = pickedFile.bytes;

      if (bytes == null || bytes.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Dosya okunamadı. Lütfen başka bir görsel seçin.'),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }

      setState(() {
        _isBusy = true;
        _localBytes = bytes;
      });

      final ext = _guessExtension(pickedFile.extension);
      final fileName = 'profile_${DateTime.now().millisecondsSinceEpoch}.$ext';

      final ref = FirebaseStorage.instance
          .ref()
          .child('chefs/${widget.chefId}/$fileName');

      final metadata = SettableMetadata(
        contentType: _contentTypeForExtension(ext),
      );

      await ref.putData(bytes, metadata);
      final url = await ref.getDownloadURL();

      await FirebaseFirestore.instance
          .collection('chefs')
          .doc(widget.chefId)
          .set({
        'media': {
          'profileImage': url,
        },
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;
      setState(() {
        _profileUrl = url;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Şef görseli başarıyla yüklendi.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      debugPrint('Şef görsel yükleme hatası: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Yükleme başarısız: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _isBusy = false;
      });
    }
  }

  String _guessExtension(String? raw) {
    final ext = (raw ?? '').toLowerCase().trim();
    if (ext == 'png' || ext == 'webp' || ext == 'gif' || ext == 'jpg') {
      return ext;
    }
    if (ext == 'jpeg') return 'jpg';
    return 'jpg';
  }

  String _contentTypeForExtension(String ext) {
    switch (ext) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'gif':
        return 'image/gif';
      case 'jpg':
      default:
        return 'image/jpeg';
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = _localBytes != null || _profileUrl.isNotEmpty;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        iconTheme: const IconThemeData(color: gold),
        title: const Text(
          'GÖRSEL PANELİ',
          style: TextStyle(
            color: gold,
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: const Color(0x22FFB300),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Şef Profil Görseli',
                    style: TextStyle(
                      color: gold,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Masaüstünden görsel seçip doğrudan yükleyebilirsin.',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 18),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      height: 320,
                      color: const Color(0xFF101010),
                      alignment: Alignment.center,
                      child: _buildPreview(hasImage),
                    ),
                  ),
                  const SizedBox(height: 18),
                  ElevatedButton.icon(
                    onPressed: _isBusy ? null : _pickAndUpload,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: gold,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: _isBusy
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.black,
                            ),
                          )
                        : const Icon(Icons.upload_file),
                    label: Text(
                      _isBusy
                          ? 'Yükleniyor...'
                          : 'Bilgisayardan Görsel Seç ve Yükle',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_profileUrl.isNotEmpty)
                    SelectableText(
                      _profileUrl,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPreview(bool hasImage) {
    if (!hasImage) {
      return const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.add_a_photo_outlined,
            color: Colors.white54,
            size: 52,
          ),
          SizedBox(height: 10),
          Text(
            'Henüz görsel seçilmedi',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 14,
            ),
          ),
        ],
      );
    }

    if (_localBytes != null) {
      return Image.memory(
        _localBytes!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      );
    }

    return Image.network(
      _profileUrl,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (_, __, ___) {
        return const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.broken_image_outlined,
              color: Colors.white54,
              size: 48,
            ),
            SizedBox(height: 8),
            Text(
              'Görsel yüklenemedi',
              style: TextStyle(color: Colors.white54),
            ),
          ],
        );
      },
    );
  }
}
