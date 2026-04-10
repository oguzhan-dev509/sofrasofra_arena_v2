import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:sofrasofra_arena_v2/modules/urun_detay.dart';
import 'package:sofrasofra_arena_v2/modules/widgets/ev_lezzetleri_cards.dart';
import 'package:sofrasofra_arena_v2/services/sepet_service.dart';
import 'package:sofrasofra_arena_v2/merchant/ev_orders_sayfasi.dart';
import '../../admin/admin_icerik_paneli.dart';
import '../../cart/sepet_sayfasi.dart';
import '../../merchant/satici_siparis_paneli.dart';
import '../../merchant/urun_ekleme_sayfasi.dart';
import '../../orders/musteri_siparis_takip_sayfasi.dart';
import 'package:sofrasofra_arena_v2/modules/vitrinler/ev_lezzetleri_helpers.dart';
import 'package:sofrasofra_arena_v2/modules/kurye_basvuru_formu.dart';

class EvLezzetleriVitrini extends StatefulWidget {
  const EvLezzetleriVitrini({super.key});

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
  ];

  Query<Map<String, dynamic>> _query() {
    return FirebaseFirestore.instance
        .collection('urunler')
        .where('tip', isEqualTo: 'Ev Lezzetleri')
        .where('onayDurumu', isEqualTo: 'onaylandi')
        .where('isActive', isEqualTo: true);
  }

  bool _isValidProduct(Map<String, dynamic> data) {
    final String ad = (data['ad'] ?? data['urunAdi'] ?? data['yemekAdi'] ?? '')
        .toString()
        .trim();

    final String dukkan =
        (data['dukkan'] ?? data['dukkanAdi'] ?? data['satici'] ?? '')
            .toString()
            .trim();

    final String img = (data['img'] ?? data['imgUrl'] ?? data['resim'] ?? '')
        .toString()
        .trim();

    return ad.isNotEmpty && dukkan.isNotEmpty && img.isNotEmpty;
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
    final raw = _safeText(
      data['kategori'] ?? data['altKategori'] ?? data['category'],
    ).toLowerCase();

    if (raw.contains('tatlı') ||
        raw.contains('cikolata') ||
        raw.contains('çikolata')) {
      return 'Çikolata & Tatlılar';
    }
    if (raw.contains('sut') ||
        raw.contains('süt') ||
        raw.contains('peynir') ||
        raw.contains('yoğurt') ||
        raw.contains('yogurt')) {
      return 'Süt Ürünleri';
    }
    if (raw.contains('turşu') ||
        raw.contains('tursu') ||
        raw.contains('reçel') ||
        raw.contains('recel') ||
        raw.contains('kahvalt')) {
      return 'Turşu & Diğerleri';
    }
    if (raw.contains('baharat') ||
        raw.contains('sos') ||
        raw.contains('salça') ||
        raw.contains('salca')) {
      return 'Baharat & Soslar';
    }
    return 'Ev Yemekleri';
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

    final local = docs.where((doc) {
      final ilce = _safeText(doc.data()['ilce']).toUpperCase();
      return ilce == dominant;
    }).toList();

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

    final String img = _safeText(
      data['img'] ?? data['imgUrl'] ?? data['resim'],
    );

    final String konum = [
      if (ilce.isNotEmpty) ilce,
      if (sehir.isNotEmpty) sehir,
    ].join(' / ');

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UrunDetaySayfasi(
          urunAdi: ad,
          urunFiyat: fiyatText,
          urunGorsel: img,
          aciklama: aciklama,
          dukkanAdi: dukkan,
          konum: konum,
          youtubeUrl: (data['youtubeUrl'] ?? data['videoUrl'] ?? '').toString(),
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

    final String img = _safeText(
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

              final String img = _safeText(
                data['img'] ?? data['imgUrl'] ?? data['resim'],
              );

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
                onAddToCart: () => _addToCart(context, doc),
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
          'MAHALLE MUTFAĞI',
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
            IconButton(
              icon: const Icon(Icons.receipt_long, color: _gold),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        const EvOrdersSayfasi(sellerId: 'demo_user'),
                  ),
                );
              },
            ),
            icon: const Icon(Icons.shopping_cart_outlined),
            tooltip: 'Sepetim',
            color: _gold,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SepetSayfasi()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.fact_check_outlined),
            tooltip: 'Ev Siparişleri',
            color: _gold,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const EvOrdersSayfasi(sellerId: 'demo_user'),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.admin_panel_settings_outlined),
            tooltip: 'Admin İçerik Paneli',
            color: _gold,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdminIcerikPaneli()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.add_box_outlined),
            tooltip: 'Ürün Ekle',
            color: _gold,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const UrunEklemeSayfasi()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.store),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) {
                    return SaticiSiparisPaneli(
                      sellerId: 'nuran_tatlilari',
                      sellerName: 'Nuran Tatlıları Sipariş Paneli',
                    );
                  },
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
            return const Center(child: CircularProgressIndicator(color: _gold));
          }

          final allDocs = snap.data?.docs ?? [];
          final validDocs = allDocs
              .where((doc) => _isValidProduct(doc.data()))
              .toList();

          final docs = validDocs
              .where((doc) => _matchesSelectedCategory(doc.data()))
              .toList();

          if (validDocs.isEmpty) {
            return const _CenterInfo(
              icon: Icons.storefront_outlined,
              title: 'Henüz ürün yok',
              message: 'Onaylı ve görselli ev lezzeti ürünü bulunamadı.',
            );
          }

          final featuredKitchens = _extractFeaturedKitchens(validDocs);
          final mahalleDocs = _mahalleDocs(docs);
          final bugunDocs = _bugunDocs(docs);
          final trendDocs = _trendDocs(docs);
          final yeniDocs = _yeniDocs(docs);
          final dominantDistrict = _dominantDistrict(validDocs);

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
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _HeroSection(isMobile: isMobile),
                          const SizedBox(height: 18),
                          _KuryeOlBanner(isMobile: isMobile),
                          const SizedBox(height: 18),
                          _SectionTitle(
                            title: 'Kategoriler',
                            subtitle:
                                'Ev yapımı lezzetleri ihtiyacına göre keşfet',
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const EvOrdersSayfasi(
                                      sellerId: 'demo_user',
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.fact_check_outlined),
                              label: const Text('Ev Siparişleri Test Ekranı'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _gold,
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
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
                          _SectionTitle(
                            title: 'Öne Çıkan Mutfaklar',
                            subtitle:
                                'Mahalleden gerçek üreticiler, sıcak mutfaklar',
                          ),
                          const SizedBox(height: 14),
                          SizedBox(
                            height: 245,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: featuredKitchens.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(width: 14),
                              itemBuilder: (context, index) {
                                final item = featuredKitchens[index];
                                return EvKitchenCard(
                                  name: item.name,
                                  district: item.district,
                                  category: item.category,
                                  imageUrl: item.imageUrl,
                                  badgeType: item.badgeType,
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 26),
                          _buildHorizontalSection(
                            context: context,
                            title: dominantDistrict.isEmpty
                                ? 'Mahallenin Lezzetleri'
                                : 'Mahallenin Lezzetleri • $dominantDistrict',
                            subtitle:
                                'Yakın çevreden güçlü score alan ev lezzetleri',
                            docs: mahalleDocs,
                          ),
                          const SizedBox(height: 24),
                          _buildHorizontalSection(
                            context: context,
                            title: 'Bugün Evde Ne Pişiyor',
                            subtitle:
                                'Bugün hazırlanan veya yeni eklenen sıcak lezzetler',
                            docs: bugunDocs,
                          ),
                          const SizedBox(height: 24),
                          _buildHorizontalSection(
                            context: context,
                            title: 'Trend Yemekler',
                            subtitle: 'Score değeri yüksek, ilgi gören ürünler',
                            docs: trendDocs,
                          ),
                          const SizedBox(height: 24),
                          _buildHorizontalSection(
                            context: context,
                            title: 'Yeni Mutfaklar',
                            subtitle: 'Yeni katılan mutfaklardan taze ürünler',
                            docs: yeniDocs,
                          ),
                          const SizedBox(height: 26),
                          _SectionTitle(
                            title: _selectedCategory == 'Tümü'
                                ? 'Tüm Ev Lezzetleri'
                                : _selectedCategory,
                            subtitle:
                                'Grid görünümde tüm aktif ürünleri keşfet',
                          ),
                          const SizedBox(height: 14),
                        ],
                      ),
                    ),
                  ),
                  if (docs.isEmpty)
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(24, 24, 24, 80),
                        child: _CenterInfo(
                          icon: Icons.search_off_rounded,
                          title: 'Bu kategoride ürün bulunamadı',
                          message:
                              'Başka bir kategori seçebilir veya tüm ürünlere dönebilirsiniz.',
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
                      sliver: SliverGrid(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final doc = docs[index];
                          final data = doc.data();

                          final String ad = _safeText(
                            data['ad'] ?? data['urunAdi'] ?? data['yemekAdi'],
                          );

                          final String dukkan = _safeText(
                            data['dukkan'] ??
                                data['dukkanAdi'] ??
                                data['satici'],
                          );

                          final String sehir = _safeText(data['sehir']);
                          final String ilce = _safeText(data['ilce']);

                          final String aciklama = _safeText(
                            data['aciklama'] ?? data['tarif'],
                          );

                          final dynamic fiyatRaw =
                              data['fiyat'] ?? data['gelAlFiyat'];
                          final double fiyat = _readPrice(fiyatRaw);
                          final String fiyatText = fiyat <= 0
                              ? ''
                              : '${fiyat.toStringAsFixed(0)} ₺';

                          final String img = _safeText(
                            data['img'] ?? data['imgUrl'] ?? data['resim'],
                          );

                          final String konum = [
                            if (ilce.isNotEmpty) ilce,
                            if (sehir.isNotEmpty) sehir,
                          ].join(' / ');

                          final category = _mapCategory(data);

                          return EvPremiumProductCard(
                            title: ad,
                            kitchen: dukkan,
                            subtitle: aciklama.isNotEmpty
                                ? aciklama
                                : 'Ev yapımı, günlük hazırlanmış, sıcak ve güven veren bir mahalle lezzeti.',
                            category: category,
                            locationText: konum,
                            priceText: fiyatText,
                            imageUrl: img,
                            badgeType:
                                _safeText(data['sellerBadgeType']).isEmpty
                                ? 'none'
                                : _safeText(data['sellerBadgeType']),
                            onTap: () => _openDetail(context, doc),
                            onAddToCart: () => _addToCart(context, doc),
                          );
                        }, childCount: docs.length),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          mainAxisSpacing: 18,
                          crossAxisSpacing: 18,
                          childAspectRatio: isMobile ? 0.78 : 0.76,
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

