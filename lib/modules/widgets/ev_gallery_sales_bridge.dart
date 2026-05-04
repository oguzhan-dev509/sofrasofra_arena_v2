import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:sofrasofra_arena_v2/cart/sepet_sayfasi.dart';
import 'package:sofrasofra_arena_v2/modules/urun_detay.dart';
import 'package:sofrasofra_arena_v2/services/sepet_service.dart';

class EvGallerySalesBridge {
  static String _safeDocId({
    required String ownerProductId,
    required String imageUrl,
  }) {
    final raw = '${ownerProductId.trim()}|${imageUrl.trim()}';
    final encoded = base64Url.encode(utf8.encode(raw)).replaceAll('=', '');
    return 'ev_gallery_$encoded';
  }

  static DocumentReference<Map<String, dynamic>> galleryProductRef({
    required String ownerProductId,
    required String sellerId,
    required String dukkanAdi,
    required String imageUrl,
  }) {
    final docId = _safeDocId(
      ownerProductId: ownerProductId,
      imageUrl: imageUrl,
    );

    return FirebaseFirestore.instance.collection('urunler').doc(docId);
  }

  static Future<DocumentReference<Map<String, dynamic>>> ensureGalleryProduct({
    required String ownerProductId,
    required String sellerId,
    required String dukkanAdi,
    required String imageUrl,
  }) async {
    final ref = galleryProductRef(
      ownerProductId: ownerProductId,
      sellerId: sellerId,
      dukkanAdi: dukkanAdi,
      imageUrl: imageUrl,
    );

    final snap = await ref.get();

    if (!snap.exists) {
      await ref.set({
        'ad': 'Ev Galeri Ürünü',
        'urunAdi': 'Ev Galeri Ürünü',
        'imageUrl': imageUrl,
        'img': imageUrl,
        'images': [imageUrl],
        'aciklama': '',
        'description': '',
        'fiyat': 0,
        'price': 0,
        'gelAlFiyat': 0,
        'goturFiyat': 0,

        // Ayrıştırma
        'kategori': 'Ev Lezzetleri',
        'tip': 'Ev Lezzetleri',
        'source': 'ev_gallery',
        'orderSource': 'ev_gallery',
        'ownerProductId': ownerProductId,
        'sellerType': 'ev_lezzetleri',
        'paymentChannel': 'ev_order',
        'iyzicoCategory': 'EvLezzetleri',

        // Satıcı bağlantısı
        'dukkanAdi': dukkanAdi,
        'dukkan': dukkanAdi,
        'dukkanId': sellerId,
        'sellerId': sellerId,
        'saticiId': sellerId,

        // Yayın durumu
        'isActive': true,
        'aktifMi': true,
        'onayDurumu': 'onaylandi',

        // Ev Galeri fiyatları nihai müşteri fiyatıdır.
        // Sepet tekrar kurye/işlem ücreti bindirmemeli.
        'deliveryIncludedInPrice': true,
        'feeIncludedInPrice': true,

        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    return ref;
  }
}

class EvGallerySalesActions extends StatelessWidget {
  final String ownerProductId;
  final String sellerId;
  final String dukkanAdi;
  final String imageUrl;
  final bool isAdmin;

  const EvGallerySalesActions({
    super.key,
    required this.ownerProductId,
    required this.sellerId,
    required this.dukkanAdi,
    required this.imageUrl,
    this.isAdmin = false,
  });

  static const Color gold = Color(0xFFFFB300);

  double _asDouble(dynamic value) {
    if (value == null) return 0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString().replaceAll(',', '.')) ?? 0;
  }

  String _priceText(double value) {
    if (value <= 0) return '—';
    return '${value.toStringAsFixed(0)} ₺';
  }

  Widget _priceChip({
    required String label,
    required double price,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: gold.withValues(alpha: 0.45),
        ),
      ),
      child: Text(
        '$label ${_priceText(price)}',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Future<Map<String, dynamic>?> _selectDeliveryMode({
    required BuildContext context,
    required double gelAlFinalPrice,
    required double? goturFinalPrice,
  }) {
    return showModalBottomSheet<Map<String, dynamic>>(
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Teslimat seçimi',
                  style: TextStyle(
                    color: gold,
                    fontSize: 16,
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
                    style: const TextStyle(color: Colors.white70),
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
                      style: const TextStyle(color: Colors.white70),
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
  }

  @override
  Widget build(BuildContext context) {
    if (ownerProductId.trim().isEmpty ||
        sellerId.trim().isEmpty ||
        imageUrl.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    return FutureBuilder<DocumentReference<Map<String, dynamic>>>(
      future: EvGallerySalesBridge.ensureGalleryProduct(
        ownerProductId: ownerProductId,
        sellerId: sellerId,
        dukkanAdi: dukkanAdi,
        imageUrl: imageUrl,
      ),
      builder: (context, refSnap) {
        if (!refSnap.hasData) {
          return const SizedBox(
            height: 42,
            child: Center(
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: gold,
                ),
              ),
            ),
          );
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

            final gelAlFinalPrice = gelAlPrice > 0 ? gelAlPrice : price;
            final goturFinalPrice = goturPrice > 0 ? goturPrice : null;

            final description = (data['aciklama'] ?? data['description'] ?? '')
                .toString()
                .trim();

            final title = (data['ad'] ?? data['urunAdi'] ?? 'Ev Galeri Ürünü')
                .toString()
                .trim();

            final canAddToCart =
                gelAlFinalPrice > 0 || (goturFinalPrice ?? 0) > 0;

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
              decoration: BoxDecoration(
                color: const Color(0xFF111111),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(20),
                ),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
              child: Row(
                children: [
                  if (isAdmin) ...[
                    InkWell(
                      borderRadius: BorderRadius.circular(999),
                      onTap: () => _editPrice(context, ref, price),
                      child: Container(
                        width: 30,
                        height: 30,
                        margin: const EdgeInsets.only(right: 6),
                        decoration: const BoxDecoration(
                          color: gold,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.edit_rounded,
                          color: Colors.black,
                          size: 17,
                        ),
                      ),
                    ),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title.isEmpty ? 'Ev Galeri Ürünü' : title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Wrap(
                          spacing: 5,
                          runSpacing: 4,
                          children: [
                            _priceChip(
                              label: 'Gel-Al',
                              price: gelAlFinalPrice,
                            ),
                            _priceChip(
                              label: 'Götür',
                              price: goturFinalPrice ?? 0,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'İncele',
                    iconSize: 18,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 30,
                      minHeight: 30,
                    ),
                    icon: const Icon(Icons.visibility, color: Colors.white),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => UrunDetaySayfasi(
                            urunAdi: title.isEmpty ? 'Ev Galeri Ürünü' : title,
                            urunFiyat: gelAlFinalPrice.toStringAsFixed(0),
                            urunGorsel: imageUrl,
                            aciklama: description,
                            dukkanAdi: dukkanAdi,
                            konum: '',
                            youtubeUrl: '',
                            urunGorseller: [imageUrl],
                            productId: ref.id,
                            sellerId: sellerId,
                            kategori: 'Ev Lezzetleri',
                            gelAlFiyat: gelAlFinalPrice,
                            goturFiyat: goturFinalPrice,
                          ),
                        ),
                      );
                    },
                  ),
                  IconButton(
                    tooltip: 'Sepete ekle',
                    iconSize: 18,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 30,
                      minHeight: 30,
                    ),
                    icon: const Icon(
                      Icons.add_shopping_cart,
                      color: Colors.white,
                    ),
                    onPressed: !canAddToCart
                        ? null
                        : () async {
                            try {
                              final selected = await _selectDeliveryMode(
                                context: context,
                                gelAlFinalPrice: gelAlFinalPrice,
                                goturFinalPrice: goturFinalPrice,
                              );

                              if (selected == null) return;

                              final selectedTip = selected['tip'].toString();
                              final selectedPrice =
                                  _asDouble(selected['fiyat']);

                              if (selectedPrice <= 0) {
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Bu ürün için geçerli fiyat bulunamadı.',
                                    ),
                                  ),
                                );
                                return;
                              }

                              await SepetService.sepeteEkle(
                                urunId: '${ref.id}_$selectedTip',
                                urunAdi:
                                    title.isEmpty ? 'Ev Galeri Ürünü' : title,
                                dukkanAdi: dukkanAdi,
                                kategori: 'Ev Lezzetleri',
                                img: imageUrl,
                                fiyat: selectedPrice,
                                gelAlFiyat: gelAlFinalPrice,
                                goturFiyat: goturFinalPrice,
                                teslimatTipi: selectedTip,

                                // Ev Galeri’de görünen fiyat nihai müşteri fiyatıdır.
                                // Sepet/ödeme tekrar teslimat veya işlem ücreti bindirmemeli.
                                deliveryIncludedInPrice: true,
                                feeIncludedInPrice: true,

                                saticiId: sellerId,
                                dukkanId: sellerId,
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
                                const Duration(milliseconds: 450),
                              );

                              if (!context.mounted) return;

                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const SepetSayfasi(),
                                ),
                              );
                            } catch (e) {
                              if (!context.mounted) return;

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Sepete eklenemedi: $e'),
                                ),
                              );
                            }
                          },
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

    final nameController = TextEditingController(
      text: (data['ad'] ?? data['urunAdi'] ?? 'Ev Galeri Ürünü').toString(),
    );

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

    try {
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Galeri Ürün Bilgileri'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Ürün adı',
                    hintText: 'Örn: Mercimek çorbası',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: gelAlController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Gel-Al Fiyatı (₺)',
                    hintText: 'Örn: 120',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: goturController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Götür Fiyatı (₺)',
                    hintText: 'Örn: 150',
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
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal'),
            ),
            TextButton(
              onPressed: () async {
                final name = nameController.text.trim().isEmpty
                    ? 'Ev Galeri Ürünü'
                    : nameController.text.trim();

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
                  'ad': name,
                  'urunAdi': name,
                  'price': gelAl,
                  'fiyat': gelAl,
                  'gelAlFiyat': gelAl,
                  'goturFiyat': gotur,
                  'aciklama': desc,
                  'description': desc,

                  // Ev Galeri fiyatları nihai müşteri fiyatıdır.
                  'deliveryIncludedInPrice': true,
                  'feeIncludedInPrice': true,

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
    } finally {
      nameController.dispose();
      gelAlController.dispose();
      goturController.dispose();
      aciklamaController.dispose();
    }
  }
}
