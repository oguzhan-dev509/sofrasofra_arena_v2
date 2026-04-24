// ===============================
// EV LEZZETLERI / MAHALLE MUTFAĞI ONLY
// Bu dosya sadece Mahalle Mutfağı / Ev Lezzetleri vitrini içindir.
// Şef profili, şef galeri, şef itibar medya kontrolleri ile karıştırılmamalı.
// ===============================

import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sofrasofra_arena_v2/merchant/mahalle_urun_gorsel_yonetimi.dart';

class VitrinMerkeziSayfasi extends StatefulWidget {
  const VitrinMerkeziSayfasi({super.key});

  @override
  State<VitrinMerkeziSayfasi> createState() => _VitrinMerkeziSayfasiState();
}

class _VitrinMerkeziSayfasiState extends State<VitrinMerkeziSayfasi> {
  static const Color _gold = Color(0xFFFFB300);

  static const String _placeholderImg =
      'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?auto=format&fit=crop&w=1200&q=60';

  final ImagePicker _picker = ImagePicker();

  String dukkanAdi = '';
  String sellerId = '';
  bool _sellerYukleniyor = true;
  bool _gonderiliyor = false;

  final List<String> evAltKategoriler = const [
    'EV YEMEKLERİ',
    'EV YAPIMI ÇİKOLATA & TATLILAR',
    'EV YAPIMI SÜT ÜRÜNLERİ',
    'EV YAPIMI TURŞU & DİĞERLERİ',
  ];

  String seciliEvAltKategori = 'EV YEMEKLERİ';

  late List<Map<String, dynamic>> _onSekizUrun;

  @override
  void initState() {
    super.initState();
    _onSekizUrun = List.generate(18, (_) => _bosUrun());
    _sellerBilgisiniYukle();
  }

  Map<String, dynamic> _bosUrun() => {
        'id': '', // 🔥 docId placeholder (sonradan doldurulacak)

        'ad': '',
        'tarif': '',
        'gelAlFiyat': '',
        'goturFiyat': '',

        'images': <String>[], // 🔒 artık max 3 olacak
        'img': '',

        'teslimat': true,
      };

  Future<void> _sellerBilgisiniYukle() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      final uid = user?.uid ?? '';

      if (uid.isEmpty) {
        if (!mounted) return;
        setState(() {
          sellerId = '';
          dukkanAdi = 'Satıcı Merkezi';
          _sellerYukleniyor = false;
        });
        return;
      }

      final doc =
          await FirebaseFirestore.instance.collection('sellers').doc(uid).get();

      final data = doc.data() ?? <String, dynamic>{};

      final loadedDukkanAdi = (data['dukkanAdi'] ??
              data['dukkan'] ??
              data['sellerName'] ??
              data['adSoyad'] ??
              '')
          .toString()
          .trim();

