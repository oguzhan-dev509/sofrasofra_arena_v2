import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sofrasofra_arena_v2/services/sepet_service.dart';

import 'package:sofrasofra_arena_v2/cart/sepet_sayfasi.dart';

class ChefGallerySalesBridge {
  /// Galeri fotoğrafı için urunler kaydı yoksa oluşturur, varsa döner.
  static Future<DocumentReference<Map<String, dynamic>>> ensureGalleryProduct({
    required String chefId,
    required String imageUrl,
  }) async {
    final col = FirebaseFirestore.instance.collection('urunler');

    // Aynı görsel + aynı şef için var mı?
    final q = await col
        .where('img', isEqualTo: imageUrl)
        .where('dukkanId', isEqualTo: chefId)
        .limit(1)
        .get();

    if (q.docs.isNotEmpty) {
      return q.docs.first.reference;
    }

    // Yoksa oluştur
    final ref = await col.add({
      'ad': 'Şef Galeri Ürünü',
      'urunAdi': 'Şef Galeri Ürünü',
      'img': imageUrl,
      'imageUrl': imageUrl,
      'images': [imageUrl],
      'aciklama': '',
      'description': '',
      'fiyat': 0,
      'price': 0,
      'kategori': 'Usta Şefler',
      'tip': 'Usta Şefler',
      'source': 'chef_gallery',
      'dukkanAdi': 'Şefin İmza Mutfağı',
      'dukkan': 'Şefin İmza Mutfağı',
      'dukkanId': chefId,
      'sellerId': chefId,
      'chefId': chefId,
      'isActive': true,
      'aktifMi': true,
      'onayDurumu': 'onaylandi',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return ref;
  }
}

/// Galeri kartının altına eklenecek aksiyon barı
class ChefGallerySalesActions extends StatelessWidget {
  final String chefId;
  final String imageUrl;
  final bool isAdmin;

  const ChefGallerySalesActions({
    super.key,
    required this.chefId,
    required this.imageUrl,
    this.isAdmin = false,
  });
  double _asDouble(dynamic value) {
    if (value == null) return 0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString().replaceAll(',', '.')) ?? 0;
  }

  Widget _galleryPriceChip({
    required String label,
    required String price,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: const Color(0xFFFFB300).withValues(alpha: 0.45),
        ),
      ),
      child: Text(
        '$label $price',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  static const Color gold = Color(0xFFFFB300);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentReference<Map<String, dynamic>>>(
      future: ChefGallerySalesBridge.ensureGalleryProduct(
        chefId: chefId,
        imageUrl: imageUrl,
      ),
      builder: (context, refSnap) {
        if (!refSnap.hasData) {
          return const SizedBox.shrink();
        }

        final ref = refSnap.data!;

        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: ref.snapshots(),
          builder: (context, snap) {
            final data = snap.data?.data() ?? {};

            final price = _asDouble(data['price'] ?? data['fiyat']);
            final gelAlPrice = _asDouble(
              data['gelAlFiyat'] ?? data['price'] ?? data['fiyat'],
            );
            final goturPrice = _asDouble(data['goturFiyat']);

            final galleryDescription =
                (data['aciklama'] ?? data['description'] ?? '')
                    .toString()
                    .trim();

            final title = (data['ad'] ?? data['urunAdi'] ?? 'Şef Galeri Ürünü')
                .toString();

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withOpacity(0.8),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Row(
                children: [
                  if (isAdmin) ...[
                    InkWell(
                      borderRadius: BorderRadius.circular(999),
                      onTap: () => _editPrice(context, ref, price),
                      child: Container(
                        width: 24,
                        height: 24,
                        margin: const EdgeInsets.only(right: 4),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color:
                              const Color(0xFFFFB300).withValues(alpha: 0.94),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.black.withValues(alpha: 0.18),
                          ),
                        ),
                        child: const Icon(
                          Icons.edit_rounded,
                          color: Colors.black,
                          size: 13,
                        ),
                      ),
                    ),
                  ],
                  const Spacer(),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: price <= 0
                        ? null
                        : () async {
                            final gelAlFinalPrice =
                                gelAlPrice > 0 ? gelAlPrice : price;
                            final goturFinalPrice =
                                goturPrice > 0 ? goturPrice : null;

                            final selected = await showModalBottomSheet<
                                Map<String, dynamic>>(
                              context: context,
                              backgroundColor: const Color(0xFF151515),
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(24),
                                ),
                              ),
                              builder: (sheetContext) {
                                return SafeArea(
                                  child: Padding(
                                    padding: const EdgeInsets.all(18),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Teslimat tercihi seçin',
                                          style: TextStyle(
                                            color: Color(0xFFFFB300),
                                            fontSize: 18,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        ListTile(
                                          contentPadding: EdgeInsets.zero,
                                          title: const Text(
                                            'Gel-Al',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                          subtitle: Text(
                                            '${gelAlFinalPrice.toStringAsFixed(0)} ₺',
                                            style: const TextStyle(
                                                color: Colors.white70),
                                          ),
                                          onTap: () {
                                            Navigator.pop(sheetContext, {
                                              'tip': 'gel_al',
                                              'fiyat': gelAlFinalPrice,
                                            });
                                          },
                                        ),
                                        if (goturFinalPrice != null)
                                          ListTile(
                                            contentPadding: EdgeInsets.zero,
                                            title: const Text(
                                              'Götür',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                            subtitle: Text(
                                              '${goturFinalPrice.toStringAsFixed(0)} ₺',
                                              style: const TextStyle(
                                                  color: Colors.white70),
                                            ),
                                            onTap: () {
                                              Navigator.pop(sheetContext, {
                                                'tip': 'gotur',
                                                'fiyat': goturFinalPrice,
                                              });
                                            },
                                          ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            );

                            if (selected == null) return;

                            final selectedTip = selected['tip'].toString();
                            final selectedPrice = selected['fiyat'] as double;

                            await SepetService.sepeteEkle(
                              urunId: '${ref.id}_$selectedTip',
                              urunAdi: title,
                              dukkanAdi: 'Şefin İmza Mutfağı',
                              kategori: 'Usta Şefler',
                              img: imageUrl,
                              fiyat: selectedPrice,
                              gelAlFiyat: gelAlFinalPrice,
                              goturFiyat: goturFinalPrice,
                              teslimatTipi: selectedTip,
                              saticiId: chefId,
                              dukkanId: chefId,
                            );

                            if (!context.mounted) return;

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  selectedTip == 'gotur'
                                      ? 'Götür fiyatı ile sepete eklendi'
                                      : 'Gel-Al fiyatı ile sepete eklendi',
                                ),
                              ),
                            );

                            await Future<void>.delayed(
                              const Duration(milliseconds: 650),
                            );

                            if (!context.mounted) return;

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const SepetSayfasi(),
                              ),
                            );
                          },
                    child: SizedBox(
                      width: 34,
                      height: 34,
                      child: Center(
                        child: Icon(
                          Icons.add_shopping_cart,
                          color: price <= 0 ? Colors.white38 : Colors.white,
                          size: 19,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _editPrice(
    BuildContext context,
    DocumentReference<Map<String, dynamic>> ref,
    double current,
  ) async {
    final snap = await ref.get();
    final data = snap.data() ?? {};

    final gelAlController = TextEditingController(
      text: (data['gelAlFiyat'] ?? data['price'] ?? data['fiyat'] ?? current)
          .toString(),
    );

    final goturController = TextEditingController(
      text: (data['goturFiyat'] ?? '').toString(),
    );

    final aciklamaController = TextEditingController(
      text: (data['aciklama'] ?? data['description'] ?? '').toString(),
    );

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Galeri Ürün Bilgileri'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: gelAlController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Gel-Al Fiyatı (₺)',
                hintText: 'Örn: 1900',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: goturController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Götür Fiyatı (₺)',
                hintText: 'Örn: 2100',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: aciklamaController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Tarif / Açıklama',
                hintText: 'Ürün açıklaması',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () async {
              final gelAl = double.tryParse(
                    gelAlController.text.trim().replaceAll(',', '.'),
                  ) ??
                  0;

              final gotur = double.tryParse(
                    goturController.text.trim().replaceAll(',', '.'),
                  ) ??
                  0;

              final desc = aciklamaController.text.trim();

              await ref.set({
                'price': gelAl,
                'fiyat': gelAl,
                'gelAlFiyat': gelAl,
                'goturFiyat': gotur,
                'aciklama': desc,
                'description': desc,
                'updatedAt': FieldValue.serverTimestamp(),
              }, SetOptions(merge: true));

              if (!context.mounted) return;
              Navigator.pop(context);
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }
}

class ChefGalleryPriceOverlay extends StatelessWidget {
  final String chefId;
  final String imageUrl;

  const ChefGalleryPriceOverlay({
    super.key,
    required this.chefId,
    required this.imageUrl,
  });

  double _asDouble(dynamic value) {
    if (value == null) return 0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString().replaceAll(',', '.')) ?? 0;
  }

  Widget _priceChip({
    required String label,
    required double value,
  }) {
    final text = value > 0 ? '${value.toStringAsFixed(0)} ₺' : '—';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: const Color(0xFFFFB300).withValues(alpha: 0.42),
        ),
      ),
      child: Text(
        '$label $text',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentReference<Map<String, dynamic>>>(
      future: ChefGallerySalesBridge.ensureGalleryProduct(
        chefId: chefId,
        imageUrl: imageUrl,
      ),
      builder: (context, refSnap) {
        if (!refSnap.hasData) {
          return const SizedBox.shrink();
        }

        final ref = refSnap.data!;

        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: ref.snapshots(),
          builder: (context, snap) {
            final data = snap.data?.data() ?? {};

            final gelAlPrice = _asDouble(
              data['gelAlFiyat'] ?? data['price'] ?? data['fiyat'],
            );
            final goturPrice = _asDouble(data['goturFiyat']);

            return Align(
              alignment: Alignment.bottomLeft,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(7, 0, 7, 7),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    _priceChip(label: 'Gel-Al', value: gelAlPrice),
                    _priceChip(label: 'Götür', value: goturPrice),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
