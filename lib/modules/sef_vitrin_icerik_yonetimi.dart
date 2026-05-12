import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sofrasofra_arena_v2/modules/widgets/sef_membership_card.dart';

class SefVitrinIcerikYonetimiSayfasi extends StatefulWidget {
  final String chefId;
  final String chefName;

  const SefVitrinIcerikYonetimiSayfasi({
    super.key,
    required this.chefId,
    required this.chefName,
  });

  @override
  State<SefVitrinIcerikYonetimiSayfasi> createState() =>
      _SefVitrinIcerikYonetimiSayfasiState();
}

class _SefVitrinIcerikYonetimiSayfasiState
    extends State<SefVitrinIcerikYonetimiSayfasi> {
  static const Color gold = Color(0xFFFFB300);
  static const Color bg = Color(0xFF050505);

  final ImagePicker _picker = ImagePicker();

  final TextEditingController _uzmanlikController = TextEditingController();
  final TextEditingController _tanitimController = TextEditingController();
  final TextEditingController _videoController = TextEditingController();

  bool _loading = false;

  String _membershipType = 'free';
  int _maxGalleryPhoto = 6;
  int _maxVideoLink = 0;
  bool _membershipLoading = true;

  List<String> _gallery = <String>[];
  List<String> _videoLinks = <String>[];

  String get _chefId =>
      (FirebaseAuth.instance.currentUser?.uid ?? widget.chefId).trim();

  DocumentReference<Map<String, dynamic>> get _chefProfileRef =>
      FirebaseFirestore.instance.collection('chef_profiles').doc(_chefId);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _uzmanlikController.dispose();
    _tanitimController.dispose();
    _videoController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final doc = await _chefProfileRef.get();
      final data = doc.data() ?? <String, dynamic>{};

      final rawType =
          (data['membershipType'] ?? 'free').toString().toLowerCase();
      final gallery = (data['gallery'] is List)
          ? List<String>.from(
              (data['gallery'] as List).map((e) => e.toString()))
          : <String>[];
      final videoLinks = (data['videoLinks'] is List)
          ? List<String>.from(
              (data['videoLinks'] as List).map((e) => e.toString()))
          : <String>[];

      _uzmanlikController.text = (data['uzmanlik'] ?? '').toString();
      _tanitimController.text = (data['bio'] ?? '').toString();

      int maxGalleryPhoto = 6;
      int maxVideoLink = 0;

      switch (rawType) {
        case 'premium':
          maxGalleryPhoto = 40;
          maxVideoLink = 3;
          break;
        case 'pro':
          maxGalleryPhoto = 15;
          maxVideoLink = 1;
          break;
        default:
          maxGalleryPhoto = 6;
          maxVideoLink = 0;
      }

      if (!mounted) return;
      setState(() {
        _membershipType = rawType;
        _maxGalleryPhoto = maxGalleryPhoto;
        _maxVideoLink = maxVideoLink;
        _membershipLoading = false;
        _gallery = gallery;
        _videoLinks = videoLinks;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _membershipType = 'free';
        _maxGalleryPhoto = 6;
        _maxVideoLink = 0;
        _membershipLoading = false;
      });
    }
  }

  bool _isYoutubeUrl(String value) {
    final t = value.trim().toLowerCase();
    return t.contains('youtube.com') || t.contains('youtu.be');
  }

  Future<String> _upload(Uint8List data, String path) async {
    final ref = FirebaseStorage.instance.ref().child(path);

    final task = await ref.putData(
      data,
      SettableMetadata(contentType: 'image/jpeg'),
    );

    return await task.ref.getDownloadURL();
  }

  Future<void> _addGalleryImage() async {
    if (_loading) return;

    if (_gallery.length >= _maxGalleryPhoto) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Galeri limiti doldu. Paketiniz en fazla $_maxGalleryPhoto fotoğraf destekliyor.',
          ),
        ),
      );
      return;
    }

    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );

    if (file == null) return;

    setState(() => _loading = true);

    try {
      final bytes = await file.readAsBytes();
      final url = await _upload(
        bytes,
        'chef_profiles/$_chefId/gallery/${DateTime.now().millisecondsSinceEpoch}.jpg',
      );

      await _chefProfileRef.set({
        'chefId': _chefId,
        'ownerId': _chefId,
        'dukkanId': _chefId,
        'gallery': FieldValue.arrayUnion([url]),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;
      setState(() {
        _gallery = [..._gallery, url];
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Galeriye fotoğraf eklendi.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Galeri fotoğrafı eklenemedi: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _removeGalleryImage(String url) async {
    if (_loading) return;

    setState(() => _loading = true);

    try {
      await _chefProfileRef.set({
        'gallery': FieldValue.arrayRemove([url]),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;
      setState(() {
        _gallery.remove(url);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Galeri fotoğrafı silindi.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Galeri fotoğrafı silinemedi: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _addVideoLink() {
    if (_loading) return;

    if (_videoLinks.length >= _maxVideoLink) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Video limiti doldu. Paketiniz en fazla $_maxVideoLink video linki destekliyor.',
          ),
        ),
      );
      return;
    }

    final url = _videoController.text.trim();

    if (!_isYoutubeUrl(url)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Geçerli bir YouTube linki giriniz.')),
      );
      return;
    }

    setState(() {
      _videoLinks = [..._videoLinks, url];
      _videoController.clear();
    });
  }

  void _removeVideoLink(String url) {
    setState(() {
      _videoLinks.remove(url);
    });
  }

  Future<void> _saveProfileContent() async {
    if (_loading) return;

    setState(() => _loading = true);

    try {
      await _chefProfileRef.set({
        'chefId': _chefId,
        'ownerId': _chefId,
        'dukkanId': _chefId,
        'displayName': widget.chefName,
        'uzmanlik': _uzmanlikController.text.trim(),
        'bio': _tanitimController.text.trim(),
        'videoLinks': _videoLinks,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Şef vitrini güncellendi.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kayıt hatası: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  InputDecoration _decoration(String label) {
    return const InputDecoration().copyWith(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      enabledBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: Colors.white24),
      ),
      focusedBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: gold),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: gold,
        fontSize: 12,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF121212),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0x22FFB300)),
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: gold),
        title: const Text(
          'ŞEF VİTRİN YÖNETİMİ',
          style: TextStyle(
            color: gold,
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 36),
        children: [
          SefMembershipCard(
            membershipType: _membershipType,
            isLoading: _membershipLoading,
            galleryLimit: _maxGalleryPhoto,
            videoLimit: _maxVideoLink,
            onTapUpgrade: () {},
          ),
          const SizedBox(height: 18),
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionTitle('ŞEF PROFİL METİNLERİ'),
                const SizedBox(height: 12),
                TextField(
                  controller: _uzmanlikController,
                  style: const TextStyle(color: Colors.white),
                  decoration: _decoration('Uzmanlık'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _tanitimController,
                  maxLines: 5,
                  style: const TextStyle(color: Colors.white),
                  decoration: _decoration('Tanıtım / Hikâye'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionTitle('TANITIM VİDEOLARI'),
                const SizedBox(height: 10),
                Text(
                  'Kullanılan: ${_videoLinks.length} / $_maxVideoLink',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _videoController,
                  style: const TextStyle(color: Colors.white),
                  decoration: _decoration('YouTube linki'),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed:
                      (_loading || _maxVideoLink == 0) ? null : _addVideoLink,
                  style: ElevatedButton.styleFrom(backgroundColor: gold),
                  child: const Text(
                    'VİDEO LİNKİ EKLE',
                    style: TextStyle(color: Colors.black),
                  ),
                ),
                if (_videoLinks.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  for (final url in _videoLinks)
                    Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF181818),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.play_circle_outline, color: gold),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              url,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            onPressed:
                                _loading ? null : () => _removeVideoLink(url),
                            icon: const Icon(Icons.close,
                                color: Colors.redAccent),
                          ),
                        ],
                      ),
                    ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 18),
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionTitle('GALERİ'),
                const SizedBox(height: 10),
                Text(
                  'Kullanılan: ${_gallery.length} / $_maxGalleryPhoto',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _loading ? null : _addGalleryImage,
                  style: ElevatedButton.styleFrom(backgroundColor: gold),
                  child: const Text(
                    'GALERİ FOTOĞRAFI EKLE',
                    style: TextStyle(color: Colors.black),
                  ),
                ),
                if (_gallery.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _gallery.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 1.0,
                    ),
                    itemBuilder: (context, index) {
                      final url = _gallery[index];
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.network(
                              url,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: Colors.white10,
                                child: const Icon(
                                  Icons.broken_image,
                                  color: Colors.white24,
                                ),
                              ),
                            ),
                            Positioned(
                              top: 6,
                              right: 6,
                              child: Material(
                                color: Colors.black.withAlpha(170),
                                shape: const CircleBorder(),
                                child: InkWell(
                                  customBorder: const CircleBorder(),
                                  onTap: () {
                                    debugPrint(
                                      '### SEF VITRIN GALLERY DELETE TAP url=$url',
                                    );
                                    _removeGalleryImage(url);
                                  },
                                  child: const SizedBox(
                                    width: 36,
                                    height: 36,
                                    child: Center(
                                      child: Icon(
                                        Icons.close,
                                        color: Colors.redAccent,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 22),
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: _loading ? null : _saveProfileContent,
              style: ElevatedButton.styleFrom(backgroundColor: gold),
              child: _loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.black,
                        ),
                      ),
                    )
                  : const Text(
                      'ŞEF VİTRİNİNDE YAYINLA',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