      if (!mounted) return;
      setState(() {
        sellerId = uid;
        dukkanAdi =
            loadedDukkanAdi.isNotEmpty ? loadedDukkanAdi : 'Satıcı Merkezi';
        _sellerYukleniyor = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        sellerId = '';
        dukkanAdi = 'Satıcı Merkezi';
        _sellerYukleniyor = false;
      });
    }
  }

  Future<String> _uploadImageBytesToStorage(Uint8List bytes) async {
    final user = FirebaseAuth.instance.currentUser;

    debugPrint('--- STORAGE UPLOAD START ---');
    debugPrint('AUTH USER NULL? ${user == null}');
    debugPrint('AUTH UID=${user?.uid}');
    debugPrint('AUTH IS ANON=${user?.isAnonymous}');
    debugPrint('SELLER ID=$sellerId');
    debugPrint('BYTES=${bytes.length}');

    if (user == null) {
      throw Exception('Giriş yapan kullanıcı bulunamadı.');
    }

    await user.reload();
    final refreshedUser = FirebaseAuth.instance.currentUser;

    debugPrint('REFRESHED AUTH UID=${refreshedUser?.uid}');
    debugPrint('REFRESHED AUTH IS ANON=${refreshedUser?.isAnonymous}');

    final uid = refreshedUser?.uid ?? user.uid;
    final ts = DateTime.now().millisecondsSinceEpoch;
    final path = 'urunler/$uid/urun_$ts.jpg';

    debugPrint('UPLOAD PATH=$path');

    final ref = FirebaseStorage.instance.ref().child(path);

    try {
      final snap = await ref.putData(
        bytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      final url = await snap.ref.getDownloadURL();
      debugPrint('UPLOAD SUCCESS URL=$url');
      debugPrint('--- STORAGE UPLOAD END ---');
      return url;
    } catch (e, st) {
      debugPrint('UPLOAD ERROR => $e');
      debugPrintStack(stackTrace: st);
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('### BUILD merchant_merkez A1');
    return Scaffold(
      backgroundColor: Colors.deepPurple,
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        elevation: 0,
        title: Text(
          _sellerYukleniyor
              ? 'MAHALLE TEST A1 / YÜKLENİYOR'
              : 'ZZZ_CANLI_DOSYA_123 / ${dukkanAdi.isEmpty ? 'Satıcı Merkezi' : dukkanAdi}',
          style: const TextStyle(
            color: _gold,
            fontWeight: FontWeight.w900,
            fontSize: 18,
            letterSpacing: 0.8,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.bug_report_outlined),
            tooltip: 'Mahalle Foto Test',
            color: _gold,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const MahalleUrunGorselYonetimiSayfasi(
                    urunId: 'coGsgUKoC4fjBFfK2epQ',
                    urunAdi: 'Lahmacun',
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _evKategoriBaslikWidget(),
            _evAltKategoriSecici(),
            _hizliErisimBari(context),
            const SizedBox(height: 10),
            _urunGridiWidget(),
            const SizedBox(height: 110),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: _gold,
        onPressed: (_gonderiliyor || _sellerYukleniyor)
            ? null
            : _vitriniMuhurleFirestore,
        icon: _gonderiliyor
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.black,
                ),
              )
            : const Icon(Icons.send, color: Colors.black),
        label: Text(
          _gonderiliyor ? 'GÖNDERİLİYOR...' : "ARENA'YA GÖNDER",
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }

  Widget _evKategoriBaslikWidget() {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: _gold,
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Text(
          'EV LEZZETLERİ',
          style: TextStyle(
            color: Colors.black,
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.8,
          ),
        ),
      ),
    );
  }

  Widget _evAltKategoriSecici() {
    return SizedBox(
      height: 58,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        itemCount: evAltKategoriler.length,
        itemBuilder: (context, i) {
          final k = evAltKategoriler[i];
          final secili = seciliEvAltKategori == k;

          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: ChoiceChip(
              selected: secili,
              selectedColor: _gold,
              backgroundColor: Colors.white10,
              label: Text(
                k,
                style: TextStyle(
                  color: secili ? Colors.black : Colors.white70,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
              onSelected: (_) => setState(() => seciliEvAltKategori = k),
            ),
          );
        },
      ),
    );
  }

  Widget _hizliErisimBari(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _barButonWidget(
            Icons.location_on,
            'ADRES',
            () => _adresGirisPenceresi(context),
          ),
          _barButonWidget(
            Icons.credit_card,
            'ÖDEME',
            () => _odemePenceresiGoster(context),
          ),
        ],
      ),
    );
  }

  Widget _barButonWidget(IconData ikon, String metin, VoidCallback aksiyon) {
    return ActionChip(
      backgroundColor: Colors.white10,
      avatar: Icon(ikon, color: _gold, size: 16),
      label: Text(
        metin,
        style: const TextStyle(color: Colors.white, fontSize: 10),
      ),
      onPressed: aksiyon,
    );
  }

  Widget _urunGridiWidget() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 20,
        mainAxisSpacing: 25,
        childAspectRatio: 0.82,
      ),
      itemCount: 18,
      itemBuilder: (context, index) => _urunKaresiWidget(index),
    );
  }

  Widget _urunKaresiWidget(int i) {
    final dolu = (_onSekizUrun[i]['ad'] ?? '').toString().trim().isNotEmpty;

    final List<String> images =
        List<String>.from(_onSekizUrun[i]['images'] ?? []);

    final String url = images.isNotEmpty ? images.first.toString().trim() : '';

    Widget imgWidget;

    if (url.startsWith('http')) {
      imgWidget = Image.network(
        url,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, __, ___) => _bosFotoKutusu(i),
      );
    } else {
      imgWidget = _bosFotoKutusu(i);
    }

    return GestureDetector(
      onTap: dolu ? () => _urunDetayFormuAc(i) : () => _urunDetayFormuAc(i),
      child: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: _gold, width: 5),
                      boxShadow: dolu
                          ? [
                              BoxShadow(
                                color: _gold.withValues(alpha: 0.16),
                                blurRadius: 15,
                              ),
                            ]
                          : null,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: imgWidget,
                    ),
                  ),
                ),

                // === MAHALLE MUTFAĞI BAĞIMSIZ FOTO KONTROLLERİ START ===
                Positioned(
                  top: 8,
                  left: 8,
                  child: _buildMahalleOverlayButton(
                    icon: Icons.photo_library_outlined,
                    color: _gold,
                    tooltip: 'Foto paneli',
                    onTap: () => _openMahallePhotoPanel(i),
                  ),
                ),

                Positioned(
                  top: 8,
                  right: 8,
                  child: _buildMahalleOverlayButton(
                    icon: Icons.add_a_photo,
                    color: Colors.white,
                    tooltip: 'Foto ekle',
                    onTap: () => _addMahallePhoto(i),
                  ),
                ),

                if (dolu)
                  const Positioned(
                    bottom: 8,
                    right: 8,
                    child: Icon(Icons.edit, color: _gold, size: 14),
                  ),
                // === MAHALLE MUTFAĞI BAĞIMSIZ FOTO KONTROLLERİ END ===
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            dolu
                ? (_onSekizUrun[i]['ad'] ?? '').toString().toUpperCase()
                : 'BOŞ KUTU',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            dolu ? "${(_onSekizUrun[i]['gelAlFiyat'] ?? '')} TL" : '-',
            style: const TextStyle(
              color: _gold,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _bosFotoKutusu(int i) {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Center(
      child: userId.isEmpty
          ? const Icon(Icons.add_a_photo, color: Colors.white10, size: 30)
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: () => _urunDetayFormuAc(i),
                  icon: const Icon(
                    Icons.add_a_photo,
                    color: Colors.white54,
                    size: 30,
                  ),
                  tooltip: 'Fotoğraf ekle',
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () => _urunDetayFormuAc(i),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _gold,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                  ),
                  child: const Text(
                    'ÜRÜN BİLGİSİ',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildMahalleOverlayButton({
    required IconData icon,
    required Color color,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Tooltip(
          message: tooltip,
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.black.withAlpha(175),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white24),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x55000000),
                  blurRadius: 8,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Icon(icon, color: color, size: 18),
          ),
        ),
      ),
    );
  }

  Future<void> _addMahallePhoto(int i) async {
    try {
      final x = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (x == null) return;

      final bytes = await x.readAsBytes();
      final uploadedUrl = await _uploadImageBytesToStorage(bytes);

      final current = Map<String, dynamic>.from(_onSekizUrun[i]);
      final imgs = List<String>.from(current['images'] ?? []);

// 🔒 3 FOTO SINIRI
      if (imgs.length >= 3) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Free üyelikte en fazla 3 foto eklenebilir.'),
          ),
        );
        return;
      }

      imgs.add(uploadedUrl);

