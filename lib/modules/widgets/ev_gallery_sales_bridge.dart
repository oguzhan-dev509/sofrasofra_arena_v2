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

  static Future<void> editGalleryProductInfo({
    required BuildContext context,
    required DocumentReference<Map<String, dynamic>> ref,
    required double current,
  }) async {
    final snap = await ref.get();
    final data = snap.data() ?? {};

    if (!context.mounted) return;

    String name =
        (data['ad'] ?? data['urunAdi'] ?? 'Ev Galeri Ürünü').toString();

    String gelAlText =
        (data['gelAlFiyat'] ?? data['price'] ?? data['fiyat'] ?? current)
            .toString();

    String goturText = (data['goturFiyat'] ?? '').toString();

    String desc = (data['aciklama'] ?? data['description'] ?? '').toString();

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Galeri Ürün Bilgileri'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  initialValue: name,
                  decoration: const InputDecoration(
                    labelText: 'Ürün adı',
                    hintText: 'Örn: Mercimek çorbası',
                  ),
                  onChanged: (value) {
                    name = value;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  initialValue: gelAlText,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Gel-Al Fiyatı (₺)',
                    hintText: 'Örn: 120',
                  ),
                  onChanged: (value) {
                    gelAlText = value;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  initialValue: goturText,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Götür Fiyatı (₺)',
                    hintText: 'Örn: 150',
                  ),
                  onChanged: (value) {
                    goturText = value;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  initialValue: desc,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Tarif / Açıklama',
                    hintText: 'Ürün açıklaması',
                  ),
                  onChanged: (value) {
                    desc = value;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(null);
              },
              child: const Text('İptal'),
            ),
            TextButton(
              onPressed: () {
                final cleanName =
                    name.trim().isEmpty ? 'Ev Galeri Ürünü' : name.trim();

                final gelAl = double.tryParse(
                      gelAlText.trim().replaceAll(',', '.'),
                    ) ??
                    0;

                final gotur = double.tryParse(
                      goturText.trim().replaceAll(',', '.'),
                    ) ??
                    0;

                Navigator.of(dialogContext).pop({
                  'ad': cleanName,
                  'urunAdi': cleanName,
                  'price': gelAl,
                  'fiyat': gelAl,
                  'gelAlFiyat': gelAl,
                  'goturFiyat': gotur,
                  'aciklama': desc.trim(),
                  'description': desc.trim(),
                  'deliveryIncludedInPrice': true,
                  'feeIncludedInPrice': true,
                  'updatedAt': FieldValue.serverTimestamp(),
                });
              },
              child: const Text('Kaydet'),
            ),
          ],
        );
      },
    );

    if (result == null) return;
    if (!context.mounted) return;

    try {
      await ref.set(result, SetOptions(merge: true));

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Galeri ürün bilgileri kaydedildi.'),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Kaydedilemedi: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
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
                      onTap: () => EvGallerySalesBridge.editGalleryProductInfo(
                        context: context,
                        ref: ref,
                        current: price,
                      ),
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
                    icon: const Icon(
                      Icons.visibility,
                      color: Colors.white,
                    ),
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
                                  backgroundColor: Colors.redAccent,
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

    if (!context.mounted) return;

    String name =
        (data['ad'] ?? data['urunAdi'] ?? 'Ev Galeri Ürünü').toString();

    String gelAlText =
        (data['gelAlFiyat'] ?? data['price'] ?? data['fiyat'] ?? current)
            .toString();

    String goturText = (data['goturFiyat'] ?? '').toString();

    String desc = (data['aciklama'] ?? data['description'] ?? '').toString();

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Galeri Ürün Bilgileri'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  initialValue: name,
                  decoration: const InputDecoration(
                    labelText: 'Ürün adı',
                    hintText: 'Örn: Mercimek çorbası',
                  ),
                  onChanged: (value) {
                    name = value;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  initialValue: gelAlText,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Gel-Al Fiyatı (₺)',
                    hintText: 'Örn: 120',
                  ),
                  onChanged: (value) {
                    gelAlText = value;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  initialValue: goturText,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Götür Fiyatı (₺)',
                    hintText: 'Örn: 150',
                  ),
                  onChanged: (value) {
                    goturText = value;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  initialValue: desc,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Tarif / Açıklama',
                    hintText: 'Ürün açıklaması',
                  ),
                  onChanged: (value) {
                    desc = value;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(null);
              },
              child: const Text('İptal'),
            ),
            TextButton(
              onPressed: () {
                final cleanName =
                    name.trim().isEmpty ? 'Ev Galeri Ürünü' : name.trim();

                final gelAl = double.tryParse(
                      gelAlText.trim().replaceAll(',', '.'),
                    ) ??
                    0;

                final gotur = double.tryParse(
                      goturText.trim().replaceAll(',', '.'),
                    ) ??
                    0;

                Navigator.of(dialogContext).pop({
                  'ad': cleanName,
                  'urunAdi': cleanName,
                  'price': gelAl,
                  'fiyat': gelAl,
                  'gelAlFiyat': gelAl,
                  'goturFiyat': gotur,
                  'aciklama': desc.trim(),
                  'description': desc.trim(),
                  'deliveryIncludedInPrice': true,
                  'feeIncludedInPrice': true,
                  'updatedAt': FieldValue.serverTimestamp(),
                });
              },
              child: const Text('Kaydet'),
            ),
          ],
        );
      },
    );

    if (result == null) return;
    if (!context.mounted) return;

    try {
      await ref.set(
        result,
        SetOptions(merge: true),
      );

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Galeri ürün bilgileri kaydedildi.'),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Kaydedilemedi: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }
}
