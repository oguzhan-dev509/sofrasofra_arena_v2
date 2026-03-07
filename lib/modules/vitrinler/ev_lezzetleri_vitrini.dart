import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sofrasofra_arena_v2/modules/urun_detay.dart';
import 'package:sofrasofra_arena_v2/services/sepet_service.dart';
import '../../cart/sepet_sayfasi.dart';
import '../../orders/musteri_siparis_takip_sayfasi.dart';
import '../../merchant/satici_siparis_paneli.dart';

class EvLezzetleriVitrini extends StatelessWidget {
  const EvLezzetleriVitrini({super.key});

  static const Color _bg = Color(0xFFFDF5E6);
  static const Color _brown = Colors.brown;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: const Text(
          "MAHALLE MUTFAĞI",
          style: TextStyle(
            color: _brown,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: _brown),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart),
            tooltip: 'Sepetim',
            color: _brown,
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
            icon: const Icon(Icons.receipt_long),
            tooltip: 'Sipariş Takibi',
            color: _brown,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const MusteriSiparisTakipSayfasi(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.storefront),
            tooltip: 'Satıcı Paneli',
            color: _brown,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const SaticiSiparisPaneli(),
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
              title: "Hata",
              message: snap.error.toString(),
            );
          }

          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final allDocs = snap.data?.docs ?? [];

          debugPrint("✅ EV DOC COUNT: ${allDocs.length}");
          for (final doc in allDocs) {
            debugPrint("✅ EV DOC: ${doc.id} => ${doc.data()}");
          }

          final docs =
              allDocs.where((doc) => _isValidProduct(doc.data())).toList();

          debugPrint("✅ VALID EV DOC COUNT: ${docs.length}");

          if (docs.isEmpty) {
            return const _CenterInfo(
              icon: Icons.storefront_outlined,
              title: "Henüz ürün yok",
              message: "Onaylı ve görselli ev lezzeti ürünü bulunamadı.",
            );
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              final double width = constraints.maxWidth;

              int crossAxisCount = 2;
              if (width < 700) {
                crossAxisCount = 1;
              } else if (width > 1100) {
                crossAxisCount = 3;
              }

              return GridView.builder(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
                itemCount: docs.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: width < 700 ? 0.95 : 0.82,
                ),
                itemBuilder: (context, index) {
                  final doc = docs[index];
                  final data = doc.data();

                  final String ad =
                      (data['ad'] ?? data['urunAdi'] ?? data['yemekAdi'] ?? '')
                          .toString()
                          .trim();

                  final String dukkan = (data['dukkan'] ??
                          data['dukkanAdi'] ??
                          data['satici'] ??
                          '')
                      .toString()
                      .trim();

                  final String sehir = (data['sehir'] ?? '').toString().trim();
                  final String ilce = (data['ilce'] ?? '').toString().trim();

                  final String aciklama =
                      (data['aciklama'] ?? data['tarif'] ?? '')
                          .toString()
                          .trim();

                  final dynamic fiyatRaw = data['fiyat'] ?? data['gelAlFiyat'];
                  final double fiyat = _readPrice(fiyatRaw);
                  final String fiyatText =
                      fiyat <= 0 ? '' : fiyat.toStringAsFixed(0);

                  final String img =
                      (data['img'] ?? data['imgUrl'] ?? data['resim'] ?? '')
                          .toString()
                          .trim();

                  final String tip =
                      (data['tip'] ?? 'Ev Lezzetleri').toString().trim();

                  final String konum = [
                    if (ilce.isNotEmpty) ilce,
                    if (sehir.isNotEmpty) sehir,
                  ].join(' / ');

                  return _EvLezzetiKarti(
                    title: ad,
                    dukkan: dukkan,
                    subtitle: aciklama.isNotEmpty
                        ? aciklama
                        : "Ev yapımı, günlük hazırlanmış lezzet.",
                    locationText: konum,
                    priceText: fiyatText.isNotEmpty ? "$fiyatText ₺" : "",
                    imgUrl: img,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => UrunDetaySayfasi(
                            urunAdi: ad,
                            urunFiyat:
                                fiyatText.isNotEmpty ? "$fiyatText ₺" : "",
                            urunGorsel: img,
                            aciklama: aciklama,
                            dukkanAdi: dukkan,
                            konum: konum,
                          ),
                        ),
                      );
                    },
                    onAddToCart: () async {
                      await SepetService.sepeteEkle(
                        urunId: doc.id,
                        urunAdi: ad,
                        dukkanAdi: dukkan,
                        kategori: tip,
                        img: img,
                        fiyat: fiyat,
                      );

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('$ad sepete eklendi.'),
                            backgroundColor: Colors.brown,
                          ),
                        );
                      }
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class EvLezzetleriVitriniPage extends StatelessWidget {
  const EvLezzetleriVitriniPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const EvLezzetleriVitrini();
  }
}

class _EvLezzetiKarti extends StatelessWidget {
  final String title;
  final String dukkan;
  final String subtitle;
  final String locationText;
  final String priceText;
  final String imgUrl;
  final VoidCallback onTap;
  final VoidCallback onAddToCart;

  const _EvLezzetiKarti({
    required this.title,
    required this.dukkan,
    required this.subtitle,
    required this.locationText,
    required this.priceText,
    required this.imgUrl,
    required this.onTap,
    required this.onAddToCart,
  });

  static const Color _brown = Colors.brown;
  static const Color _card = Colors.white;
  static const Color _gold = Color(0xFFFFB300);

  bool _isHttp(String s) => s.startsWith('http://') || s.startsWith('https://');

  @override
  Widget build(BuildContext context) {
    final safeImg = imgUrl.trim();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: _card,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.07),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                child: AspectRatio(
                  aspectRatio: 4 / 3,
                  child: _isHttp(safeImg)
                      ? Image.network(
                          safeImg,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            debugPrint("❌ IMG LOAD FAIL: $safeImg");
                            debugPrint("❌ ERROR: $error");
                            return _imgPlaceholder();
                          },
                        )
                      : _imgPlaceholder(),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: _brown,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        dukkan,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      if (locationText.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on_outlined,
                              size: 15,
                              color: Colors.brown,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                locationText,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.black54,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 8),
                      Expanded(
                        child: Text(
                          subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            height: 1.35,
                            color: Colors.black54,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              priceText.isEmpty ? "Fiyat yakında" : priceText,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: priceText.isEmpty ? Colors.grey : _gold,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          InkWell(
                            onTap: onAddToCart,
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              decoration: BoxDecoration(
                                color: _gold,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.add_shopping_cart,
                                    size: 18,
                                    color: Colors.black,
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    'Sepete Ekle',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _imgPlaceholder() {
    return Container(
      color: Colors.brown.shade50,
      child: const Center(
        child: Icon(
          Icons.image_outlined,
          size: 42,
          color: Colors.brown,
        ),
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

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 42, color: Colors.brown),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.brown,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