// 🔥 FIRESTORE'A YAZ (ASIL ÇÖZÜM)
      final docId = current['id']?.toString() ?? '';

      if (docId.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('urunler')
            .doc(docId)
            .update({
          'images': imgs,
          'img': imgs.isNotEmpty ? imgs.first : '',
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

// 🔄 UI GÜNCELLE
      if (!mounted) return;

      setState(() {
        _onSekizUrun[i] = {
          ...current,
          'images': imgs,
          'img': imgs.first,
        };
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '✅ Fotoğraf eklendi. Toplam: ${List<String>.from(_onSekizUrun[i]["images"] ?? []).length}',
          ),
        ),
      );
    } catch (e, st) {
      debugPrint('❌ _addMahallePhoto hata => $e');
      debugPrintStack(stackTrace: st);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Fotoğraf eklenemedi: $e')),
      );
    }
  }

  Future<void> _deleteMahallePhotoAt(int i, int imageIndex) async {
    final current = Map<String, dynamic>.from(_onSekizUrun[i]);
    final imgs = List<String>.from(current['images'] ?? []);

    if (imgs.isEmpty || imageIndex < 0 || imageIndex >= imgs.length) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silinecek fotoğraf bulunamadı')),
      );
      return;
    }

    final targetUrl = imgs[imageIndex];

    if (targetUrl.startsWith('http')) {
      try {
        final ref = FirebaseStorage.instance.refFromURL(targetUrl);
        await ref.delete();
      } catch (_) {}
    }

    imgs.removeAt(imageIndex);

