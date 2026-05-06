import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'urun_detay.dart';

class KategoriUrunListesiSayfasi extends StatelessWidget {
  final String kategori;
  final String aciklama;

  const KategoriUrunListesiSayfasi({
    super.key,
    required this.kategori,
    required this.aciklama,
  });

  static const Color _bg = Color(0xFFF8F3EA);
  static const Color _card = Colors.white;
  static const Color _gold = Color(0xFFFFB300);
  static const Color _goldDark = Color(0xFF8A5A00);
  static const Color _textDark = Color(0xFF2D2215);
  static const Color _textMuted = Color(0xFF7A6A58);
  static const Color _border = Color(0xFFE7D6B8);
  static const Color _chipBg = Color(0xFFFFF8EC);

  Stream<QuerySnapshot<Map<String, dynamic>>> _stream() {
    return FirebaseFirestore.instance
        .collection('urunler')
        .where('kategori', isEqualTo: kategori)
        .snapshots();
  }

  String _readString(
    Map<String, dynamic> data,
    List<String> keys, {
    String fallback = '',
  }) {
    for (final key in keys) {
      final value = data[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString().trim();
      }
    }
    return fallback;
  }

  double _asDouble(dynamic value) {
    if (value == null) return 0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();
    if (value is String) {
      return double.tryParse(value.replaceAll(',', '.')) ?? 0;
    }
    return 0;
  }

  String _price(double value) => '${value.toStringAsFixed(0)} ₺';

  bool _isHttp(String s) {
    return s.startsWith('http://') || s.startsWith('https://');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: _textDark),
        title: Text(
          kategori,
          style: const TextStyle(
            color: _textDark,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _card,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _border),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0F000000),
                    blurRadius: 16,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'EV YAPIMI KATEGORİ',
                    style: TextStyle(
                      color: _goldDark,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    aciklama,
                    style: const TextStyle(
                      color: _textMuted,
                      fontSize: 14,
                      height: 1.45,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _stream(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Kategori ürünleri yüklenirken hata oluştu.\n\n${snapshot.error}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: _textMuted,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: _gold),
                  );
                }

                final docs = snapshot.data?.docs ?? [];

                if (docs.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: _card,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: _border),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 84,
                              height: 84,
                              decoration: BoxDecoration(
                                color: _chipBg,
                                borderRadius: BorderRadius.circular(22),
                                border: Border.all(color: _border),
                              ),
                              child: const Icon(
                                Icons.inventory_2_outlined,
                                color: _goldDark,
                                size: 38,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              '$kategori kategorisinde henüz ürün yok.',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: _textDark,
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Yeni ev yapımı ürünler eklendiğinde burada listelenecek.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: _textMuted,
                                fontSize: 14,
                                height: 1.45,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data();

                    final urunAdi = _readString(
                      data,
                      ['urunAdi', 'ad', 'isim', 'title', 'name', 'yemekAdi'],
                      fallback: 'Ürün',
                    );

                    final dukkanAdi = _readString(
                      data,
                      [
                        'dukkanAdi',
                        'dukkan',
                        'saticiAdi',
                        'sellerName',
                        'magazaAdi',
                      ],
                    );

                    final konum = _readString(
                      data,
                      ['konum', 'adres', 'ilce', 'sehir'],
                    );

                    final aciklama = _readString(
                      data,
                      ['aciklama', 'description', 'not'],
                      fallback: 'Bu ürün için henüz açıklama girilmedi.',
                    );

                    final img = _readString(
                      data,
                      ['img', 'imageUrl', 'foto', 'gorselUrl'],
                    );

                    final fiyat = _asDouble(
                      data['fiyat'] ??
                          data['price'] ??
                          data['birimFiyat'] ??
                          data['unitPrice'] ??
                          0,
                    );

                    return Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        color: _card,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _border),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x0F000000),
                            blurRadius: 16,
                            offset: Offset(0, 8),
                          ),
                        ],
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () {
                          final String youtubeUrl =
                              (data['youtubeUrl'] ?? '').toString();

                          final List<String> urunGorseller =
                              ((data['images'] as List?) ?? [])
                                  .map((e) => e.toString().trim())
                                  .where((e) => e.isNotEmpty)
                                  .toList();

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => UrunDetaySayfasi(
                                urunAdi: urunAdi,
                                urunFiyat: fiyat <= 0
                                    ? 'Fiyat yakında'
                                    : _price(fiyat),
                                urunGorsel: img,
                                aciklama: aciklama,
                                dukkanAdi: dukkanAdi,
                                konum: konum,
                                youtubeUrl: youtubeUrl,
                                urunGorseller: urunGorseller,
                                productId:
                                    (data['id'] ?? data['productId'] ?? '')
                                        .toString(),
                                sellerId:
                                    (data['dukkanId'] ?? data['sellerId'] ?? '')
                                        .toString(),
                                kategori: 'Ev Lezzetleri',
                                gelAlFiyat: data['gelAlFiyat'] is num
                                    ? data['gelAlFiyat'] as num
                                    : null,
                                goturFiyat: data['goturFiyat'] is num
                                    ? data['goturFiyat'] as num
                                    : null,
                                isAdmin: false,
                              ),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: _buildImage(img),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      urunAdi,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: _textDark,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w900,
                                        height: 1.2,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    if (dukkanAdi.isNotEmpty)
                                      Text(
                                        dukkanAdi,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: _goldDark,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    if (konum.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        konum,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: _textMuted,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 10),
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 6,
                                      children: const [
                                        _MiniChip(
                                          icon: Icons.schedule,
                                          text: 'Günlük hazırlanır',
                                        ),
                                        _MiniChip(
                                          icon: Icons.home_work_outlined,
                                          text: 'Ev yapımı',
                                        ),
                                        _MiniChip(
                                          icon: Icons
                                              .local_fire_department_outlined,
                                          text: 'Özel lezzet',
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Text(
                                          fiyat <= 0
                                              ? 'Fiyat yakında'
                                              : _price(fiyat),
                                          style: const TextStyle(
                                            color: _textDark,
                                            fontSize: 17,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                        const Spacer(),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 8,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFFFF4D9),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            border: Border.all(color: _border),
                                          ),
                                          child: const Text(
                                            'İncele',
                                            style: TextStyle(
                                              color: _goldDark,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImage(String img) {
    if (_isHttp(img)) {
      return Image.network(
        img,
        width: 96,
        height: 96,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _placeholder();
        },
      );
    }

    return _placeholder();
  }

  Widget _placeholder() {
    return Container(
      width: 96,
      height: 96,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFF7E7BF),
            Color(0xFFE7C784),
          ],
        ),
      ),
      child: const Icon(
        Icons.restaurant_menu_rounded,
        color: _goldDark,
        size: 28,
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  final IconData icon;
  final String text;

  const _MiniChip({
    required this.icon,
    required this.text,
  });

  static const Color _textDark = Color(0xFF2D2215);
  static const Color _goldDark = Color(0xFF8A5A00);
  static const Color _border = Color(0xFFE7D6B8);
  static const Color _chipBg = Color(0xFFFFF8EC);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: _chipBg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: _goldDark),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              color: _textDark,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
