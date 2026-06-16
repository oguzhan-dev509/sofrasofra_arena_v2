import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:sofrasofra_arena_v2/cart/sepet_sayfasi.dart';
import 'package:sofrasofra_arena_v2/modules/kurye_basvuru_formu.dart';
import '../../orders/musteri_siparis_takip_sayfasi.dart';
import 'package:sofrasofra_arena_v2/modules/urun_detay.dart';

import 'package:sofrasofra_arena_v2/modules/widgets/ev_lezzetleri_cards.dart';
import 'package:sofrasofra_arena_v2/services/sepet_service.dart';

import 'package:sofrasofra_arena_v2/modules/widgets/sepet_badge.dart';
import 'package:sofrasofra_arena_v2/onboarding/uretici_basvuru_secim_sayfasi.dart';
import 'package:sofrasofra_arena_v2/modules/widgets/mahalle_mutfaklari_single_vitrin_section.dart';

class EvLezzetleriVitrini extends StatefulWidget {
  final String city;
  final String district;

  const EvLezzetleriVitrini({
    super.key,
    required this.city,
    required this.district,
  });

  @override
  State<EvLezzetleriVitrini> createState() => _EvLezzetleriVitriniState();
}

class _EvLezzetleriVitriniState extends State<EvLezzetleriVitrini> {
  static const Color _bg = Color(0xFF111111);
  static const Color _gold = Color(0xFFFFB300);

  String _selectedCategory = 'Tümü';

  final List<String> _categories = const [
    'Tümü',
    'Ev Yemekleri',
    'Çikolata & Tatlılar',
    'Süt Ürünleri',
    'Turşu & Diğerleri',
    'Baharat & Soslar',
    'Erişte & Mantı',
    'Tarhana',
    'Ev Yapımı Kuru Gıda',
    'Reçel & Marmelat',
    'Turşu',
    'Kuru Bakliyat Hazırlıkları',
    'Hamur Ürünleri / Dondurulmuş Mantı',
  ];

  Query<Map<String, dynamic>> _query() {
    return FirebaseFirestore.instance
        .collection('urunler')
        .where('tip', isEqualTo: 'Ev Lezzetleri');
  }

  String _normalizeText(dynamic value) {
    return (value ?? '')
        .toString()
        .trim()
        .toLowerCase()
        .replaceAll('ı', 'i')
        .replaceAll('i̇', 'i')
        .replaceAll('ğ', 'g')
        .replaceAll('ü', 'u')
        .replaceAll('ş', 's')
        .replaceAll('ö', 'o')
        .replaceAll('ç', 'c')
        .replaceAll('â', 'a')
        .replaceAll('î', 'i')
        .replaceAll('û', 'u')
        .replaceAll(RegExp(r'\s+'), ' ');
  }

  bool _matchesLocation(Map<String, dynamic> data) {
    final selectedCity = _normalizeText(widget.city);
    final selectedDistrict = _normalizeText(widget.district);

    final dataCity = _normalizeText(
      data['sehir'] ??
          data['şehir'] ??
          data['city'] ??
          data['il'] ??
          data['province'] ??
          data['adresIl'] ??
          data['locationCity'],
    );

    final dataDistrict = _normalizeText(
      data['ilce'] ??
          data['ilçe'] ??
          data['district'] ??
          data['bolge'] ??
          data['adresIlce'] ??
          data['locationDistrict'],
    );

    if (selectedCity.isEmpty) return true;

    final cityMatches = dataCity.isEmpty ||
        dataCity == selectedCity ||
        dataCity.contains(selectedCity) ||
        selectedCity.contains(dataCity);

    if (!cityMatches) return false;

    if (selectedDistrict.isEmpty || selectedDistrict == 'tumu') {
      return true;
    }

    final districtMatches = dataDistrict.isEmpty ||
        dataDistrict == selectedDistrict ||
        dataDistrict.contains(selectedDistrict) ||
        selectedDistrict.contains(dataDistrict);

    return districtMatches;
  }

  bool _isValidProduct(Map<String, dynamic> data) {
    final String ad = (data['ad'] ?? data['urunAdi'] ?? data['yemekAdi'] ?? '')
        .toString()
        .trim();

    final String dukkan =
        (data['dukkan'] ?? data['dukkanAdi'] ?? data['satici'] ?? '')
            .toString()
            .trim();

    return ad.isNotEmpty && dukkan.isNotEmpty;
  }

