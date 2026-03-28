import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

void showImagePreview(BuildContext context, String imageUrl) {
  if (imageUrl.isEmpty) return;

  showDialog(
    context: context,
    barrierColor: Colors.black.withOpacity(0.9),
    builder: (_) {
      return Stack(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(color: Colors.transparent),
          ),
          Center(
            child: InteractiveViewer(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.broken_image,
                    color: Colors.white,
                    size: 60,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 40,
            right: 20,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ),
          ),
        ],
      );
    },
  );
}

class ChefSignatureAdminPage extends StatefulWidget {
  final String chefId;

  const ChefSignatureAdminPage({
    super.key,
    required this.chefId,
  });

  @override
  State<ChefSignatureAdminPage> createState() => _ChefSignatureAdminPageState();
}

class _ChefSignatureAdminPageState extends State<ChefSignatureAdminPage> {
  final _galleryUrlCtrl = TextEditingController();
  final _galleryCaptionCtrl = TextEditingController();

  final _dishTitleCtrl = TextEditingController();
  final _dishDescCtrl = TextEditingController();
  final _dishImageCtrl = TextEditingController();

  bool _dishIsActive = true;
  bool _savingGallery = false;
  bool _savingDish = false;

  @override
  void dispose() {
    _galleryUrlCtrl.dispose();
    _galleryCaptionCtrl.dispose();
    _dishTitleCtrl.dispose();
    _dishDescCtrl.dispose();
    _dishImageCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveGallery() async {
    final url = _galleryUrlCtrl.text.trim();
    final caption = _galleryCaptionCtrl.text.trim();

    if (url.isEmpty) {
      _showSnack('Lütfen görsel URL girin.', backgroundColor: Colors.redAccent);
      return;
    }

    final lowerUrl = url.toLowerCase();
    final isImage = lowerUrl.contains('.jpg') ||
        lowerUrl.contains('.jpeg') ||
        lowerUrl.contains('.png') ||
        lowerUrl.contains('.webp') ||
        lowerUrl.contains('.gif');

    if (!isImage) {
      _showSnack(
        'Lütfen geçerli bir görsel linki girin (.jpg, .png, .webp vb.)',
        backgroundColor: Colors.orange,
      );
      return;
    }

    if (mounted) {
      setState(() => _savingGallery = true);
    }

    try {
      await FirebaseFirestore.instance.collection('chef_gallery').add({
        'chefId': widget.chefId,
        'imageUrl': url,
        'caption': caption,
        'createdAt': FieldValue.serverTimestamp(),
      });

      _galleryUrlCtrl.clear();
      _galleryCaptionCtrl.clear();

      _showSnack(
        'Galeri görseli eklendi.',
        backgroundColor: Colors.green,
      );
    } catch (e) {
      _showSnack('Galeri görseli kaydedilemedi: $e');
    } finally {
      if (mounted) {
        setState(() => _savingGallery = false);
      }
    }
  }

  Future<void> _saveDish() async {
    final title = _dishTitleCtrl.text.trim();
    final description = _dishDescCtrl.text.trim();
    final imageUrl = _dishImageCtrl.text.trim();

    if (title.isEmpty) {
      _showSnack('Tabak başlığı boş olamaz.');
      return;
    }

    if (imageUrl.isEmpty) {
      _showSnack('Tabak görsel URL boş olamaz.');
      return;
    }

    if (mounted) {
      setState(() => _savingDish = true);
    }

    try {
      await FirebaseFirestore.instance.collection('chef_signature_dishes').add({
        'chefId': widget.chefId,
        'title': title,
        'description': description,
        'imageUrl': imageUrl,
        'isActive': _dishIsActive,
        'createdAt': FieldValue.serverTimestamp(),
      });

      _dishTitleCtrl.clear();
      _dishDescCtrl.clear();
      _dishImageCtrl.clear();

      if (mounted) {
        setState(() {
          _dishIsActive = true;
        });
      }

      _showSnack('İmza tabak eklendi.');
    } catch (e) {
      _showSnack('İmza tabak kaydedilemedi: $e');
    } finally {
      if (mounted) {
        setState(() => _savingDish = false);
      }
    }
  }

  void _showSnack(
    String message, {
    Color backgroundColor = Colors.black87,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
      ),
    );
  }

