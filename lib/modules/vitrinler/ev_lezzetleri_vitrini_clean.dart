import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:sofrasofra_arena_v2/modules/urun_detay.dart';

class EvLezzetleriVitriniClean extends StatefulWidget {
  final String city;
  final String district;

  const EvLezzetleriVitriniClean({
    super.key,
    required this.city,
    required this.district,
  });

  @override
  State<EvLezzetleriVitriniClean> createState() =>
      _EvLezzetleriVitriniCleanState();
}

class _EvLezzetleriVitriniCleanState extends State<EvLezzetleriVitriniClean> {
  static const Color _bg = Color(0xFF111111);
  static const Color _gold = Color(0xFFFFB300);

  String _selectedCategory = 'Tümü';
// ignore: unused_field
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
        .where('tip', isEqualTo: 'Ev Lezzetleri');
  }

  String _safeText(dynamic value) {
    return (value ?? '').toString().trim();
  }

  String _normalizeText(dynamic value) {
    return (value ?? '')
        .toString()
        .trim()
        .toLowerCase()
        .replaceAll('i̇', 'i')
        .replaceAll('ı', 'i')
        .replaceAll('â', 'a')
        .replaceAll('á', 'a')
        .replaceAll('à', 'a')
        .replaceAll('ä', 'a')
        .replaceAll('ç', 'c')
        .replaceAll('ğ', 'g')
        .replaceAll('ö', 'o')
        .replaceAll('ş', 's')
        .replaceAll('ü', 'u');
  }

  bool _isApproved(Map<String, dynamic> data) {
    final status = _normalizeText(data['onayDurumu']);
    if (status.isEmpty) return true;
    return status == 'onaylandi';
  }

  bool _isActiveProduct(Map<String, dynamic> data) {
    final dynamic isActive = data['isActive'];
    final dynamic aktifMi = data['aktifMi'];

    if (isActive == true || aktifMi == true) return true;
    if (isActive == null && aktifMi == null) return true;
    return false;
  }

  bool _isValidProduct(Map<String, dynamic> data) {
    final String ad = _safeText(
      data['ad'] ?? data['urunAdi'] ?? data['yemekAdi'],
    );

    final String dukkan = _safeText(
      data['dukkan'] ?? data['dukkanAdi'] ?? data['satici'],
    );

    return ad.isNotEmpty && dukkan.isNotEmpty;
  }

  bool _matchesLocation(Map<String, dynamic> data) {
    final selectedCity = _normalizeText(widget.city);
    final selectedDistrict = _normalizeText(widget.district);

    final dataCity = _normalizeText(
      data['sehir'] ?? data['city'] ?? data['il'] ?? data['province'],
    );

    final dataDistrict = _normalizeText(
      data['ilce'] ?? data['district'] ?? data['ilçe'] ?? data['bolge'],
    );

    if (selectedCity.isEmpty) return true;

    final cityMatches = dataCity.isNotEmpty && dataCity == selectedCity;
    if (!cityMatches) return false;

    if (selectedDistrict.isEmpty || selectedDistrict == 'tumu') {
      return true;
    }

    return dataDistrict.isNotEmpty && dataDistrict == selectedDistrict;
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

  String _resolveCardImage(Map<String, dynamic> data) {
    final List<String> images = ((data['images'] as List?) ?? [])
        .map((e) => e.toString().trim())
        .where((e) => e.isNotEmpty)
        .toList();

    if (images.isNotEmpty) return images.first;

    return (data['img'] ?? data['imgUrl'] ?? data['resim'] ?? '')
        .toString()
        .trim();
  }

  List<String> _resolveGalleryImages(Map<String, dynamic> data) {
    final List<String> images = ((data['images'] as List?) ?? [])
        .map((e) => e.toString().trim())
        .where((e) => e.isNotEmpty)
        .toList();

    if (images.isNotEmpty) return images;

    final fallback = _resolveCardImage(data);
    if (fallback.isNotEmpty) return [fallback];

    return [];
  }

  int _photoCount(Map<String, dynamic> data) {
    final List<String> images = ((data['images'] as List?) ?? [])
        .map((e) => e.toString().trim())
        .where((e) => e.isNotEmpty)
        .toList();

    if (images.isNotEmpty) return images.length;

    final fallback = (data['img'] ?? data['imgUrl'] ?? data['resim'] ?? '')
        .toString()
        .trim();

    return fallback.isNotEmpty ? 1 : 0;
  }

  double _readPrice(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    if (value is String) {
      return double.tryParse(value.replaceAll(',', '.').trim()) ?? 0;
    }
    return 0;
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

    final String img = _resolveCardImage(data);
    final List<String> urunGorseller = _resolveGalleryImages(data);

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
          urunGorseller: urunGorseller,
          aciklama: aciklama,
          dukkanAdi: dukkan,
          konum: konum,
          youtubeUrl: (data['youtubeUrl'] ?? data['videoUrl'] ?? '').toString(),
          productId: doc.id,
          sellerId: (data['dukkanId'] ?? data['sellerId'] ?? '').toString(),
          isAdmin: false,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: _gold),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'MAHALLE MUTFAĞI',
              style: TextStyle(
                color: _gold,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.3,
              ),
            ),
            Text(
              '${widget.city} • ${widget.district}',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _query().snapshots(),
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Hata: ${snap.error}',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            );
          }

          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: _gold),
            );
          }

          final allDocs = snap.data?.docs ?? [];

          final validProductDocs =
              allDocs.where((doc) => _isValidProduct(doc.data())).toList();

          final approvedDocs =
              allDocs.where((doc) => _isApproved(doc.data())).toList();

          final activeDocs =
              allDocs.where((doc) => _isActiveProduct(doc.data())).toList();

          final locationDocs =
              allDocs.where((doc) => _matchesLocation(doc.data())).toList();

          final validDocs = allDocs.where((doc) {
            final data = doc.data();
            return _isValidProduct(data) &&
                _isApproved(data) &&
                _isActiveProduct(data) &&
                _matchesLocation(data);
          }).toList();

          final docs = validDocs
              .where((doc) => _matchesSelectedCategory(doc.data()))
              .toList();
          final multiPhotoDocs = docs
              .where((doc) => _resolveGalleryImages(doc.data()).length > 1)
              .toList();
          if (multiPhotoDocs.isEmpty) {
            return const Center(
              child: Text(
                'Çoklu foto ürün yok',
                style: TextStyle(color: Colors.white70),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            itemCount: multiPhotoDocs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 14),
            itemBuilder: (context, index) {
              final doc = multiPhotoDocs[index];
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

              final double fiyat =
                  _readPrice(data['fiyat'] ?? data['gelAlFiyat']);

              final String fiyatText = fiyat <= 0
                  ? 'Fiyat yakında'
                  : '${fiyat.toStringAsFixed(0)} ₺';

              final String cardImage = _resolveCardImage(data);

              return InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () => _openDetail(context, doc),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF181818),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(18),
                        ),
                        child: SizedBox(
                          height: 220,
                          width: double.infinity,
                          child: cardImage.isNotEmpty
                              ? Image.network(
                                  cardImage,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    color: const Color(0xFF242424),
                                    alignment: Alignment.center,
                                    child: const Icon(
                                      Icons.image_not_supported,
                                      color: Colors.white38,
                                      size: 34,
                                    ),
                                  ),
                                )
                              : Container(
                                  color: const Color(0xFF242424),
                                  alignment: Alignment.center,
                                  child: const Icon(
                                    Icons.fastfood_rounded,
                                    color: Colors.white38,
                                    size: 34,
                                  ),
                                ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              ad,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              dukkan,
                              style: const TextStyle(
                                color: _gold,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              aciklama.isNotEmpty
                                  ? aciklama
                                  : 'Ev yapımı lezzet',
                              style: const TextStyle(
                                color: Colors.white70,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              '$ilce / $sehir',
                              style: const TextStyle(
                                color: Colors.white60,
                                fontSize: 12.5,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              fiyatText,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
          final debugSamples = allDocs.take(5).map((doc) {
            final data = doc.data();
            final ad =
                _safeText(data['ad'] ?? data['urunAdi'] ?? data['yemekAdi']);
            final dukkan = _safeText(
              data['dukkan'] ?? data['dukkanAdi'] ?? data['satici'],
            );
            final sehir = _safeText(data['sehir']);
            final ilce = _safeText(data['ilce']);
            final onay = _safeText(data['onayDurumu']);
            final isActive = data['isActive'];
            final aktifMi = data['aktifMi'];

            return '''
Ürün: $ad
Dükkan: $dukkan
Şehir: $sehir
İlçe: $ilce
Onay: $onay
isActive: $isActive
aktifMi: $aktifMi
valid=${_isValidProduct(data)}
approved=${_isApproved(data)}
active=${_isActiveProduct(data)}
location=${_matchesLocation(data)}
''';
          }).toList();

          return Column(
            children: [
              Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white12),
                ),
                child: DefaultTextStyle(
                  style: const TextStyle(color: Colors.white70, fontSize: 12.5),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'DEBUG SAYACI',
                        style: TextStyle(
                          color: _gold,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text('Seçilen şehir: ${widget.city}'),
                      Text('Seçilen ilçe: ${widget.district}'),
                      Text('Toplam gelen doc: ${allDocs.length}'),
                      Text('_isValidProduct geçen: ${validProductDocs.length}'),
                      Text('_isApproved geçen: ${approvedDocs.length}'),
                      Text('_isActiveProduct geçen: ${activeDocs.length}'),
                      Text('_matchesLocation geçen: ${locationDocs.length}'),
                      Text('Filtre sonrası doc: ${validDocs.length}'),
                      Text('Kategori sonrası doc: ${docs.length}'),
                      const SizedBox(height: 12),
                      const Text(
                        'İlk 5 örnek:',
                        style: TextStyle(
                          color: _gold,
                          fontWeight: FontWeight.w700,
                          fontSize: 12.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...debugSamples.map(
                        (e) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Text(
                            e,
                            style: const TextStyle(
                              color: Colors.white60,
                              fontSize: 11.5,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(
                height: 260,
                child: SingleChildScrollView(
                  child: Container(
                    width: double.infinity,
                    margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A1A),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: DefaultTextStyle(
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 12.5),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'DEBUG SAYACI',
                            style: TextStyle(
                              color: _gold,
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text('Seçilen şehir: ${widget.city}'),
                          Text('Seçilen ilçe: ${widget.district}'),
                          Text('Toplam gelen doc: ${allDocs.length}'),
                          Text(
                              '_isValidProduct geçen: ${validProductDocs.length}'),
                          Text('_isApproved geçen: ${approvedDocs.length}'),
                          Text('_isActiveProduct geçen: ${activeDocs.length}'),
                          Text(
                              '_matchesLocation geçen: ${locationDocs.length}'),
                          Text('Filtre sonrası doc: ${validDocs.length}'),
                          Text('Kategori sonrası doc: ${docs.length}'),
                          const SizedBox(height: 8),
                          const Text(
                            'Debug örnekleri geçici olarak kapatıldı.',
                            style: TextStyle(
                              color: Colors.white38,
                              fontSize: 11.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 400,
                child: docs.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Text(
                            'Bu filtreyle ürün görünmüyor.',
                            style: TextStyle(color: Colors.white70),
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        itemCount: docs.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 14),
                        itemBuilder: (context, index) {
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

                          final double fiyat =
                              _readPrice(data['fiyat'] ?? data['gelAlFiyat']);

                          final String fiyatText = fiyat <= 0
                              ? 'Fiyat yakında'
                              : '${fiyat.toStringAsFixed(0)} ₺';

                          final String cardImage = _resolveCardImage(data);
                          final int photoCount = _photoCount(data);
                          return InkWell(
                            borderRadius: BorderRadius.circular(18),
                            onTap: () => _openDetail(context, doc),
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFF181818),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: Colors.white12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ClipRRect(
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(18),
                                    ),
                                    child: SizedBox(
                                      height: 220,
                                      width: double.infinity,
                                      child: cardImage.isNotEmpty
                                          ? Image.network(
                                              cardImage,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) =>
                                                  Container(
                                                color: const Color(0xFF242424),
                                                alignment: Alignment.center,
                                                child: const Icon(
                                                  Icons.image_not_supported,
                                                  color: Colors.white38,
                                                  size: 34,
                                                ),
                                              ),
                                            )
                                          : Container(
                                              color: const Color(0xFF242424),
                                              alignment: Alignment.center,
                                              child: const Icon(
                                                Icons.fastfood_rounded,
                                                color: Colors.white38,
                                                size: 34,
                                              ),
                                            ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(14),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          ad,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 17,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          dukkan,
                                          style: const TextStyle(
                                            color: _gold,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          aciklama.isNotEmpty
                                              ? aciklama
                                              : 'Ev yapımı lezzet',
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            height: 1.4,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Foto: $photoCount',
                                          style: TextStyle(
                                            color: photoCount > 1
                                                ? _gold
                                                : Colors.white38,
                                            fontSize: 11.5,
                                            fontWeight: photoCount > 1
                                                ? FontWeight.w700
                                                : FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        Text(
                                          '$ilce / $sehir',
                                          style: const TextStyle(
                                            color: Colors.white60,
                                            fontSize: 12.5,
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              fiyatText,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 15,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 10,
                                                vertical: 6,
                                              ),
                                              decoration: BoxDecoration(
                                                color: _gold,
                                                borderRadius:
                                                    BorderRadius.circular(999),
                                              ),
                                              child: const Text(
                                                'Detay',
                                                style: TextStyle(
                                                  color: Colors.black,
                                                  fontWeight: FontWeight.w800,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 10),
                                        Text(
                                          'img: ${cardImage.isNotEmpty ? "var" : "yok"} • kategori: ${_mapCategory(data)}',
                                          style: const TextStyle(
                                            color: Colors.white38,
                                            fontSize: 11.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
