import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sofrasofra_arena_v2/modules/sef_akademi_dersleri.dart';
import 'package:sofrasofra_arena_v2/modules/widgets/sef_imza_tabaklari_section.dart';
import 'package:sofrasofra_arena_v2/modules/widgets/sef_itibar_header.dart';
import 'package:sofrasofra_arena_v2/modules/widgets/sef_catering_section.dart';
import 'package:sofrasofra_arena_v2/modules/create_reservation_page.dart';

class SefItibarSayfasi extends StatefulWidget {
  final String dukkanId;
  final bool isAdmin;

  const SefItibarSayfasi({
    super.key,
    required this.dukkanId,
    this.isAdmin = false,
  });

  @override
  State<SefItibarSayfasi> createState() => _SefItibarSayfasiState();
}

String _safeHttpUrlOrEmpty(String? url) {
  final value = (url ?? '').trim();
  if (value.startsWith('http://') || value.startsWith('https://')) {
    return value;
  }
  return '';
}

class _SefItibarSayfasiState extends State<SefItibarSayfasi> {
  static const Color gold = Color(0xFFFFB300);
  static const Color bg = Color(0xFF050505);

  final ImagePicker _picker = ImagePicker();
  bool _busy = false;

  String get _chefId => widget.dukkanId.trim();

  DocumentReference<Map<String, dynamic>> get _chefProfileRef =>
      FirebaseFirestore.instance.collection('chef_profiles').doc(_chefId);