  Future<void> _pickAndUploadGalleryImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked == null) return;

    final file = File(picked.path);

    setState(() => _savingGallery = true);

    try {
      final fileName = DateTime.now().millisecondsSinceEpoch.toString();

      final ref = FirebaseStorage.instance
          .ref()
          .child('chef_gallery')
          .child(widget.chefId)
          .child('$fileName.jpg');

      await ref.putFile(
        file,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      final url = await ref.getDownloadURL();

      await FirebaseFirestore.instance.collection('chef_gallery').add({
        'chefId': widget.chefId,
        'imageUrl': url,
        'caption': _galleryCaptionCtrl.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      _galleryCaptionCtrl.clear();

      _showSnack('Fotoğraf yüklendi', backgroundColor: Colors.green);
    } catch (e) {
      _showSnack('Upload hatası: $e');
    } finally {
      if (mounted) setState(() => _savingGallery = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111111),
      appBar: AppBar(
        backgroundColor: const Color(0xFF111111),
        elevation: 0,
        title: const Text(
          'İMZA MUTFAĞI YÖNETİMİ',
          style: TextStyle(
            color: Color(0xFFFFD54F),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _AdminSectionCard(
            title: 'Galeri Görseli Ekle',
            child: Column(
              children: [
                _AdminTextField(
                  controller: _galleryUrlCtrl,
                  label: 'Görsel URL',
                  hint: 'https://picsum.photos/400/300',
                ),
                const SizedBox(height: 12),
                _AdminTextField(
                  controller: _galleryCaptionCtrl,
                  label: 'Açıklama / Caption',
                  hint: 'İmza sunum',
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed:
                        _savingGallery ? null : _pickAndUploadGalleryImage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFD54F),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(
                      _savingGallery ? 'Kaydediliyor...' : 'Galeriye Ekle',
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _AdminSectionCard(
            title: 'İmza Tabak Ekle',
            child: Column(
              children: [
                _AdminTextField(
                  controller: _dishTitleCtrl,
                  label: 'Tabak Başlığı',
                  hint: 'Trüf Soslu Dana',
                ),
                const SizedBox(height: 12),
                _AdminTextField(
                  controller: _dishDescCtrl,
                  label: 'Açıklama',
                  hint: 'Kısa açıklama yaz...',
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                _AdminTextField(
                  controller: _dishImageCtrl,
                  label: 'Görsel URL',
                  hint: 'https://picsum.photos/800/500',
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  value: _dishIsActive,
                  activeColor: const Color(0xFFFFD54F),
                  tileColor: const Color(0xFF1A1A1A),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: const BorderSide(color: Color(0x22FFD54F)),
                  ),
                  title: const Text(
                    'Aktif olarak yayınla',
                    style: TextStyle(color: Colors.white),
                  ),
                  subtitle: const Text(
                    'Kapalıysa vitrinde görünmez',
                    style: TextStyle(color: Colors.white70),
                  ),
                  onChanged: (v) {
                    setState(() => _dishIsActive = v);
                  },
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _savingDish ? null : _saveDish,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFD54F),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(
                      _savingDish ? 'Kaydediliyor...' : 'İmza Tabak Ekle',
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Not: Şimdilik URL ile kayıt yapıyoruz. Sonraki adımda fotoğraf yükleme ve silme eklenebilir.',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 12,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Galeri Kayıtları',
            style: TextStyle(
              color: Color(0xFFFFD54F),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _GalleryAdminList(chefId: widget.chefId),
          const SizedBox(height: 24),
          const Text(
            'İmza Tabak Kayıtları',
            style: TextStyle(
              color: Color(0xFFFFD54F),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _SignatureDishAdminList(chefId: widget.chefId),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _AdminSectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _AdminSectionCard({
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF171717),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0x22FFD54F)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFFFFD54F),
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _AdminTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final int maxLines;

  const _AdminTextField({
    required this.controller,
    required this.label,
    required this.hint,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(color: Color(0xFFFFD54F)),
        hintStyle: const TextStyle(color: Colors.white38),
        filled: true,
        fillColor: const Color(0xFF222222),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0x22FFD54F)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0x88FFD54F)),
        ),
      ),
    );
  }
}

class _GalleryAdminList extends StatelessWidget {
  final String chefId;

  const _GalleryAdminList({required this.chefId});

  Future<void> _confirmDelete(BuildContext context, String docId) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: const Color(0xFF1A1A1A),
            title: const Text(
              'Galeri görselini sil',
              style: TextStyle(color: Colors.white),
            ),
            content: const Text(
              'Bu kayıt kalıcı olarak silinecek. Emin misiniz?',
              style: TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Vazgeç'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                ),
                child: const Text('Sil'),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed) return;

    await FirebaseFirestore.instance
        .collection('chef_gallery')
        .doc(docId)
        .delete();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Galeri görseli silindi.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('chef_gallery')
          .where('chefId', isEqualTo: chefId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(
              child: CircularProgressIndicator(
                color: Color(0xFFFFD54F),
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return Text(
            'Galeri listesi yüklenemedi: ${snapshot.error}',
            style: const TextStyle(color: Colors.white70),
          );
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF171717),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0x22FFD54F)),
            ),
            child: const Text(
              'Henüz galeri kaydı yok.',
              style: TextStyle(color: Colors.white70),
            ),
          );
        }

        return Column(
          children: docs.map((doc) {
            final m = doc.data();
            final imageUrl = (m['imageUrl'] ?? '').toString();
            final caption = (m['caption'] ?? '').toString();

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF171717),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0x22FFD54F)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: imageUrl.isEmpty
                        ? null
                        : () => showImagePreview(context, imageUrl),
                    child: Container(
                      width: 72,
                      height: 72,
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        color: const Color(0xFF222222),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: imageUrl.isEmpty
                          ? const Icon(
                              Icons.image_not_supported_outlined,
                              color: Colors.white54,
                            )
                          : Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) {
                                return const Icon(
                                  Icons.broken_image_outlined,
                                  color: Colors.white54,
                                );
                              },
                            ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          caption.isEmpty ? 'Açıklamasız görsel' : caption,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          doc.id,
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Sil',
                    onPressed: () => _confirmDelete(context, doc.id),
                    icon: const Icon(
                      Icons.delete_outline,
                      color: Colors.redAccent,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _SignatureDishAdminList extends StatelessWidget {
  final String chefId;

  const _SignatureDishAdminList({required this.chefId});

  Future<void> _confirmDelete(BuildContext context, String docId) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: const Color(0xFF1A1A1A),
            title: const Text(
              'İmza tabağı sil',
              style: TextStyle(color: Colors.white),
            ),
            content: const Text(
              'Bu kayıt kalıcı olarak silinecek. Emin misiniz?',
              style: TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Vazgeç'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                ),
                child: const Text('Sil'),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed) return;

    await FirebaseFirestore.instance
        .collection('chef_signature_dishes')
        .doc(docId)
        .delete();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('İmza tabak silindi.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('chef_signature_dishes')
          .where('chefId', isEqualTo: chefId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(
              child: CircularProgressIndicator(
                color: Color(0xFFFFD54F),
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return Text(
            'İmza tabak listesi yüklenemedi: ${snapshot.error}',
            style: const TextStyle(color: Colors.white70),
          );
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF171717),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0x22FFD54F)),
            ),
            child: const Text(
              'Henüz imza tabak kaydı yok.',
              style: TextStyle(color: Colors.white70),
            ),
          );
        }

        return Column(
          children: docs.map((doc) {
            final m = doc.data();
            final title = (m['title'] ?? 'İsimsiz Tabak').toString();
            final description = (m['description'] ?? '').toString();
            final imageUrl = (m['imageUrl'] ?? '').toString();
            final isActive = m['isActive'] == true;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF171717),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0x22FFD54F)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: const Color(0xFF222222),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: imageUrl.isEmpty
                        ? const Icon(
                            Icons.image_not_supported_outlined,
                            color: Colors.white54,
                          )
                        : GestureDetector(
                            onTap: () => showImagePreview(context, imageUrl),
                            child: Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) {
                                return const Icon(
                                  Icons.broken_image_outlined,
                                  color: Colors.white54,
                                );
                              },
                            ),
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (description.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              isActive
                                  ? Icons.check_circle
                                  : Icons.pause_circle,
                              size: 16,
                              color: isActive
                                  ? const Color(0xFFFFD54F)
                                  : Colors.white54,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              isActive ? 'Aktif' : 'Pasif',
                              style: TextStyle(
                                color: isActive
                                    ? const Color(0xFFFFD54F)
                                    : Colors.white54,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      IconButton(
                        tooltip: 'Aktif/Pasif',
                        onPressed: () async {
                          await FirebaseFirestore.instance
                              .collection('chef_signature_dishes')
                              .doc(doc.id)
                              .update({
                            'isActive': !isActive,
                          });
                        },
                        icon: Icon(
                          isActive
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: const Color(0xFFFFD54F),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Sil',
                        onPressed: () => _confirmDelete(context, doc.id),
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.redAccent,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
