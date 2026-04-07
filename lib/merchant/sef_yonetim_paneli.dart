import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

class SefYonetimPaneli extends StatefulWidget {
  final String dukkanAdi;

  const SefYonetimPaneli({
    super.key,
    required this.dukkanAdi,
  });

  @override
  State<SefYonetimPaneli> createState() => _SefYonetimPaneliState();
}

class _SefYonetimPaneliState extends State<SefYonetimPaneli> {
  static const Color gold = Color(0xFFFFB300);
  static const Color bg = Color(0xFF050505);
  static const Color card = Color(0xFF121212);

  final TextEditingController _adSoyad = TextEditingController();
  final TextEditingController _unvan = TextEditingController();
  final TextEditingController _bio = TextEditingController();
  final TextEditingController _uzmanlik = TextEditingController();
  final TextEditingController _profilFoto = TextEditingController();
  final TextEditingController _kapakFoto = TextEditingController();

  final List<TextEditingController> _galeriControllers = [];

  bool _yukleniyor = true;
  bool _kaydediliyor = false;
  bool _profilGorselYukleniyor = false;
  bool _kapakGorselYukleniyor = false;
  bool _galeriGorselYukleniyor = false;

  String _aktifUid = 'demo_user';
  String _aktifDukkanAdi = '';

  @override
  void initState() {
    super.initState();
    _aktifDukkanAdi = widget.dukkanAdi.trim();
    _yukle();
  }

  @override
  void dispose() {
    _adSoyad.dispose();
    _unvan.dispose();
    _bio.dispose();
    _uzmanlik.dispose();
    _profilFoto.dispose();
    _kapakFoto.dispose();

    for (final controller in _galeriControllers) {
      controller.dispose();
    }

    super.dispose();
  }

  bool _isValidImageUrl(String url) {
    final u = url.trim().toLowerCase();

    if (u.isEmpty) return true;

    final isHttp = u.startsWith('http://') || u.startsWith('https://');
    if (!isHttp) return false;

    if (u.contains('firebasestorage.googleapis.com')) return true;

    final hasImageExt = u.endsWith('.jpg') ||
        u.endsWith('.jpeg') ||
        u.endsWith('.png') ||
        u.endsWith('.webp');

    final looksLikeDirectImage = u.contains('/o/') ||
        u.contains('/images/') ||
        u.contains('/uploads/') ||
        hasImageExt;

    final blockedHosts = <String>[
      'bing.com/images/search',
      'google.com/search',
      'youtube.com',
      'youtu.be',
    ];

    final isBlocked = blockedHosts.any((host) => u.contains(host));
    if (isBlocked) return false;

    return looksLikeDirectImage;
  }

  String _safeHttpUrlOrEmpty(String? url) {
    final u = (url ?? '').trim();
    if (u.startsWith('http://') || u.startsWith('https://')) return u;
    return '';
  }

  Future<void> _deleteFromStorage(String url) async {
    try {
      if (url.trim().isEmpty) return;

      final ref = FirebaseStorage.instance.refFromURL(url);
      await ref.delete();
    } catch (e) {
      debugPrint('Storage silme hatası: $e');
    }
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<String?> _dosyaSecVeYukle({
    required String folderName,
  }) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
      );

      if (result == null || result.files.isEmpty) {
        return null;
      }

      final file = result.files.first;
      final Uint8List? bytes = file.bytes;