  Future<Uint8List?> _pickImage() async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
    );
    if (file == null) return null;
    return file.readAsBytes();
  }

  Future<String> _upload(Uint8List data, String path) async {
    final ref = FirebaseStorage.instance.ref().child(path);
    final task = await ref.putData(
      data,
      SettableMetadata(contentType: 'image/jpeg'),
    );
    return task.ref.getDownloadURL();
  }

  Future<void> _updateProfileImage() async {
    if (_busy) return;

    final img = await _pickImage();
    if (img == null) return;

    setState(() => _busy = true);

    try {
      final url = await _upload(
        img,
        'chef_profiles/$_chefId/profile/${DateTime.now().millisecondsSinceEpoch}.jpg',
      );

      await _chefProfileRef.set({
        'chefId': _chefId,
        'ownerId': _chefId,
        'dukkanId': _chefId,
        'img': url,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil fotoğrafı güncellendi.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Profil fotoğrafı yüklenemedi: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _removeProfileImage() async {
    if (_busy) return;

    setState(() => _busy = true);

    try {
      await _chefProfileRef.set({
        'img': '',
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil fotoğrafı silindi.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Profil fotoğrafı silinemedi: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _updateCoverImage() async {
    if (_busy) return;

    final img = await _pickImage();
    if (img == null) return;

    setState(() => _busy = true);

    try {
      final url = await _upload(
        img,
        'chef_profiles/$_chefId/cover/${DateTime.now().millisecondsSinceEpoch}.jpg',
      );

      await _chefProfileRef.set({
        'chefId': _chefId,
        'ownerId': _chefId,
        'dukkanId': _chefId,
        'coverImage': url,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kapak görseli güncellendi.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kapak görseli yüklenemedi: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _removeCoverImage() async {
    if (_busy) return;

    setState(() => _busy = true);

    try {
      await _chefProfileRef.set({
        'coverImage': '',
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kapak görseli silindi.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kapak görseli silinemedi: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _addGalleryImage() async {
    if (_busy) return;

    final img = await _pickImage();
    if (img == null) return;

    setState(() => _busy = true);

    try {
      final url = await _upload(
        img,
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Galeriye fotoğraf eklendi.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Galeri fotoğrafı eklenemedi: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _removeGalleryImage(String imageUrl) async {
    if (_busy) return;

    setState(() => _busy = true);

    try {
      await _chefProfileRef.set({
        'gallery': FieldValue.arrayRemove([imageUrl]),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Galeri fotoğrafı silindi.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Galeri fotoğrafı silinemedi: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  void _openImage(String url) {
    final safe = _safeHttpUrlOrEmpty(url);
    if (safe.isEmpty) return;

    showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(12),
        child: Stack(
          children: [
            InteractiveViewer(
              minScale: 0.8,
              maxScale: 4,
              child: Image.network(
                safe,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const SizedBox(
                  height: 280,
                  child: Center(
                    child: Icon(Icons.broken_image, color: Colors.white30),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(180),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white10),
                  ),
                  child: const Icon(Icons.close, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
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
        letterSpacing: 1.6,
      ),
    );
  }

  Widget _buildQuickActions(String displayName) {
    return const SizedBox.shrink();
  }

  Widget _buildQuickActionsContent(String displayName) {
    return SectionCard(
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CreateReservationPage(
                chefId: _chefId,
                chefName: displayName,
                tableTitle: '8 Kişilik Özel Şef Masası Deneyimi',
                concept: 'Tadım Menüsü',
                capacity: '8 Kişi',
                unitPrice: 1500,
              ),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle('DASHBOARD HIZLI GEÇİŞ'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () {},
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(8),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: const Column(
                        children: [
                          Icon(Icons.verified_outlined, color: gold, size: 22),
                          SizedBox(height: 8),
                          Text(
                            'İTİBAR',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SefAkademiDersleri(
                            chefId: _chefId,
                            chefName: displayName,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(8),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: const Column(
                        children: [
                          Icon(Icons.school_outlined, color: gold, size: 22),
                          SizedBox(height: 8),
                          Text(
                            'AKADEMİ',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CreateReservationPage(
                            chefId: _chefId,
                            chefName: displayName,
                            tableTitle: '8 Kişilik Özel Şef Masası Deneyimi',
                            concept: 'Tadım Menüsü',
                            capacity: '8 Kişi',
                            unitPrice: 1500,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(8),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: const Column(
                        children: [
                          Icon(Icons.event_seat_outlined,
                              color: gold, size: 22),
                          SizedBox(height: 8),
                          Text(
                            'REZERVASYON',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAccess(String displayName) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('HIZLI ERİŞİM'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SefAkademiDersleri(
                        chefId: _chefId,
                        chefName: displayName,
                      ),
                    ),
                  );
                },
                child: const ChipLabel('Şef Akademisi'),
              ),
              const ChipLabel('İmza Mutfağı'),
              InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CreateReservationPage(
                        chefId: _chefId,
                        chefName: displayName,
                        tableTitle: '8 Kişilik Özel Şef Masası Deneyimi',
                        concept: 'Tadım Menüsü',
                        capacity: '8 Kişi',
                        unitPrice: 1500,
                      ),
                    ),
                  );
                },
                child: const ChipLabel('Şefin Masası'),
              ),
              // const ChipLabel('Kurumsal Davetler'),
            ],
          ),
          const SizedBox(height: 14),
          RichText(
            text: const TextSpan(
              children: [
                TextSpan(
                  text: 'Rezervasyon oluşturmak için ',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15.5,
                    height: 1.6,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextSpan(
                  text: 'Şefin Masası',
                  style: TextStyle(
                    color: Color(0xFFFFB300),
                    fontSize: 15.5,
                    height: 1.6,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                TextSpan(
                  text: "'na tıklayın.",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15.5,
                    height: 1.6,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
        ],
      ),
    );
  }

  Widget _buildCurriculumSection() {
    return const SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionTitleText('AKADEMİ MÜFREDATI'),
          SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              ChipLabel('Osmanlı'),
              ChipLabel('Tabak Tasarım'),
              ChipLabel('Dünya Mutfağı'),
              ChipLabel('Maliyet'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStorySection(String hikaye) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('ŞEF HİKAYESİ'),
          const SizedBox(height: 12),
          Text(
            hikaye,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGallerySection(List<String> gallery) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Expanded(
              child: Text(
                'GALERİ',
                style: TextStyle(
                  color: gold,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.6,
                ),
              ),
            ),
            if (widget.isAdmin)
              GestureDetector(
                onTap: _addGalleryImage,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: gold,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.add_photo_alternate,
                        color: Colors.black,
                        size: 18,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Fotoğraf Ekle',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        if (gallery.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 18),
            decoration: BoxDecoration(
              color: const Color(0xFF101010),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white10),
            ),
            child: Text(
              widget.isAdmin
                  ? 'Henüz galeri fotoğrafı yok. Sağdaki butonla ilk fotoğrafı ekleyebilirsin.'
                  : 'Henüz galeri fotoğrafı yok.',
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 12,
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
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.05,
            ),
            itemBuilder: (context, index) {
              final url = gallery[index].trim();

              return GestureDetector(
                onTap: () => _openImage(url),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      NetworkImageWidget(url: url),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white10),
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      if (widget.isAdmin)
                        Positioned(
                          top: 6,
                          right: 6,
                          child: GestureDetector(
                            onTap: () => _removeGalleryImage(url),
                            child: Container(
                              padding: const EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                color: Colors.black.withAlpha(170),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                color: Colors.redAccent,
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _chefLiveStatusCard(String chefId, String displayName) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('chef_table_reservations')
          .where('chefId', isEqualTo: chefId)
          .orderBy('createdAt', descending: true)
          .limit(1)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SectionCard(
            child: SizedBox(
              height: 96,
              child: Center(
                child: CircularProgressIndicator(color: gold),
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return const SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionTitleText('CANLI DURUM'),
                SizedBox(height: 12),
                Text(
                  'Son aktivite yüklenemedi.',
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          );
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return const SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionTitleText('CANLI DURUM'),
                SizedBox(height: 12),
                Text(
                  'Henüz rezervasyon aktivitesi bulunmuyor.',
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          );
        }

        final data = docs.first.data();
        final tableTitle = (data['tableTitle'] ?? 'Rezervasyon').toString();
        final flowStatus =
            (data['reservationFlowStatus'] ?? 'bilinmiyor').toString();
        final paymentStatus =
            (data['paymentStatus'] ?? 'bilinmiyor').toString();
        final guestCount = (data['guestCount'] ?? '-').toString();

        return SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionTitle('CANLI DURUM'),
              const SizedBox(height: 12),
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CreateReservationPage(
                        chefId: _chefId,
                        chefName: displayName,
                        tableTitle: '8 Kişilik Özel Şef Masası Deneyimi',
                        concept: 'Tadım Menüsü',
                        capacity: '8 Kişi',
                        unitPrice: 1500,
                      ),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          tableTitle,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        color: gold,
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Akış: $flowStatus',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(height: 4),
              Text(
                'Ödeme: $paymentStatus',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(height: 4),
              Text(
                'Kişi sayısı: $guestCount',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_chefId.isEmpty) {
      return const Scaffold(
        backgroundColor: bg,
        body: Center(
          child: Text(
            'Hata: dukkanId boş geldi.',
            style: TextStyle(color: Colors.white70),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: bg,
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _chefProfileRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: gold),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Hata: ${snapshot.error}',
                  style: const TextStyle(color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final data = snapshot.data?.data() ?? <String, dynamic>{};

          final bool isActive = data['isActive'] == true;

          final String displayName =
              (data['displayName'] ?? data['adSoyad'] ?? 'Usta Şef')
                  .toString()
                  .trim();

          final String bio = (data['bio'] ?? '').toString().trim();
          final String uzmanlik = (data['uzmanlik'] ?? '').toString().trim();
          final String unvan = (data['unvan'] ?? '').toString().trim();

          final String subtitle = [
            if (uzmanlik.isNotEmpty) uzmanlik,
            if (unvan.isNotEmpty) unvan,
          ].join(' • ').trim();

          final String profileImage = (data['img'] ?? '').toString().trim();
          final String coverImage =
              (data['coverImage'] ?? '').toString().trim();

          final List<String> gallery = (data['gallery'] is List)
              ? List<String>.from(
                  (data['gallery'] as List).map((e) => e.toString()),
                )
              : <String>[];

          final String puan = (data['itibar_puani'] ?? '4.9').toString();
          final String mezun = (data['mezun_sayisi'] ?? '12').toString();
          final String muhur = (data['muhur_sayisi'] ?? '24').toString();

          final String hikaye = bio.isNotEmpty
              ? bio
              : '$displayName, Arena’nın öne çıkan şeflerinden biridir. '
                  '${uzmanlik.isNotEmpty ? uzmanlik : 'gastronomi'} alanında güçlü birikimiyle öne çıkar.';

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                backgroundColor: Colors.black,
                pinned: true,
                expandedHeight: 440,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: gold),
                  onPressed: () => Navigator.pop(context),
                ),
                title: const Text(
                  'ŞEF İTİBAR PROFİLİ',
                  style: TextStyle(
                    color: gold,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: HeroHeader(
                    coverImageUrl: coverImage,
                    profileImageUrl: profileImage,
                    title: displayName,
                    subtitle:
                        subtitle.isNotEmpty ? subtitle : 'Gastronomi Uzmanı',
                    bio: bio,
                    isAdmin: widget.isAdmin,
                    isActive: isActive,
                    onEditCover: _updateCoverImage,
                    onDeleteCover: _removeCoverImage,
                    onEditProfile: _updateProfileImage,
                    onDeleteProfile: _removeProfileImage,
                    onOpenProfile: profileImage.isNotEmpty
                        ? () => _openImage(profileImage)
                        : null,
                    onOpenCover: coverImage.isNotEmpty
                        ? () => _openImage(coverImage)
                        : null,
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 36),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      StatsRow(
                        puan: puan,
                        mezun: mezun,
                        muhur: muhur,
                      ),
                      const SizedBox(height: 18),
                      _buildQuickActionsContent(displayName),
                      const SizedBox(height: 18),
                      _chefLiveStatusCard(_chefId, displayName),
                      const SizedBox(height: 18),
                      _buildQuickAccess(displayName),
                      const SizedBox(height: 18),
                      _buildCurriculumSection(),
                      const SizedBox(height: 18),
                      _buildStorySection(hikaye),
                      const SizedBox(height: 18),
                      SefCateringSection(
                        chefId: _chefId,
                        chefName: displayName,
                      ),
                      const SizedBox(height: 18),
                      SectionCard(
                        child: _buildGallerySection(gallery),
                      ),
                      const SizedBox(height: 18),
                      const SectionCard(
                        child: _SizedImzaSectionPlaceholder(),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SizedImzaSectionPlaceholder extends StatelessWidget {
  const _SizedImzaSectionPlaceholder();

  @override
  Widget build(BuildContext context) {
    final state = context.findAncestorStateOfType<_SefItibarSayfasiState>();
    final chefId = state?._chefId ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 2),
        SefImzaTabaklariSection(chefId: chefId),
      ],
    );
  }
}

class SectionTitleText extends StatelessWidget {
  final String text;

  const SectionTitleText(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFFFFB300), // gold
        fontSize: 12,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.6,
      ),
    );
  }
}

class SectionCard extends StatelessWidget {
  final Widget child;

  const SectionCard({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
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
}

class ChipLabel extends StatelessWidget {
  final String text;

  const ChipLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(8),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white10),
      ),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const StatCard({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF121212),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0x22FFB300)),
      ),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFFFFB300), size: 22),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 10,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class StatsRow extends StatelessWidget {
  final String puan;
  final String mezun;
  final String muhur;

  const StatsRow({
    super.key,
    required this.puan,
    required this.mezun,
    required this.muhur,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: StatCard(
            icon: Icons.star_rounded,
            value: puan,
            label: 'İTİBAR',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: StatCard(
            icon: Icons.school_rounded,
            value: mezun,
            label: 'MEZUN',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: StatCard(
            icon: Icons.workspace_premium_rounded,
            value: muhur,
            label: 'MÜHÜR',
          ),
        ),
      ],
    );
  }
}

class NetworkImageWidget extends StatelessWidget {
  final String url;

  const NetworkImageWidget({
    super.key,
    required this.url,
  });

  @override
  Widget build(BuildContext context) {
    final safe = _safeHttpUrlOrEmpty(url);

    if (safe.isEmpty) {
      return Container(
        color: Colors.white10,
        child: const Center(
          child: Icon(Icons.image, color: Colors.white24),
        ),
      );
    }

    return Image.network(
      safe,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) {
        return Container(
          color: Colors.white10,
          child: const Center(
            child: Icon(Icons.broken_image, color: Colors.white24),
          ),
        );
      },
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return const Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Color(0xFFFFB300),
            ),
          ),
        );
      },
    );
  }
}