// 🔥 FIRESTORE UPDATE EKLE
    final docId = current['id']?.toString() ?? '';

    if (docId.isNotEmpty) {
      await FirebaseFirestore.instance.collection('urunler').doc(docId).update({
        'images': imgs,
        'img': imgs.isNotEmpty ? imgs.first : '',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

// 🔄 UI GÜNCELLE
    if (!mounted) return;

    setState(() {
      _onSekizUrun[i] = {
        ...current,
        'images': imgs,
        'img': imgs.isNotEmpty ? imgs.first : '',
      };
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('🗑 Fotoğraf silindi')),
    );
  }

  void _openMahallePhotoPanel(int i) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0D0D0D),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModal) {
            final imgs = List<String>.from(_onSekizUrun[i]['images'] ?? []);

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 48,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'MAHALLE FOTO YÖNETİMİ',
                      style: TextStyle(
                        color: _gold,
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              await _addMahallePhoto(i);
                              if (!mounted) return;
                              setModal(() {});
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _gold,
                              minimumSize: const Size(double.infinity, 48),
                            ),
                            icon: const Icon(Icons.add_a_photo,
                                color: Colors.black),
                            label: const Text(
                              'FOTO EKLE',
                              style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (imgs.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 28),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(10),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: const Column(
                          children: [
                            Icon(Icons.photo_library_outlined,
                                color: Colors.white38, size: 34),
                            SizedBox(height: 8),
                            Text(
                              'Henüz galeri fotoğrafı yok',
                              style: TextStyle(
                                color: Colors.white60,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      SizedBox(
                        height: 220,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: imgs.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: 12),
                          itemBuilder: (context, imageIndex) {
                            final imageUrl = imgs[imageIndex];

                            return Container(
                              width: 170,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: _gold.withAlpha(140)),
                                color: Colors.black,
                              ),
                              child: Stack(
                                children: [
                                  Positioned.fill(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(18),
                                      child: Image.network(
                                        imageUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Container(
                                          color: Colors.white10,
                                          child: const Icon(
                                            Icons.broken_image_outlined,
                                            color: Colors.white38,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: _buildMahalleOverlayButton(
                                      icon: Icons.delete_outline,
                                      color: Colors.redAccent,
                                      tooltip: 'Bu fotoğrafı sil',
                                      onTap: () async {
                                        await _deleteMahallePhotoAt(
                                            i, imageIndex);
                                        if (!mounted) return;
                                        setModal(() {});
                                      },
                                    ),
                                  ),
                                  Positioned(
                                    left: 10,
                                    bottom: 10,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withAlpha(150),
                                        borderRadius: BorderRadius.circular(99),
                                      ),
                                      child: Text(
                                        '${imageIndex + 1}/${imgs.length}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(sheetContext),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.white24),
                          minimumSize: const Size(double.infinity, 46),
                        ),
                        child: const Text(
                          'KAPAT',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _mahalleSonFotoyuSil(int i) async {
    final current = _onSekizUrun[i];
    final imgs = List<String>.from(current['images'] ?? []);

    if (imgs.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silinecek fotoğraf yok')),
      );
      return;
    }

    final sonUrl = imgs.removeLast();

    if (sonUrl.startsWith('http')) {
      try {
        final ref = FirebaseStorage.instance.refFromURL(sonUrl);
        await ref.delete();
      } catch (_) {}
    }

    final docId = current['id']?.toString() ?? '';

    if (docId.isNotEmpty) {
      await FirebaseFirestore.instance.collection('urunler').doc(docId).update({
        'images': imgs,
        'img': imgs.isNotEmpty ? imgs.first : '',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    if (!mounted) return;

    setState(() {
      _onSekizUrun[i] = {
        ...current,
        'images': imgs,
        'img': imgs.isNotEmpty ? imgs.first : '',
      };
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('🗑 Son foto silindi')),
    );
  }

  void _urunDetayFormuAc(int i) {
    final ad = TextEditingController(text: _onSekizUrun[i]['ad']);
    final tarif = TextEditingController(text: _onSekizUrun[i]['tarif']);
    final gelAl = TextEditingController(text: _onSekizUrun[i]['gelAlFiyat']);
    final gotur = TextEditingController(text: _onSekizUrun[i]['goturFiyat']);
    bool teslim = _onSekizUrun[i]['teslimat'] == true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0D0D0D),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (c) => StatefulBuilder(
        builder: (context, setModal) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(c).viewInsets.bottom,
            left: 25,
            right: 25,
            top: 25,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'ÜRÜNÜ MÜHÜRLE',
                style: TextStyle(color: _gold, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 20),
              _inputWidget(ad, 'Yemek Adı', Icons.restaurant),
              _inputWidget(tarif, 'Tarif / İçerik', Icons.menu_book),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF151515),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: _gold.withOpacity(0.35)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.payments_outlined, color: _gold, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'FİYAT YÖNETİMİ',
                          style: TextStyle(
                            color: _gold,
                            fontWeight: FontWeight.w900,
                            fontSize: 13,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Güncel fiyatı buradan değiştir. En az bir fiyat gir.',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 11,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _inputWidget(
                            gelAl,
                            'Gel-Al Fiyatı',
                            Icons.storefront,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _inputWidget(
                            gotur,
                            'Götür Fiyatı',
                            Icons.delivery_dining,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SwitchListTile(
                title: const Text(
                  'Teslimat var mı?',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                value: teslim,
                activeColor: _gold,
                onChanged: (v) => setModal(() => teslim = v),
              ),
              const SizedBox(height: 10),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        try {
                          final x = await _picker.pickImage(
                            source: ImageSource.gallery,
                          );
                          if (x == null) return;

                          final bytes = await x.readAsBytes();
                          final uploadedUrl =
                              await _uploadImageBytesToStorage(bytes);

// 🔥 BURAYA EKLEYECEKSİN
                          final current = _onSekizUrun[i];
                          final imgs =
                              List<String>.from(current['images'] ?? []);

                          imgs.add(uploadedUrl);

                          final docId = current['id']?.toString() ?? '';

                          if (docId.isNotEmpty) {
                            await FirebaseFirestore.instance
                                .collection('urunler')
                                .doc(docId)
                                .update({
                              'images': imgs,
                              'img': imgs.first,
                              'updatedAt': FieldValue.serverTimestamp(),
                            });
                          }

// 🔽 BU ESKİ setState AYNI KALACAK
                          if (!mounted) return;

                          setState(() {
                            _onSekizUrun[i] = {
                              ...current,
                              "ad": ad.text.trim(),
                              "tarif": tarif.text.trim(),
                              "gelAlFiyat": gelAl.text.trim(),
                              "goturFiyat": gotur.text.trim(),
                              "teslimat": teslim,
                              "images": imgs,
                              "img": imgs.first,
                            };
                          });

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                "✅ Fotoğraf eklendi. Toplam: ${List<String>.from(_onSekizUrun[i]['images'] ?? []).length}",
                              ),
                            ),
                          );
                        } catch (e, st) {
                          debugPrint("❌ RESİM YÜKLEME HATASI => $e");
                          debugPrintStack(stackTrace: st);

                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text("❌ Resim yükleme hatası: $e")),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _gold,
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: Text(
                        kIsWeb ? 'FOTO EKLE (WEB)' : 'FOTO EKLE',
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        final current = _onSekizUrun[i];
                        final imgs = List<String>.from(current['images'] ?? []);

                        if (imgs.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Silinecek fotoğraf yok')),
                          );
                          return;
                        }

                        final last = imgs.removeLast();

                        if (last.startsWith('http')) {
                          try {
                            final ref =
                                FirebaseStorage.instance.refFromURL(last);
                            await ref.delete();
                          } catch (_) {}
                        }

                        if (!mounted) return;

                        setState(() {
                          _onSekizUrun[i] = {
                            ...current,
                            "ad": ad.text.trim(),
                            "tarif": tarif.text.trim(),
                            "gelAlFiyat": gelAl.text.trim(),
                            "goturFiyat": gotur.text.trim(),
                            "teslimat": teslim,
                            "images": imgs,
                            "img": imgs.isNotEmpty ? imgs.first : '',
                          };
                        });

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('🗑 Son foto silindi')),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.redAccent),
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: const Text(
                        'SON FOTOYU SİL',
                        style: TextStyle(
                          color: Colors.redAccent,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final adText = ad.text.trim();
                    final tarifText = tarif.text.trim();
                    final gelAlText = gelAl.text.trim();
                    final goturText = gotur.text.trim();

                    // 🔥 1. ZORUNLU ALAN KONTROLÜ
                    if (adText.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('❌ Ürün adı boş olamaz')),
                      );
                      return;
                    }

                    if (gelAlText.isEmpty && goturText.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('❌ En az bir fiyat girilmeli')),
                      );
                      return;
                    }

                    try {
                      final current = _onSekizUrun[i];
                      final docId = current['id']?.toString() ?? '';

                      final data = {
                        "ad": adText,
                        "tarif": tarifText,
                        "gelAlFiyat": gelAlText,
                        "goturFiyat": goturText,
                        "teslimat": teslim,
                        "images": current['images'] ?? [],
                        "img": current['img'] ?? '',
                        "kategori": seciliEvAltKategori,
                        "dukkanAdi": dukkanAdi,
                        "sellerId": sellerId,
                        "updatedAt": FieldValue.serverTimestamp(),
                      };

                      String newDocId = docId;

                      // 🔥 2. CREATE veya UPDATE
                      if (docId.isEmpty) {
                        final ref = await FirebaseFirestore.instance
                            .collection('urunler')
                            .add({
                          ...data,
                          "createdAt": FieldValue.serverTimestamp(),
                        });

                        newDocId = ref.id;
                      } else {
                        await FirebaseFirestore.instance
                            .collection('urunler')
                            .doc(docId)
                            .update(data);
                      }

                      // 🔥 3. LOCAL STATE GÜNCELLE
                      if (!mounted) return;

                      setState(() {
                        _onSekizUrun[i] = {
                          ...current,
                          "id": newDocId,
                          "ad": adText,
                          "tarif": tarifText,
                          "gelAlFiyat": gelAlText,
                          "goturFiyat": goturText,
                          "teslimat": teslim,
                        };
                      });

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('✅ Ürün başarıyla kaydedildi')),
                      );

                      Navigator.pop(c);
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('❌ Kayıt hatası: $e')),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 48),
                  ),
                  child: const Text(
                    'ÜRÜNÜ KAYDET',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Builder(
                builder: (_) {
                  final imgs =
                      List<String>.from(_onSekizUrun[i]['images'] ?? []);
                  return Text(
                    'Galeri foto sayısı: ${imgs.length}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  );
                },
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _inputWidget(TextEditingController c, String h, IconData ikon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: c,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          prefixIcon: Icon(ikon, color: _gold, size: 18),
          hintText: h,
          hintStyle: const TextStyle(color: Colors.white24),
          filled: true,
          fillColor: Colors.white10,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  void _odemePenceresiGoster(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF111111),
      builder: (c) => Container(
        padding: const EdgeInsets.all(30),
        child: const Text(
          'ÖDEME SİSTEMİ AKTİF',
          style: TextStyle(color: _gold),
        ),
      ),
    );
  }

  void _adresGirisPenceresi(BuildContext context) {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: const Color(0xFF111111),
        title: const Text('ADRES', style: TextStyle(color: Colors.white)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text('KAYDET'),
          ),
        ],
      ),
    );
  }

  Future<void> _vitriniMuhurleFirestore() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ürün göndermek için giriş yapmalısın.'),
        ),
      );
      return;
    }

    final urunler = _onSekizUrun
        .where((u) => (u['ad'] ?? '').toString().trim().isNotEmpty)
        .toList();

    if (urunler.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gönderilecek ürün yok. En az 1 ürün ekleyin.'),
        ),
      );
      return;
    }

    setState(() => _gonderiliyor = true);

    try {
      final fs = FirebaseFirestore.instance;
      final batch = fs.batch();
      final kategori = _kategoriMetni();

      for (final u in urunler) {
        final fiyatNum = _parseFiyat((u['gelAlFiyat'] ?? '').toString()) ?? 0;
        final List<String> images = List<String>.from(u['images'] ?? []);

        final String img = images.isNotEmpty ? images.first : _placeholderImg;

        final doc = fs.collection('urunler').doc();

        batch.set(doc, {
          'ad': (u['ad'] ?? '').toString().trim(),
          'tarif': (u['tarif'] ?? '').toString().trim(),
          'dukkan': dukkanAdi,
          'dukkanAdi': dukkanAdi,
          'urunId': doc.id,
          'dukkanId': sellerId.isNotEmpty ? sellerId : user.uid,
          'saticiId': sellerId.isNotEmpty ? sellerId : user.uid,
          'sellerId': sellerId.isNotEmpty ? sellerId : user.uid,
          'ownerId': sellerId.isNotEmpty ? sellerId : user.uid,
          'sellerName': dukkanAdi,
          'fiyat': fiyatNum,
          'gelAlFiyat': (u['gelAlFiyat'] ?? '').toString().trim(),
          'goturFiyat': (u['goturFiyat'] ?? '').toString().trim(),
          'teslimat': u['teslimat'] == true,
          'img': img,
          'images': images,
          'tip': 'Ev Lezzetleri',
          'kategori': kategori,
          'onayDurumu': 'onaylandi',
          'isActive': true,
          'aktifMi': true,
          'kayitTarihi': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ VİTRİN ARENA'DA CANLI!")),
      );
    } catch (e, st) {
      debugPrint("❌ Firestore hatası: $e");
      debugPrintStack(stackTrace: st);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Firestore hatası: $e")),
      );
    } finally {
      if (mounted) setState(() => _gonderiliyor = false);
    }
  }

  String _kategoriMetni() {
    return seciliEvAltKategori;
  }

  num? _parseFiyat(String s) {
    final t = s.trim().replaceAll(',', '.');
    if (t.isEmpty) return null;
    return num.tryParse(t);
  }
}