  double _readPrice(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    if (value is String) {
      return double.tryParse(value.replaceAll(',', '.').trim()) ?? 0;
    }
    return 0;
  }

  String _safeText(dynamic value) {
    return (value ?? '').toString().trim();
  }

  Timestamp? _asTimestamp(dynamic value) {
    if (value is Timestamp) return value;
    return null;
  }

  double _readScore(Map<String, dynamic> data) {
    final rawScore = data['score'];
    if (rawScore is num) return rawScore.toDouble();

    final puan = data['puan'];
    final yorumSayisi = data['yorumSayisi'];
    final bugunPisiyor = data['bugunPisiyor'] == true;

    double score = 0;

    if (puan is num) {
      score += puan.toDouble() * 20;
    }

    if (yorumSayisi is num) {
      score += yorumSayisi.toDouble().clamp(0, 200);
    }

    if (bugunPisiyor) {
      score += 25;
    }

    return score;
  }

  String _mapCategory(Map<String, dynamic> data) {
    final raw = _normalizeText(
      [
        data['kategori'],
        data['altKategori'],
        data['category'],
        data['categoryLabel'],
        data['productCategory'],
        data['urunKategori'],
        data['ad'],
        data['urunAdi'],
        data['yemekAdi'],
        data['baslik'],
        data['title'],
        data['aciklama'],
        data['description'],
      ].where((value) => _safeText(value).isNotEmpty).join(' '),
    );
    if (raw.contains('eriste') ||
        raw.contains('erişte') ||
        raw.contains('manti') ||
        raw.contains('mantı')) {
      return 'Erişte & Mantı';
    }

    if (raw.contains('tarhana')) {
      return 'Tarhana';
    }

    if (raw.contains('kuru gida') ||
        raw.contains('kuru gıda') ||
        raw.contains('kurutulmus') ||
        raw.contains('kurutulmuş')) {
      return 'Ev Yapımı Kuru Gıda';
    }

    if (raw.contains('recel') || raw.contains('reçel')) {
      return 'Reçel & Marmelat';
    }

    if (raw.contains('tursu') || raw.contains('turşu')) {
      return 'Turşu';
    }

    if (raw.contains('bakliyat') ||
        raw.contains('nohut') ||
        raw.contains('fasulye') ||
        raw.contains('mercimek')) {
      return 'Kuru Bakliyat Hazırlıkları';
    }

    if (raw.contains('dondurulmus manti') ||
        raw.contains('dondurulmuş mantı') ||
        raw.contains('hamur urunleri') ||
        raw.contains('hamur ürünleri') ||
        raw.contains('borek') ||
        raw.contains('börek') ||
        raw.contains('pogaca') ||
        raw.contains('poğaça')) {
      return 'Hamur Ürünleri / Dondurulmuş Mantı';
    }
    if (raw.contains('cikolata') ||
        raw.contains('tatli') ||
        raw.contains('pasta') ||
        raw.contains('kurabiye') ||
        raw.contains('baklava') ||
        raw.contains('sutlac') ||
        raw.contains('kek')) {
      return 'Çikolata & Tatlılar';
    }

    if (raw.contains('sut') ||
        raw.contains('peynir') ||
        raw.contains('yogurt') ||
        raw.contains('tereyag') ||
        raw.contains('kaymak')) {
      return 'Süt Ürünleri';
    }

    if (raw.contains('tursu') ||
        raw.contains('recel') ||
        raw.contains('salca') ||
        raw.contains('konserve') ||
        raw.contains('zeytin')) {
      return 'Turşu & Diğerleri';
    }

    if (raw.contains('baharat') ||
        raw.contains('sos') ||
        raw.contains('biber') ||
        raw.contains('pul biber') ||
        raw.contains('kekik')) {
      return 'Baharat & Soslar';
    }

    return 'Ev Yemekleri';
  }

