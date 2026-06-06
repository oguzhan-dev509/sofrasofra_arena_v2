import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sofrasofra_arena_v2/modules/sef_akademi_dersleri.dart';
import 'package:sofrasofra_arena_v2/modules/widgets/sef_imza_tabaklari_section.dart';
import 'package:sofrasofra_arena_v2/modules/widgets/sef_itibar_header.dart';

import 'package:sofrasofra_arena_v2/modules/create_reservation_page.dart';
import 'package:sofrasofra_arena_v2/modules/widgets/sef_akademi_section.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sofrasofra_arena_v2/modules/widgets/chef_reviews_section.dart';
import 'package:sofrasofra_arena_v2/modules/widgets/sef_membership_card.dart';
import 'package:sofrasofra_arena_v2/modules/sef_vitrin_icerik_yonetimi.dart';
import 'package:sofrasofra_arena_v2/modules/widgets/chef_gallery_price_strip.dart';
import 'package:sofrasofra_arena_v2/modules/widgets/chef_gallery_sales_bridge.dart';

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
  int _selectedChefGalleryIndex = 0;
  String _membershipType = 'free';
  int _maxGalleryPhoto = 6;
  int _maxVideoLink = 0;
  bool _membershipLoading = true;
  String get _chefId => widget.dukkanId.trim();

  DocumentReference<Map<String, dynamic>> get _chefProfileRef =>
      FirebaseFirestore.instance.collection('chef_profiles').doc(_chefId);
  @override
  void initState() {
    super.initState();
    _loadChefMembership();
  }

  Future<void> _loadChefMembership() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('chef_profiles')
          .doc(_chefId)
          .get();

      final data = doc.data() ?? <String, dynamic>{};
      final rawType =
          (data['membershipType'] ?? 'free').toString().toLowerCase();
      debugPrint(
          '### SEF_ITIBAR_SAYFASI BUILD aktif | chefId=$_chefId | isAdmin=${widget.isAdmin}');
      if (!mounted) return;

      setState(() {
        _membershipType = rawType;
        _membershipLoading = false;

        switch (rawType) {
          case 'premium':
            _maxGalleryPhoto = 40;
            _maxVideoLink = 3;
            break;
          case 'pro':
            _maxGalleryPhoto = 15;
            _maxVideoLink = 1;
            break;
          default:
            _maxGalleryPhoto = 6;
            _maxVideoLink = 0;
        }
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

  Future<Uint8List?> _pickImage() async {
    try {
      final file = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
      );

      if (file == null) {
        debugPrint('IMAGE PICK CANCELLED');
        return null;
      }

      final bytes = await file.readAsBytes();
      debugPrint('IMAGE PICKED bytes=${bytes.length}');
      return bytes;
    } catch (e, st) {
      debugPrint('IMAGE PICK ERROR => $e');
      debugPrintStack(stackTrace: st);
      return null;
    }
  }

  Future<String> _upload(Uint8List data, String path) async {
    try {
      debugPrint('AUTH UID=${FirebaseAuth.instance.currentUser?.uid}');
      debugPrint('CHEF ID=$_chefId');
      debugPrint(
          'UPLOAD START path=$path bytes=${data.length} chefId=$_chefId');

      final ref = FirebaseStorage.instance.ref().child(path);

      final task = await ref.putData(
        data,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      final url = await task.ref.getDownloadURL();
      debugPrint('UPLOAD SUCCESS url=$url');
      return url;
    } catch (e, st) {
      debugPrint('UPLOAD ERROR => $e');
      debugPrintStack(stackTrace: st);
      rethrow;
    }
  }

  Future<void> _updateProfileImage() async {
    if (_busy) return;

    if (_chefId.trim().isEmpty) {
      debugPrint('PROFILE IMAGE ERROR => chefId is empty');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Şef kimliği bulunamadı.')),
      );
      return;
    }

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

      debugPrint('PROFILE IMAGE FIRESTORE UPDATED chefId=$_chefId');

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil fotoğrafı güncellendi.')),
      );
    } catch (e, st) {
      debugPrint('PROFILE IMAGE UPDATE ERROR => $e');
      debugPrintStack(stackTrace: st);

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

    if (_chefId.trim().isEmpty) {
      debugPrint('REMOVE PROFILE IMAGE ERROR => chefId is empty');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Şef kimliği bulunamadı.')),
      );
      return;
    }

    setState(() => _busy = true);

    try {
      await _chefProfileRef.set({
        'img': '',
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      debugPrint('PROFILE IMAGE REMOVED chefId=$_chefId');

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil fotoğrafı silindi.')),
      );
    } catch (e, st) {
      debugPrint('REMOVE PROFILE IMAGE ERROR => $e');
      debugPrintStack(stackTrace: st);

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

// ignore: unused_element
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
              InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SefVitrinIcerikYonetimiSayfasi(
                        chefId: _chefId,
                        chefName: displayName,
                      ),
                    ),
                  );
                },
                child: const ChipLabel('Şef Vitrin Yönetimi'),
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
        ],
      ),
    );
  }