class EvLezzetleriVitriniPage extends StatelessWidget {
  const EvLezzetleriVitriniPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const EvLezzetleriVitrini();
  }
}

class _HeroSection extends StatelessWidget {
  final bool isMobile;

  const _HeroSection({required this.isMobile});

  static const Color _gold = Color(0xFFFFB300);
  static const Color _panel = Color(0xFF1A1A1A);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 18 : 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [Color(0xFF1A1A1A), Color(0xFF222222), Color(0xFF151515)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: _gold.withOpacity(0.35)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.28),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _HeroTextBlock(),
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
                const Expanded(flex: 6, child: _HeroTextBlock()),
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
  const _HeroTextBlock();

  static const Color _gold = Color(0xFFFFB300);
  static const Color _softGold = Color(0xFFFFE0A3);

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mahalle Mutfağı',
          style: TextStyle(
            color: _gold,
            fontSize: 30,
            fontWeight: FontWeight.w900,
            height: 1.05,
          ),
        ),
        SizedBox(height: 10),
        Text(
          'Ev yapımı günlük yemekler, tatlılar, kahvaltılıklar ve mahalleden gelen sıcak lezzetler.',
          style: TextStyle(
            color: Colors.white,
            fontSize: 15,
            height: 1.55,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 12),
        Text(
          'Gerçek üreticiler • güven veren mutfaklar • premium vitrin',
          style: TextStyle(
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
        color: _gold.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _gold.withOpacity(0.4)),
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
                border: Border.all(color: isSelected ? _gold : Colors.white12),
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

  const _SectionTitle({required this.title, required this.subtitle});

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
              color: _gold.withOpacity(0.14),
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
  static const Color _gold2 = Color(0xFFFF9800);
  static const Color _dark = Color(0xFF121212);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [_gold, _gold2],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x55FFB300),
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
            color: Colors.black.withOpacity(0.10),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.delivery_dining_rounded,
            color: Colors.black,
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
                      color: Colors.black,
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
                  color: Colors.black87,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  height: 1.35,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Esnek çalışma • Bölgesel teslimat • Hızlı başvuru',
                style: TextStyle(
                  color: Colors.black54,
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
            MaterialPageRoute(builder: (_) => const KuryeBasvuruFormu()),
          );
        },
        icon: const Icon(Icons.flash_on, size: 18),
        label: const Text(
          'Hemen Başvur',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: _dark,
          foregroundColor: Colors.white,
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