      if (bytes == null) {
        throw Exception('Seçilen dosya okunamadı.');
      }

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('Firebase oturumu bulunamadı.');
      }

      final uid = user.uid;
      final fileName = file.name.replaceAll(' ', '_');
      final ext = (file.extension ?? 'jpg').toLowerCase();

      final path =
          'chef_profiles/$uid/$folderName/${DateTime.now().millisecondsSinceEpoch}_$fileName';

      final ref = FirebaseStorage.instance.ref().child(path);

      String contentType;
      switch (ext) {
        case 'png':
          contentType = 'image/png';
          break;
        case 'webp':
          contentType = 'image/webp';
          break;
        case 'jpeg':
        case 'jpg':
          contentType = 'image/jpeg';
          break;
        default:
          contentType = 'image/jpeg';
      }

      final metadata = SettableMetadata(contentType: contentType);

      await ref.putData(bytes, metadata);
      return await ref.getDownloadURL();
    } catch (e) {
      _showSnack('Görsel yüklenemedi: $e');
      return null;
    }
  }

  Future<void> _profilGorseliSec() async {
    setState(() => _profilGorselYukleniyor = true);

    try {
      final url = await _dosyaSecVeYukle(folderName: 'profile');
      if (url != null && mounted) {
        setState(() {
          _profilFoto.text = url;
        });
      }
    } finally {
      if (mounted) {
        setState(() => _profilGorselYukleniyor = false);
      }
    }
  }

  Future<void> _kapakGorseliSec() async {
    setState(() => _kapakGorselYukleniyor = true);

    try {
      final url = await _dosyaSecVeYukle(folderName: 'cover');
      if (url != null && mounted) {
        setState(() {
          _kapakFoto.text = url;
        });
      }
    } finally {
      if (mounted) {
        setState(() => _kapakGorselYukleniyor = false);
      }
    }
  }

  Future<void> _galeriGorselleriSec() async {
    setState(() => _galeriGorselYukleniyor = true);

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: true,
        withData: true,
      );

      if (result == null || result.files.isEmpty) {
        return;
      }

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('Firebase oturumu bulunamadı.');
      }

      final uid = user.uid;
      final List<String> yeniUrlListesi = [];

      for (final file in result.files) {
        final Uint8List? bytes = file.bytes;
        if (bytes == null) continue;

        final fileName = file.name.replaceAll(' ', '_');
        final ext = (file.extension ?? 'jpg').toLowerCase();

        final path =
            'chef_profiles/$uid/gallery/${DateTime.now().millisecondsSinceEpoch}_$fileName';

        final ref = FirebaseStorage.instance.ref().child(path);

        String contentType;
        switch (ext) {
          case 'png':
            contentType = 'image/png';
            break;
          case 'webp':
            contentType = 'image/webp';
            break;
          case 'jpeg':
          case 'jpg':
            contentType = 'image/jpeg';
            break;
          default:
            contentType = 'image/jpeg';
        }

        final metadata = SettableMetadata(contentType: contentType);

        await ref.putData(bytes, metadata);
        final downloadUrl = await ref.getDownloadURL();
        yeniUrlListesi.add(downloadUrl);
      }

      if (!mounted || yeniUrlListesi.isEmpty) return;

      setState(() {
        for (final url in yeniUrlListesi) {
          _galeriControllers.add(TextEditingController(text: url));
        }
      });

      _showSnack('${yeniUrlListesi.length} galeri görseli yüklendi.');
    } catch (e) {
      _showSnack('Galeri görselleri yüklenemedi: $e');
    } finally {
      if (mounted) {
        setState(() => _galeriGorselYukleniyor = false);
      }
    }
  }

  Future<DocumentSnapshot<Map<String, dynamic>>?> _chefProfileGetir(
    String uid,
  ) async {
    final doc = await FirebaseFirestore.instance
        .collection('chef_profiles')
        .doc(uid)
        .get();

    if (doc.exists) return doc;
    return null;
  }

  Future<QueryDocumentSnapshot<Map<String, dynamic>>?> _urunDokumaniBul({
    required String uid,
    required String dukkanAdi,
  }) async {
    final urunlerRef = FirebaseFirestore.instance.collection('urunler');

    final qsByUid = await urunlerRef
        .where('tip', isEqualTo: 'Usta Sefler')
        .where('ownerId', isEqualTo: uid)
        .limit(1)
        .get();

    if (qsByUid.docs.isNotEmpty) {
      return qsByUid.docs.first;
    }

    final qsByDukkanId = await urunlerRef
        .where('tip', isEqualTo: 'Usta Sefler')
        .where('dukkanId', isEqualTo: uid)
        .limit(1)
        .get();

    if (qsByDukkanId.docs.isNotEmpty) {
      return qsByDukkanId.docs.first;
    }

    final fallbackName = dukkanAdi.trim();
    if (fallbackName.isNotEmpty) {
      final qsByName = await urunlerRef
          .where('tip', isEqualTo: 'Usta Sefler')
          .where('dukkanAdi', isEqualTo: fallbackName)
          .limit(1)
          .get();

      if (qsByName.docs.isNotEmpty) {
        return qsByName.docs.first;
      }
    }

    return null;
  }

  Future<void> _yukle() async {
    setState(() => _yukleniyor = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('Firebase oturumu bulunamadı. Panel yüklenemedi.');
      }

      final uid = user.uid;
      _aktifUid = uid;

      final chefProfile = await _chefProfileGetir(uid);
      final chefData = chefProfile?.data();

      final profileDisplayName =
          (chefData?['displayName'] ?? chefData?['adSoyad'] ?? '')
              .toString()
              .trim();

      if (profileDisplayName.isNotEmpty) {
        _aktifDukkanAdi = profileDisplayName;
      }

      final urunDoc = await _urunDokumaniBul(
        uid: uid,
        dukkanAdi: _aktifDukkanAdi,
      );

      if (chefData != null) {
        _adSoyad.text =
            (chefData['adSoyad'] ?? chefData['displayName'] ?? '').toString();
        _unvan.text = (chefData['unvan'] ?? '').toString();
        _bio.text = (chefData['bio'] ?? '').toString();
        _uzmanlik.text = (chefData['uzmanlik'] ?? '').toString();

        final chefImg =
            (chefData['img'] ?? chefData['imageUrl'] ?? '').toString().trim();
        final chefCover = (chefData['coverImage'] ?? '').toString().trim();

        if (chefImg.isNotEmpty) {
          _profilFoto.text = chefImg;
        }

        if (chefCover.isNotEmpty) {
          _kapakFoto.text = chefCover;
        } else if (chefImg.isNotEmpty) {
          _kapakFoto.text = chefImg;
        }

        final gallery = (chefData['gallery'] is List)
            ? List<String>.from(
                (chefData['gallery'] as List).map((e) => e.toString()),
              )
            : <String>[];

        for (final controller in _galeriControllers) {
          controller.dispose();
        }
        _galeriControllers.clear();

        for (final url in gallery) {
          _galeriControllers.add(TextEditingController(text: url));
        }
      }

      if (urunDoc != null) {
        final data = urunDoc.data();

        _adSoyad.text = (data['adSoyad'] ?? _adSoyad.text).toString();
        _unvan.text = (data['unvan'] ?? _unvan.text).toString();
        _bio.text = (data['bio'] ?? _bio.text).toString();
        _uzmanlik.text = (data['uzmanlik'] ?? _uzmanlik.text).toString();
        _profilFoto.text = (data['img'] ?? _profilFoto.text).toString();

        final cover = (data['coverImage'] ?? '').toString().trim();
        _kapakFoto.text = cover.isEmpty ? _profilFoto.text.trim() : cover;

        if (_galeriControllers.isEmpty) {
          final gallery = (data['gallery'] is List)
              ? List<String>.from(
                  (data['gallery'] as List).map((e) => e.toString()),
                )
              : <String>[];

          for (final url in gallery) {
            _galeriControllers.add(TextEditingController(text: url));
          }
        }

        final urunDukkanAdi = (data['dukkanAdi'] ?? '').toString().trim();
        if (urunDukkanAdi.isNotEmpty) {
          _aktifDukkanAdi = urunDukkanAdi;
        }
      }

      if (_aktifDukkanAdi.isEmpty) {
        _aktifDukkanAdi = widget.dukkanAdi.trim().isEmpty
            ? 'Usta Şef'
            : widget.dukkanAdi.trim();
      }
    } catch (e) {
      _showSnack('Şef paneli yüklenemedi: $e');
    } finally {
      if (mounted) {
        setState(() => _yukleniyor = false);
      }
    }
  }

  Future<void> _kaydet() async {
    setState(() => _kaydediliyor = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('Firebase oturumu bulunamadı. Kayıt durduruldu.');
      }

      final uid = user.uid;
      _aktifUid = uid;

      final img = _profilFoto.text.trim();
      final coverRaw = _kapakFoto.text.trim();
      final cover = coverRaw.isEmpty ? img : coverRaw;

      final gallery = _galeriControllers
          .map((e) => e.text.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      if (!_isValidImageUrl(img)) {
        _showSnack('Ana görsel URL geçersiz.');
        return;
      }

      if (!_isValidImageUrl(cover)) {
        _showSnack('Kapak görsel URL geçersiz.');
        return;
      }

      for (final g in gallery) {
        if (!_isValidImageUrl(g)) {
          _showSnack('Galeri görsel URL geçersiz: $g');
          return;
        }
      }

      _aktifDukkanAdi = _adSoyad.text.trim().isEmpty
          ? widget.dukkanAdi.trim()
          : _adSoyad.text.trim();

      final payload = <String, dynamic>{
        'tip': 'Usta Sefler',
        'dukkanAdi': _aktifDukkanAdi,
        'dukkan': _aktifDukkanAdi,
        'dukkanId': uid,
        'ownerId': uid,
        'adSoyad': _adSoyad.text.trim(),
        'unvan': _unvan.text.trim(),
        'bio': _bio.text.trim(),
        'uzmanlik': _uzmanlik.text.trim(),
        'img': img,
        'coverImage': cover,
        'gallery': gallery,
        'isActive': true,
        'aktifMi': true,
        'onayDurumu': 'onaylandi',
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance
          .collection('chef_profiles')
          .doc(uid)
          .set({
        'chefId': uid,
        'ownerId': uid,
        'dukkanId': uid,
        'displayName': _aktifDukkanAdi,
        'adSoyad': _adSoyad.text.trim(),
        'unvan': _unvan.text.trim(),
        'bio': _bio.text.trim(),
        'uzmanlik': _uzmanlik.text.trim(),
        'img': img,
        'coverImage': cover,
        'gallery': gallery,
        'isActive': true,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      final mevcutUrunDoc = await _urunDokumaniBul(
        uid: uid,
        dukkanAdi: _aktifDukkanAdi,
      );

      if (mevcutUrunDoc == null) {
        await FirebaseFirestore.instance.collection('urunler').add({
          ...payload,
          'createdAt': FieldValue.serverTimestamp(),
        });
      } else {
        await mevcutUrunDoc.reference.set(payload, SetOptions(merge: true));
      }

      _showSnack('Şef profili kaydedildi.');
    } catch (e) {
      _showSnack('Kayıt başarısız: $e');
    } finally {
      if (mounted) {
        setState(() => _kaydediliyor = false);
      }
    }
  }

  Widget _imagePreviewCard({
    required String title,
    required String imageUrl,
    required VoidCallback onUpload,
    VoidCallback? onDelete,
    double height = 180,
    IconData emptyIcon = Icons.image_outlined,
    String uploadLabel = 'Görsel Seç ve Yükle',
    bool loading = false,
  }) {
    final safe = _safeHttpUrlOrEmpty(imageUrl);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: gold,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: double.infinity,
              height: height,
              color: Colors.white.withAlpha(8),
              child: safe.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(emptyIcon, color: Colors.white38, size: 34),
                          const SizedBox(height: 8),
                          const Text(
                            'Henüz görsel yok',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    )
                  : Image.network(
                      safe,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Center(
                        child: Icon(
                          Icons.broken_image,
                          color: Colors.white30,
                          size: 30,
                        ),
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            safe.isNotEmpty ? 'Görsel yüklendi' : 'Görsel henüz yüklenmedi',
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: loading ? null : onUpload,
                  icon: loading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.upload_file),
                  label: Text(loading ? 'Yükleniyor...' : uploadLabel),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white10,
                    foregroundColor: gold,
                  ),
                ),
              ),
              if (onDelete != null) ...[
                const SizedBox(width: 10),
                OutlinedButton.icon(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Sil'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    side: const BorderSide(color: Colors.redAccent),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _gallerySection({
    required List<String> gallery,
    required VoidCallback onAdd,
    required void Function(String url) onDelete,
    bool loading = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'GALERİ',
              style: TextStyle(
                color: gold,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.1,
              ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: loading ? null : onAdd,
              icon: loading
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(
                      Icons.upload_file,
                      color: gold,
                      size: 18,
                    ),
              label: Text(
                loading ? 'Yükleniyor...' : 'Çoklu Yükle',
                style: const TextStyle(color: gold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (gallery.isEmpty)
          Container(
            height: 110,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(8),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white10),
            ),
            child: const Center(
              child: Text(
                'Henüz galeri görseli yok.',
                style: TextStyle(color: Colors.white54),
              ),
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: gallery.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1,
            ),
            itemBuilder: (context, index) {
              final url = gallery[index].trim();
              final safe = _safeHttpUrlOrEmpty(url);

              return ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(
                      color: Colors.white.withAlpha(8),
                      child: safe.isEmpty
                          ? const Center(
                              child: Icon(Icons.image, color: Colors.white30),
                            )
                          : Image.network(
                              safe,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Center(
                                child: Icon(
                                  Icons.broken_image,
                                  color: Colors.white30,
                                ),
                              ),
                            ),
                    ),
                    Positioned(
                      top: 6,
                      right: 6,
                      child: GestureDetector(
                        onTap: () => onDelete(url),
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: Colors.black.withAlpha(180),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            size: 16,
                            color: Colors.redAccent,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 6,
                      left: 6,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            final index = _galeriControllers.indexWhere(
                              (c) => c.text.trim() == url,
                            );

                            if (index > 0) {
                              final selected =
                                  _galeriControllers.removeAt(index);
                              _galeriControllers.insert(0, selected);
                            }
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: Colors.black.withAlpha(180),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.star,
                            color: Colors.amber,
                            size: 16,
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final galleryUrls = _galeriControllers
        .map((e) => e.text.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: gold),
        title: Text(
          _aktifDukkanAdi.isEmpty
              ? 'ŞEF YÖNETİM PANELİ'
              : 'ŞEF YÖNETİM PANELİ • $_aktifDukkanAdi',
          style: const TextStyle(
            color: gold,
            fontSize: 13,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.1,
          ),
        ),
      ),
      body: _yukleniyor
          ? const Center(
              child: CircularProgressIndicator(color: gold),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _kart(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _baslik('TEMEL BİLGİLER'),
                      const SizedBox(height: 12),
                      _alan(_adSoyad, 'Ad Soyad'),
                      _alan(_unvan, 'Unvan'),
                      _alan(_uzmanlik, 'Uzmanlık'),
                      _alan(_bio, 'Bio', maxLines: 4),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _kart(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _baslik('GÖRSEL ALANLAR'),
                      const SizedBox(height: 16),
                      _imagePreviewCard(
                        title: 'ANA GÖRSEL',
                        imageUrl: _profilFoto.text,
                        onUpload: _profilGorseliSec,
                        onDelete: _profilFoto.text.trim().isNotEmpty
                            ? () async {
                                final oldUrl = _profilFoto.text.trim();

                                await _deleteFromStorage(oldUrl);

                                if (!mounted) return;

                                setState(() {
                                  _profilFoto.clear();
                                });
                              }
                            : null,
                        emptyIcon: Icons.person_outline,
                        uploadLabel: 'Ana Görsel Seç ve Yükle',
                        loading: _profilGorselYukleniyor,
                      ),
                      const SizedBox(height: 16),
                      _imagePreviewCard(
                        title: 'KAPAK GÖRSEL',
                        imageUrl: _kapakFoto.text,
                        onUpload: _kapakGorseliSec,
                        onDelete: _kapakFoto.text.trim().isNotEmpty
                            ? () async {
                                final oldUrl = _kapakFoto.text.trim();

                                await _deleteFromStorage(oldUrl);

                                if (!mounted) return;

                                setState(() {
                                  _kapakFoto.clear();
                                });
                              }
                            : null,
                        height: 160,
                        emptyIcon: Icons.landscape_outlined,
                        uploadLabel: 'Kapak Görseli Seç ve Yükle',
                        loading: _kapakGorselYukleniyor,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _kart(
                  child: _gallerySection(
                    gallery: galleryUrls,
                    onAdd: _galeriGorselleriSec,
                    onDelete: (url) async {
                      await _deleteFromStorage(url);

                      if (!mounted) return;

                      setState(() {
                        final index = _galeriControllers.indexWhere(
                          (c) => c.text.trim() == url,
                        );

                        if (index != -1) {
                          _galeriControllers[index].dispose();
                          _galeriControllers.removeAt(index);
                        }
                      });
                    },
                    loading: _galeriGorselYukleniyor,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: (_kaydediliyor ||
                            _profilGorselYukleniyor ||
                            _kapakGorselYukleniyor ||
                            _galeriGorselYukleniyor)
                        ? null
                        : _kaydet,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: gold,
                      foregroundColor: Colors.black,
                    ),
                    child: _kaydediliyor
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.black,
                            ),
                          )
                        : const Text(
                            'KAYDET',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _kart({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0x22FFB300)),
      ),
      child: child,
    );
  }

  Widget _baslik(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: gold,
        fontSize: 12,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.1,
      ),
    );
  }

  Widget _alan(
    TextEditingController controller,
    String label, {
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white60),
          filled: true,
          fillColor: Colors.white.withAlpha(8),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.white.withAlpha(18)),
            borderRadius: BorderRadius.circular(12),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: gold),
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