// ignore: unused_element
  Widget _buildCurriculumSection() {
    return SectionCard(
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
        ),
        child: ExpansionTile(
          tilePadding: EdgeInsets.zero,
          childrenPadding: EdgeInsets.zero,
          iconColor: const Color(0xFFFFB300),
          collapsedIconColor: const Color(0xFFFFB300),
          initiallyExpanded: false,
          title: const SectionTitleText('AKADEMİ MÜFREDATI'),
          subtitle: const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              'Ders başlıklarını görmek için tıklayın.',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          children: const [
            SizedBox(height: 14),
            SefAkademiSection(),
          ],
        ),
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
    final safeSelectedIndex = gallery.isEmpty
        ? 0
        : _selectedChefGalleryIndex.clamp(0, gallery.length - 1).toInt();

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
              ElevatedButton.icon(
                onPressed: _addGalleryImage,
                icon: const Icon(Icons.add_photo_alternate_outlined, size: 18),
                label: const Text('Fotoğraf Ekle'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: gold,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 14),
        if (gallery.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFF111111),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white10),
            ),
            child: const Text(
              'Henüz galeri fotoğrafı eklenmemiş.',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          )
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: gallery.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.62,
                ),
                itemBuilder: (context, index) {
                  final url = gallery[index].trim();
                  final isSelected = index == safeSelectedIndex;

                  return Column(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            setState(() {
                              _selectedChefGalleryIndex = index;
                            });
                            _openImage(url);
                          },
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Positioned.fill(
                                  child: Image.network(
                                    url,
                                    fit: BoxFit.cover,
                                    gaplessPlayback: true,
                                    filterQuality: FilterQuality.medium,
                                    loadingBuilder: (context, child, progress) {
                                      if (progress == null) return child;

                                      return Container(
                                        color: const Color(0xFF111111),
                                        alignment: Alignment.center,
                                        child: const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: gold,
                                          ),
                                        ),
                                      );
                                    },
                                    errorBuilder: (_, __, ___) => Container(
                                      color: const Color(0xFF151515),
                                      alignment: Alignment.center,
                                      child: const Icon(
                                        Icons.image_not_supported_outlined,
                                        color: Colors.white38,
                                        size: 22,
                                      ),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  left: 8,
                                  top: 8,
                                  child: GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTap: () => _openImage(url),
                                    child: Container(
                                      width: 34,
                                      height: 34,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: Colors.black
                                            .withValues(alpha: 0.58),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white
                                              .withValues(alpha: 0.16),
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.visibility_rounded,
                                        color: Colors.white,
                                        size: 17,
                                      ),
                                    ),
                                  ),
                                ),
                                Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: isSelected ? gold : Colors.white10,
                                      width: isSelected ? 2.5 : 1,
                                    ),
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                ),
                                if (widget.isAdmin)
                                  Positioned(
                                    top: 6,
                                    right: 6,
                                    child: GestureDetector(
                                      behavior: HitTestBehavior.opaque,
                                      onTap: () => _removeGalleryImage(url),
                                      child: Container(
                                        width: 34,
                                        height: 34,
                                        alignment: Alignment.center,
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
                        ),
                      ),
                      const SizedBox(height: 6),
                      ChefGalleryPriceStrip(
                        chefId: _chefId,
                        imageUrl: url,
                      ),
                      const SizedBox(height: 4),
                      SizedBox(
                        height: 64,
                        width: double.infinity,
                        child: ChefGallerySalesActions(
                          chefId: _chefId,
                          imageUrl: url,
                          isAdmin: widget.isAdmin,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
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
                      if (widget.isAdmin)
                        Row(
                          children: [
                            const Text(
                              '1500 ₺',
                              style: TextStyle(
                                color: Color(0xFFFFB300),
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Icon(Icons.edit, color: Colors.white70, size: 18),
                            const SizedBox(width: 4),
                            Icon(Icons.delete,
                                color: Colors.redAccent, size: 18),
                          ],
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
          debugPrint('### HERO HEADER CURRENT FILE CALISIYOR');
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
                      if (widget.isAdmin) ...[
                        SefMembershipCard(
                          membershipType: _membershipType,
                          isLoading: _membershipLoading,
                          galleryLimit: _maxGalleryPhoto,
                          videoLimit: _maxVideoLink,
                          onTapUpgrade: () {},
                        ),
                        const SizedBox(height: 18),
                      ],
                      SectionCard(
                        child: _buildGallerySection(gallery),
                      ),
                      const SizedBox(height: 18),
                      const SectionCard(
                        child: _SizedImzaSectionPlaceholder(),
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
                      SectionCard(
                        child: ChefReviewsSection(
                          chefId: _chefId,
                        ),
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
        SefImzaTabaklariSection(
          chefId: chefId,
          canManage: state?.widget.isAdmin ?? false,
        ),
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
