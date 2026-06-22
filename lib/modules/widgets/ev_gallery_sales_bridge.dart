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
        'isGalleryProduct': true,
        'hiddenFromCatalog': true,
        'ownerProductId': ownerProductId,
        'parentProductId': ownerProductId,
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
      await ref.set({
        ...result,
        'source': 'ev_gallery',
        'orderSource': 'ev_gallery',
        'isGalleryProduct': true,
        'hiddenFromCatalog': true,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

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
  final List<Map<String, dynamic>> selectedAddons;
  final num addonsTotal;
  final bool isAdmin;

  const EvGallerySalesActions({
    super.key,
    required this.ownerProductId,
    required this.sellerId,
    required this.dukkanAdi,
    required this.imageUrl,
    this.selectedAddons = const <Map<String, dynamic>>[],
    this.addonsTotal = 0,
    this.isAdmin = false,
  });

  double _asDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();

    final raw = value.toString().trim().replaceAll(',', '.');
    return double.tryParse(raw) ?? 0;
  }

  Widget _priceChip({
    required String label,
    required double price,
  }) {
    if (price <= 0) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: const Color(0xFFFFB300).withValues(alpha: 0.75),
        ),
      ),
      child: Text(
        '$label ${price.toStringAsFixed(0)} ₺',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        softWrap: false,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10.5,
          fontWeight: FontWeight.w900,
          height: 1,
        ),
      ),
    );
  }

  Widget _smallGalleryIconButton({
    required String tooltip,
    required IconData icon,
    required VoidCallback? onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: SizedBox(
          width: 28,
          height: 28,
          child: Icon(
            icon,
            color: onTap == null ? Colors.white38 : Colors.white,
            size: 21,
          ),
        ),
      ),
    );
  }

  Future<Map<String, dynamic>?> _selectDeliveryMode({
    required BuildContext context,
    required double gelAlFinalPrice,
    required double? goturFinalPrice,
  }) async {
    return showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      backgroundColor: const Color(0xFF101010),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
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
                  'Teslimat seç',
                  style: TextStyle(
                    color: Color(0xFFFFB300),
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
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
                    Navigator.of(sheetContext).pop({
                      'tip': 'gel_al',
                      'fiyat': gelAlFinalPrice,
                    });
                  },
                ),
                if (goturFinalPrice != null && goturFinalPrice > 0)
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
                      Navigator.of(sheetContext).pop({
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

    final ref = EvGallerySalesBridge.galleryProductRef(
      ownerProductId: ownerProductId,
      sellerId: sellerId,
      dukkanAdi: dukkanAdi,
      imageUrl: imageUrl,
    );

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: ref.snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data() ?? <String, dynamic>{};

        final gelAlFinalPrice = _asDouble(
          data['gelAlFiyat'] ?? data['price'] ?? data['fiyat'],
        );

        final goturRaw = data['goturFiyat'];
        final goturFinalPrice = goturRaw == null ? null : _asDouble(goturRaw);

        final title = (data['ad'] ?? data['urunAdi'] ?? 'Ev Galeri Ürünü')
            .toString()
            .trim();

        final description =
            (data['aciklama'] ?? data['description'] ?? '').toString();

        final canAddToCart = gelAlFinalPrice > 0 || (goturFinalPrice ?? 0) > 0;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 7),
          decoration: BoxDecoration(
            color: const Color(0xFF111111),
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(20),
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (gelAlFinalPrice > 0 || (goturFinalPrice ?? 0) > 0)
                Row(
                  children: [
                    if (gelAlFinalPrice > 0)
                      Expanded(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.center,
                          child: _priceChip(
                            label: 'Gel-Al',
                            price: gelAlFinalPrice,
                          ),
                        ),
                      ),
                    if (gelAlFinalPrice > 0 && (goturFinalPrice ?? 0) > 0)
                      const SizedBox(width: 6),
                    if ((goturFinalPrice ?? 0) > 0)
                      Expanded(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.center,
                          child: _priceChip(
                            label: 'Götür',
                            price: goturFinalPrice ?? 0,
                          ),
                        ),
                      ),
                  ],
                ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _smallGalleryIconButton(
                    tooltip: 'İncele',
                    icon: Icons.visibility,
                    onTap: () {
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
                  const SizedBox(width: 6),
                  _smallGalleryIconButton(
                    tooltip: 'Sepete ekle',
                    icon: Icons.add_shopping_cart,
                    onTap: !canAddToCart
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

                              final safeAddonsTotal = addonsTotal > 0
                                  ? addonsTotal.toDouble()
                                  : 0.0;

                              final cartPrice = selectedPrice + safeAddonsTotal;

                              final addonSignature = selectedAddons.isEmpty
                                  ? 'no_addons'
                                  : selectedAddons.map((addon) {
                                      final addonId = (addon['addonId'] ?? '')
                                          .toString()
                                          .trim();
                                      final quantity = addon['quantity'] ?? 0;

                                      return '${addonId}_$quantity';
                                    }).join('_');

                              debugPrint(
                                'EV ADDON CART DEBUG '
                                'selectedPrice=$selectedPrice '
                                'addonsTotal=$safeAddonsTotal '
                                'cartPrice=$cartPrice '
                                'addons=${selectedAddons.length} '
                                'signature=$addonSignature',
                              );

                              await SepetService.sepeteEkle(
                                urunId:
                                    '${ref.id}_${selectedTip}_$addonSignature',
                                urunAdi:
                                    title.isEmpty ? 'Ev Galeri Ürünü' : title,
                                dukkanAdi: dukkanAdi,
                                kategori: 'Ev Lezzetleri',
                                img: imageUrl,

                                // Müşterinin ödeyeceği ana ürün + yan ürün toplamı.
                                fiyat: cartPrice,

                                // Gel-Al/Götür temel fiyatlarını değiştirmiyoruz.
                                // Kurye farkının doğru kalması için yan ürün yalnızca addonsTotal ile taşınır.
                                gelAlFiyat: gelAlFinalPrice,
                                goturFiyat: goturFinalPrice,
                                teslimatTipi: selectedTip,

                                deliveryIncludedInPrice: true,
                                feeIncludedInPrice: true,

                                saticiId: sellerId,
                                dukkanId: sellerId,
                                selectedAddons: selectedAddons,
                                addonsTotal: safeAddonsTotal,
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
                                const Duration(milliseconds: 250),
                              );

                              if (!context.mounted) return;

                              Navigator.of(context, rootNavigator: true).push(
                                MaterialPageRoute(
                                  builder: (_) => const SepetSayfasi(),
                                ),
                              );
                            } catch (e) {
                              if (!context.mounted) return;

                              final message = e.toString();
                              final isSingleSellerConflict =
                                  message.contains('tek satıcı') ||
                                      message.contains('yalnızca tek satıcı') ||
                                      message.contains('Aynı anda');

                              final messenger = ScaffoldMessenger.of(context);
                              messenger.clearSnackBars();

                              if (isSingleSellerConflict) {
                                messenger.showSnackBar(
                                  const SnackBar(
                                    duration: Duration(seconds: 2),
                                    backgroundColor: Colors.redAccent,
                                    content: Text(
                                      'Sepette başka bir satıcıdan ürün var. Sepetim açılıyor.',
                                    ),
                                  ),
                                );

                                await Future<void>.delayed(
                                  const Duration(milliseconds: 700),
                                );

                                if (!context.mounted) return;

                                Navigator.of(
                                  context,
                                  rootNavigator: true,
                                ).push(
                                  MaterialPageRoute(
                                    builder: (_) => const SepetSayfasi(),
                                  ),
                                );

                                return;
                              }

                              messenger.showSnackBar(
                                SnackBar(
                                  duration: const Duration(seconds: 4),
                                  backgroundColor: Colors.redAccent,
                                  content: Text('Sepete eklenemedi: $e'),
                                ),
                              );
                            }
                          },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