  bool _isEvGalleryCatalogDoc(Map<String, dynamic> data) {
    final source = (data['source'] ?? '').toString().trim();
    final orderSource = (data['orderSource'] ?? '').toString().trim();
    final isGalleryProduct = data['isGalleryProduct'] == true;
    final hiddenFromCatalog = data['hiddenFromCatalog'] == true;
    final ad = (data['ad'] ?? data['urunAdi'] ?? '').toString().trim();

    return source == 'ev_gallery' ||
        orderSource == 'ev_gallery' ||
        isGalleryProduct ||
        hiddenFromCatalog ||
        ad == 'Ev Galeri Ürünü';
  }

  bool _matchesSelectedCategory(Map<String, dynamic> data) {
    if (_selectedCategory == 'Tümü') return true;
    return _mapCategory(data) == _selectedCategory;
  }

  bool _isBugunPisiyor(Map<String, dynamic> data) {
    return data['bugunPisiyor'] == true;
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _sortByScore(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final items = [...docs];
    items.sort((a, b) {
      final bScore = _readScore(b.data());
      final aScore = _readScore(a.data());
      return bScore.compareTo(aScore);
    });
    return items;
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _sortByCreatedAt(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final items = [...docs];
    items.sort((a, b) {
      final bTs = _asTimestamp(b.data()['createdAt']);
      final aTs = _asTimestamp(a.data()['createdAt']);

      if (aTs == null && bTs == null) return 0;
      if (aTs == null) return 1;
      if (bTs == null) return -1;

      return bTs.toDate().compareTo(aTs.toDate());
    });
    return items;
  }

  String _dominantDistrict(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final Map<String, int> counts = {};

    for (final doc in docs) {
      final ilce = _safeText(doc.data()['ilce']).toUpperCase();
      if (ilce.isEmpty) continue;
      counts[ilce] = (counts[ilce] ?? 0) + 1;
    }

    if (counts.isEmpty) return '';

    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted.first.key;
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _mahalleDocs(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final dominant = _dominantDistrict(docs);
    if (dominant.isEmpty) {
      return _sortByScore(docs).take(10).toList();
    }

    final dominantNorm = _normalizeText(dominant);

    final local = docs.where((doc) {
      final data = doc.data();

      final ilce = _normalizeText(
        data['ilce'] ??
            data['ilçe'] ??
            data['district'] ??
            data['bolge'] ??
            data['adresIlce'] ??
            data['locationDistrict'],
      );

      return ilce.isNotEmpty &&
          (ilce == dominantNorm ||
              ilce.contains(dominantNorm) ||
              dominantNorm.contains(ilce));
    }).toList();

    if (local.isEmpty) {
      return _sortByScore(docs).take(10).toList();
    }

    return _sortByScore(local).take(10).toList();
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _bugunDocs(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final bugun = docs.where((doc) => _isBugunPisiyor(doc.data())).toList();
    if (bugun.isEmpty) {
      return _sortByCreatedAt(docs).take(10).toList();
    }
    return _sortByScore(bugun).take(10).toList();
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _trendDocs(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    return _sortByScore(docs).take(10).toList();
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _yeniDocs(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    return _sortByCreatedAt(docs).take(10).toList();
  }

  void _openDetail(
    BuildContext context,
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();

    final String ad = _safeText(
      data['ad'] ?? data['urunAdi'] ?? data['yemekAdi'],
    );

    final String dukkan = _safeText(
      data['dukkan'] ?? data['dukkanAdi'] ?? data['satici'],
    );

    final String sehir = _safeText(data['sehir']);
    final String ilce = _safeText(data['ilce']);

    final String aciklama = _safeText(data['aciklama'] ?? data['tarif']);

    final dynamic fiyatRaw = data['fiyat'] ?? data['gelAlFiyat'];
    final double fiyat = _readPrice(fiyatRaw);
    final String fiyatText = fiyat <= 0 ? '' : '${fiyat.toStringAsFixed(0)} ₺';

    final List<String> urunGorseller = ((data['images'] as List?) ?? [])
        .map((e) => e.toString().trim())
        .where((e) => e.isNotEmpty)
        .toList();
    debugPrint('DEBUG ${ad} → images: ${urunGorseller.length}');
    print('DEBUG images length: ${urunGorseller.length}');
    final String img = urunGorseller.isNotEmpty
        ? urunGorseller.first
        : (data['img'] ?? data['imgUrl'] ?? data['resim'] ?? '')
            .toString()
            .trim();

    final String konum = [
      if (ilce.isNotEmpty) ilce,
      if (sehir.isNotEmpty) sehir,
    ].join(' / ');
    // debugPrint('=== TAP PRODUCT START ===');
    //debugPrint('TAP DOC ID: ${doc.id}');
    // debugPrint('TAP AD: $ad');
    // debugPrint('TAP IMG: $img');
    // debugPrint('TAP IMAGES COUNT: ${urunGorseller.length}');
    debugPrint('TAP IMAGES: $urunGorseller');
    debugPrint('=== TAP PRODUCT END ===');
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UrunDetaySayfasi(
          urunAdi: ad,
          urunFiyat: fiyatText,
          urunGorsel: img,
          urunGorseller: urunGorseller,
          aciklama: aciklama,
          dukkanAdi: dukkan,
          konum: konum,
          youtubeUrl: (data['youtubeUrl'] ?? data['videoUrl'] ?? '').toString(),
          productId: doc.id,
          sellerId: (data['dukkanId'] ??
                  data['sellerId'] ??
                  data['ownerId'] ??
                  data['uid'] ??
                  '')
              .toString(),
          kategori: 'Ev Lezzetleri',
          gelAlFiyat:
              data['gelAlFiyat'] is num ? data['gelAlFiyat'] as num : null,
          goturFiyat:
              data['goturFiyat'] is num ? data['goturFiyat'] as num : null,
          isAdmin: false,
        ),
      ),
    );
  }

  Future<void> _addToCart(
    BuildContext context,
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) async {
    final data = doc.data();

    final String ad = _safeText(
      data['ad'] ?? data['urunAdi'] ?? data['yemekAdi'],
    );

    final String dukkan = _safeText(
      data['dukkan'] ?? data['dukkanAdi'] ?? data['satici'],
    );

    final List<dynamic> rawImages = (data['images'] as List?) ?? [];
    final List<String> detailImages = rawImages
        .map((e) => e.toString().trim())
        .where((e) => e.isNotEmpty)
        .toList();

    final String img = detailImages.isNotEmpty
        ? detailImages.first
        : _safeText(
            data['img'] ?? data['imgUrl'] ?? data['resim'],
          );

    final String category = _mapCategory(data);

    final dynamic fiyatRaw = data['fiyat'] ?? data['gelAlFiyat'];
    final double fiyat = _readPrice(fiyatRaw);

    await SepetService.sepeteEkle(
      urunId: doc.id,
      urunAdi: ad,
      dukkanAdi: dukkan,
      kategori: category,
      img: img,
      fiyat: fiyat,
    );

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$ad sepete eklendi.'),
        backgroundColor: _gold,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _showOrderActionSheet(
    BuildContext context,
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) async {
    final data = doc.data();

    final String ad = _safeText(
      data['ad'] ?? data['urunAdi'] ?? data['yemekAdi'],
    );

    final dynamic fiyatRaw = data['fiyat'] ?? data['gelAlFiyat'];
    final double fiyat = _readPrice(fiyatRaw);
    final String fiyatText =
        fiyat <= 0 ? 'Fiyat belirtilmemiş' : '${fiyat.toStringAsFixed(0)} ₺';

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ad,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  fiyatText,
                  style: const TextStyle(
                    color: _gold,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      Navigator.pop(sheetContext);
                      await _addToCart(context, doc);
                    },
                    icon: const Icon(Icons.shopping_cart_outlined),
                    label: const Text('Sepete Ekle'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _gold,
                      foregroundColor: Colors.black,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ).copyWith(
                      overlayColor: MaterialStateProperty.all(
                        Colors.black.withOpacity(0.1),
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
  }

  Future<void> _createDirectOrder(
    BuildContext context,
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Önce kullanıcı oturumu hazırlanmalı.'),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }

      await _addToCart(context, doc);

      final data = doc.data();

      final String sehir = _safeText(data['sehir']).isEmpty
          ? 'istanbul'
          : _safeText(data['sehir']).toLowerCase().trim();

      final String ilce = _safeText(data['ilce']).isEmpty
          ? 'kadikoy'
          : _safeText(data['ilce']).toLowerCase().trim();

      final String orderId = await SepetService.siparisiTamamla(
        musteriAd: 'Demo Müşteri',
        musteriTelefon: '0555 000 00 00',
        teslimatAdresi: '${ilce.toUpperCase()} / ${sehir.toUpperCase()}',
        sehir: sehir,
        ilce: ilce,
        paymentMethod: 'cash',
      );

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sipariş oluşturuldu. No: $orderId'),
          backgroundColor: _gold,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sipariş oluşturulamadı: $e'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Widget _buildHorizontalSection({
    required BuildContext context,
    required String title,
    required String subtitle,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  }) {
    if (docs.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(title: title, subtitle: subtitle),
        const SizedBox(height: 14),
        SizedBox(
          height: 305,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data();

              final String ad = _safeText(
                data['ad'] ?? data['urunAdi'] ?? data['yemekAdi'],
              );

              final String dukkan = _safeText(
                data['dukkan'] ?? data['dukkanAdi'] ?? data['satici'],
              );

              final String sehir = _safeText(data['sehir']);
              final String ilce = _safeText(data['ilce']);

              final String aciklama = _safeText(
                data['aciklama'] ?? data['tarif'],
              );

              final dynamic rawImages = data['images'] ??
                  data['urunGorseller'] ??
                  data['galeri'] ??
                  data['fotoGalerisi'];

              final List<String> urunGorseller = rawImages is Iterable
                  ? rawImages
                      .map((e) => e.toString().trim())
                      .where((e) => e.isNotEmpty)
                      .toList()
                  : <String>[];

              final String img = urunGorseller.isNotEmpty
                  ? urunGorseller.first
                  : _safeText(
                      data['img'] ??
                          data['imgUrl'] ??
                          data['resim'] ??
                          data['image'],
                    );

              // debugPrint('### DOC ID: ${doc.id}');
              // debugPrint('### RAW IMAGES TYPE: ${rawImages.runtimeType}');
              // debugPrint('### RAW IMAGES: $rawImages');
              // debugPrint('### CARD GALERI LENGTH: ${urunGorseller.length}');
              //  debugPrint('### CARD IMG: $img');
              final dynamic fiyatRaw = data['fiyat'] ?? data['gelAlFiyat'];
              final double fiyat = _readPrice(fiyatRaw);
              final String fiyatText = fiyat <= 0
                  ? 'Fiyat yakında'
                  : '${fiyat.toStringAsFixed(0)} ₺';

              final String konum = [
                if (ilce.isNotEmpty) ilce,
                if (sehir.isNotEmpty) sehir,
              ].join(' / ');

              return EvHorizontalFoodCard(
                title: ad,
                kitchen: dukkan,
                subtitle: aciklama.isNotEmpty
                    ? aciklama
                    : 'Ev yapımı günlük hazırlanmış sıcak mahalle lezzeti.',
                locationText: konum,
                priceText: fiyatText,
                imageUrl: img,
                badgeType: _safeText(data['sellerBadgeType']).isEmpty
                    ? 'none'
                    : _safeText(data['sellerBadgeType']),
                onTap: () => _openDetail(context, doc),
                onAddToCart: () => _showOrderActionSheet(context, doc),
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: const Text(
          'EV LEZZETLERİ',
          style: TextStyle(
            color: _gold,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.3,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: _gold),
        actions: [
          IconButton(
            icon: const SepetBadge(),
            tooltip: 'Sepetim',
            color: _gold,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const SepetSayfasi(),
                ),
              );
            },
          ),
          IconButton(
            icon:
                const Icon(Icons.storefront_rounded, color: Color(0xFFFFB300)),
            tooltip: 'Yönetim Merkezi',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const UreticiBasvuruSecimSayfasi(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.receipt_long_outlined),
            tooltip: 'Sipariş Takibi',
            color: _gold,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const MusteriSiparisTakipSayfasi(),
                ),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _query().snapshots(),
        builder: (context, snap) {
          if (snap.hasError) {
            return _CenterInfo(
              icon: Icons.error_outline,
              title: 'Hata',
              message: snap.error.toString(),
            );
          }
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: _gold),
            );
          }

          final allDocs = snap.data?.docs ?? [];

          final validDocs = allDocs.where((doc) {
            final data = doc.data();

            if (_isEvGalleryCatalogDoc(data)) {
              return false;
            }

            return _isValidProduct(data) && _matchesLocation(data);
          }).toList();

          final categoryDocs = validDocs
              .where((doc) => _matchesSelectedCategory(doc.data()))
              .toList();

          final sellerDocs = _uniqueSellerDocs(categoryDocs);
          final sellerValidDocs = _uniqueSellerDocs(validDocs);
          if (validDocs.isEmpty) {
            return _CenterInfo(
              icon: Icons.storefront_outlined,
              title: 'Bu bölgede ürün bulunamadı',
              message:
                  '${widget.district == 'Tümü' ? widget.city : '${widget.district} / ${widget.city}'} için onaylı ve görselli ev lezzeti ürünü görünmüyor.',
            );
          }

          final featuredKitchens = _extractFeaturedKitchens(sellerValidDocs);
          final mahalleDocs = _mahalleDocs(sellerDocs);
          final bugunDocs = _bugunDocs(sellerDocs);
          final trendDocs = _trendDocs(sellerDocs);
          final yeniDocs = _yeniDocs(sellerDocs);
          final dominantDistrict = _dominantDistrict(sellerValidDocs);
          final isCategoryFiltered = _selectedCategory != 'Tümü';
          return LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final isMobile = width < 760;

              int crossAxisCount = 1;
              if (width >= 760 && width < 1180) {
                crossAxisCount = 2;
              } else if (width >= 1180) {
                crossAxisCount = 3;
              }

              return CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _HeroSection(
                            isMobile: isMobile,
                            city: widget.city,
                            district: widget.district,
                          ),
                          const SizedBox(height: 18),
                          _KuryeOlBanner(isMobile: isMobile),
                          const SizedBox(height: 18),
                          _SectionTitle(
                            title: 'Kategoriler',
                            subtitle:
                                'Ev yapımı günlük lezzetleri, güven veren üreticilerden keşfet.',
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFF12100A),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: const Color(0xFFFFB300)
                                    .withValues(alpha: 0.34),
                              ),
                            ),
                            child: const Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.verified_user_outlined,
                                  color: Color(0xFFFFB300),
                                  size: 22,
                                ),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Esnaf Vergi Muafiyeti Belgesi ile Satılabilecek Ürünler',
                                        style: TextStyle(
                                          color: Color(0xFFFFB300),
                                          fontWeight: FontWeight.w800,
                                          fontSize: 14,
                                        ),
                                      ),
                                      SizedBox(height: 7),
                                      Text(
                                        'Tarhana, erişte, mantı gibi bazı ev yapımı ürünler için esnaf vergi muafiyeti belgesi alınabilir. Uygunluk belge ve mevzuat kontrolüne tabidir.',
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 12.5,
                                          height: 1.4,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          _CategoryBar(
                            categories: _categories,
                            selected: _selectedCategory,
                            onSelected: (value) {
                              setState(() {
                                _selectedCategory = value;
                              });
                            },
                          ),
                          const SizedBox(height: 22),
                          _AgentIdeaCard(isMobile: isMobile),
                          const SizedBox(height: 22),
                          MahalleMutfaklariSingleVitrinSection(
                            docs: categoryDocs,
                            selectedCategory: _selectedCategory,
                            isMobile: isMobile,
                            crossAxisCount: crossAxisCount,
                            onOpenDetail: (doc) => _openDetail(context, doc),
                            onAddToCart: (doc) =>
                                _showOrderActionSheet(context, doc),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _uniqueSellerDocs(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final Map<String, QueryDocumentSnapshot<Map<String, dynamic>>> unique = {};

    for (final doc in docs) {
      final data = doc.data();

      final source = (data['source'] ?? '').toString().trim();
      final orderSource = (data['orderSource'] ?? '').toString().trim();
      final isGalleryProduct = data['isGalleryProduct'] == true;
      final hiddenFromCatalog = data['hiddenFromCatalog'] == true;

      if (source == 'ev_gallery' ||
          orderSource == 'ev_gallery' ||
          isGalleryProduct ||
          hiddenFromCatalog) {
        continue;
      }

      final kitchenName = _normalizeText(
        data['dukkan'] ??
            data['dukkanAdi'] ??
            data['mutfakAdi'] ??
            data['satici'] ??
            '',
      );

      final district = _normalizeText(
        data['ilce'] ?? data['ilçe'] ?? '',
      );

      final city = _normalizeText(
        data['sehir'] ?? data['şehir'] ?? '',
      );

      final ownerKey = _normalizeText(
        data['sellerId'] ??
            data['saticiId'] ??
            data['dukkanId'] ??
            data['ownerId'] ??
            data['userId'] ??
            '',
      );

      final sellerKey = kitchenName.isNotEmpty
          ? '$kitchenName|$district|$city'
          : ownerKey.isNotEmpty
              ? ownerKey
              : doc.id;

      if (sellerKey.trim().isEmpty) continue;

      unique.putIfAbsent(sellerKey, () => doc);
    }

    return unique.values.toList();
  }

  List<_KitchenPreview> _extractFeaturedKitchens(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final Map<String, _KitchenPreview> kitchens = {};

    for (final doc in docs) {
      final data = doc.data();

      final kitchenName = _safeText(
        data['dukkan'] ?? data['dukkanAdi'] ?? data['satici'],
      );
      if (kitchenName.isEmpty) continue;

      kitchens.putIfAbsent(
        kitchenName,
        () => _KitchenPreview(
          name: kitchenName,
          district: [
            if (_safeText(data['ilce']).isNotEmpty) _safeText(data['ilce']),
            if (_safeText(data['sehir']).isNotEmpty) _safeText(data['sehir']),
          ].join(' / '),
          category: _mapCategory(data),
          imageUrl: _safeText(
            data['producerImg'] ??
                data['ownerImg'] ??
                data['profilFoto'] ??
                data['img'] ??
                data['imgUrl'] ??
                data['resim'],
          ),
          badgeType: _safeText(data['sellerBadgeType']).isEmpty
              ? 'none'
              : _safeText(data['sellerBadgeType']),
        ),
      );
    }

    final list = kitchens.values.toList();
    if (list.isEmpty) return [];

    return list.take(8).toList();
  }
}

class _HeroSection extends StatelessWidget {
  final bool isMobile;
  final String city;
  final String district;

  const _HeroSection({
    required this.isMobile,
    required this.city,
    required this.district,
  });

  static const Color _gold = Color(0xFFFFB300);
  static const Color _panel = Color(0xFF1A1A1A);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 18 : 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF1A1A1A),
            Color(0xFF222222),
            Color(0xFF151515),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: _gold.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _HeroTextBlock(
                  city: city,
                  district: district,
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: const [
                    _HeroTag(text: 'Günlük Hazırlanır'),
                    _HeroTag(text: 'Ev Yapımı'),
                    _HeroTag(text: 'Mahalleden Teslim'),
                    _HeroTag(text: 'Sıcak Lezzetler'),
                  ],
                ),
              ],
            )
          : Row(
              children: [
                Expanded(
                  flex: 6,
                  child: _HeroTextBlock(
                    city: city,
                    district: district,
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  flex: 5,
                  child: Container(
                    height: 270,
                    decoration: BoxDecoration(
                      color: _panel,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white10),
                    ),
                    padding: const EdgeInsets.all(18),
                    child: const Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _HeroTag(text: 'Günlük Hazırlanır'),
                        _HeroTag(text: 'Ev Yapımı'),
                        _HeroTag(text: 'Mahalleden Teslim'),
                        _HeroTag(text: 'Katkısız Seçenekler'),
                        _HeroTag(text: 'Tatlı & Kahvaltılık'),
                        _HeroTag(text: 'Sıcak Tencere Yemekleri'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _HeroTextBlock extends StatelessWidget {
  final String city;
  final String district;

  const _HeroTextBlock({
    required this.city,
    required this.district,
  });

  static const Color _gold = Color(0xFFFFB300);
  static const Color _softGold = Color(0xFFFFE0A3);

  @override
  Widget build(BuildContext context) {
    final hasCity = city.trim().isNotEmpty;
    final hasDistrict =
        district.trim().isNotEmpty && district.trim().toLowerCase() != 'tümü';

    final areaText = hasCity
        ? (hasDistrict ? '$district / $city bölgesinde' : '$city bölgesinde')
        : 'bulunduğun bölgede';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ev Lezzetleri',
          style: TextStyle(
            color: _gold,
            fontSize: 30,
            fontWeight: FontWeight.w900,
            height: 1.05,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          '$areaText ev yapımı günlük lezzetleri, güven veren üreticilerden keşfet.',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            height: 1.55,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          hasCity
              ? 'Gerçek üreticiler • ev yapımı lezzetler • $areaText premium vitrin'
              : 'Gerçek üreticiler • ev yapımı lezzetler • premium vitrin',
          style: const TextStyle(
            color: _softGold,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _HeroTag extends StatelessWidget {
  final String text;

  const _HeroTag({required this.text});

  static const Color _gold = Color(0xFFFFB300);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
      decoration: BoxDecoration(
        color: _gold.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _gold.withValues(alpha: 0.4)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: _gold,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _CategoryBar extends StatelessWidget {
  final List<String> categories;
  final String selected;
  final ValueChanged<String> onSelected;

  const _CategoryBar({
    required this.categories,
    required this.selected,
    required this.onSelected,
  });

  static const Color _gold = Color(0xFFFFB300);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final item = categories[index];
          final isSelected = item == selected;

          return GestureDetector(
            onTap: () => onSelected(item),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
              decoration: BoxDecoration(
                color: isSelected ? _gold : const Color(0xFF1F1F1F),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: isSelected ? _gold : Colors.white12,
                ),
              ),
              child: Center(
                child: Text(
                  item,
                  style: TextStyle(
                    color: isSelected ? Colors.black : Colors.white70,
                    fontWeight: FontWeight.w700,
                    fontSize: 12.5,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionTitle({
    required this.title,
    required this.subtitle,
  });

  static const Color _gold = Color(0xFFFFB300);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: _gold,
            fontWeight: FontWeight.w800,
            fontSize: 22,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 13,
            height: 1.45,
          ),
        ),
      ],
    );
  }
}

class _AgentIdeaCard extends StatelessWidget {
  final bool isMobile;

  const _AgentIdeaCard({required this.isMobile});

  static const Color _gold = Color(0xFFFFB300);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 18),
      decoration: BoxDecoration(
        color: const Color(0xFF181818),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _gold.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.auto_awesome, color: _gold),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bugün ne yemeliyim?',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Bu alan ileride müşteri ajanı için hazırlandı. Bütçene, konumuna ve damak zevkine göre ev lezzeti önerecek.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12.5,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CenterInfo extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _CenterInfo({
    required this.icon,
    required this.title,
    required this.message,
  });

  static const Color _gold = Color(0xFFFFB300);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 44, color: _gold),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13.5,
                color: Colors.white70,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _KitchenPreview {
  final String name;
  final String district;
  final String category;
  final String imageUrl;
  final String badgeType;

  const _KitchenPreview({
    required this.name,
    required this.district,
    required this.category,
    required this.imageUrl,
    required this.badgeType,
  });
}

class _KuryeOlBanner extends StatelessWidget {
  final bool isMobile;

  const _KuryeOlBanner({required this.isMobile});

  static const Color _gold = Color(0xFFFFB300);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      decoration: BoxDecoration(
        color: const Color(0xFF090909),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFFFB300),
          width: 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22FFB300),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _bannerTop(),
                const SizedBox(height: 14),
                _bannerButton(context, fullWidth: true),
              ],
            )
          : Row(
              children: [
                Expanded(child: _bannerTop()),
                const SizedBox(width: 16),
                _bannerButton(context),
              ],
            ),
    );
  }

  Widget _bannerTop() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(
            color: const Color(0xFF151515),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.delivery_dining_rounded,
            color: Color(0xFFFFB300),
            size: 30,
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  Text(
                    'Kurye Ol',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  _KuryeRozet(),
                ],
              ),
              SizedBox(height: 6),
              Text(
                'Teslimat ağına katıl, bulunduğun bölgede sipariş taşıyarak gelir elde et.',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  height: 1.35,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Esnek çalışma • Bölgesel teslimat • Hızlı başvuru',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _bannerButton(BuildContext context, {bool fullWidth = false}) {
    return SizedBox(
      width: fullWidth ? double.infinity : null,
      height: 48,
      child: ElevatedButton.icon(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const KuryeBasvuruFormu(),
            ),
          );
        },
        icon: const Icon(Icons.flash_on, size: 18),
        label: const Text(
          'Hemen Başvur',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: _gold,
          foregroundColor: Colors.black,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}

class _KuryeRozet extends StatelessWidget {
  const _KuryeRozet();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Text(
        'Bugün Başvur',
        style: TextStyle(
          color: Color(0xFFFFB300),
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
