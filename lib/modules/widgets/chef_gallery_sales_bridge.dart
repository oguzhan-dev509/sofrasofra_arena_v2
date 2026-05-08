import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sofrasofra_arena_v2/cart/sepet_sayfasi.dart';
import 'package:sofrasofra_arena_v2/services/sepet_service.dart';

class ChefGallerySalesBridge {
  /// Galeri fotoğrafı için urunler kaydı yoksa oluşturur, varsa döner.
  static Future<DocumentReference<Map<String, dynamic>>> ensureGalleryProduct({
    required String chefId,
    required String imageUrl,
  }) async {
    final col = FirebaseFirestore.instance.collection('urunler');

    final q = await col
        .where('img', isEqualTo: imageUrl)
        .where('dukkanId', isEqualTo: chefId)
        .limit(1)
        .get();

    if (q.docs.isNotEmpty) {
      return q.docs.first.reference;
    }

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
      'gelAlFiyat': 0,
      'goturFiyat': 0,
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

/// Fotoğrafın üstünde / alt köşesinde gösterilecek fiyat etiketi.
/// Önemli: IgnorePointer ile tıklama alanlarını engellemez.
class ChefGalleryPriceOverlay extends StatelessWidget {
  static const Color gold = Color(0xFFFFB300);
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

    return double.tryParse(
          value.toString().trim().replaceAll(',', '.'),
        ) ??
        0;
  }

  Widget _inlinePriceChip({
    required String label,
    required double price,
  }) {
    if (price <= 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 7,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.48),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: gold.withValues(alpha: 0.38),
        ),
      ),
      child: Text(
        '$label ${price.toStringAsFixed(0)} ₺',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9.5,
          fontWeight: FontWeight.w900,
          height: 1,
        ),
      ),
    );
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
          color: const Color(0xFFFFB300).withValues(alpha: 0.45),
        ),
      ),
      child: Text(
        '$label $text',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9.5,
          fontWeight: FontWeight.w900,
          height: 1,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: true,
      child: FutureBuilder<DocumentReference<Map<String, dynamic>>>(
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

              if (gelAlPrice <= 0 && goturPrice <= 0) {
                return const SizedBox.shrink();
              }

              return Align(
                alignment: Alignment.bottomLeft,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(7, 0, 7, 7),
                  child: Wrap(
                    spacing: 5,
                    runSpacing: 4,
                    children: [
                      _priceChip(
                        label: 'Gel-Al',
                        value: gelAlPrice,
                      ),
                      if (goturPrice > 0)
                        _priceChip(
                          label: 'Götür',
                          value: goturPrice,
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

/// Galeri kartının altındaki güvenli aksiyon barı.
/// Mobilde overflow üretmemesi için alt barda sadece:
/// - admin/satıcı için kalem
/// - herkes için sepet
/// bırakıldı.
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

  static const Color gold = Color(0xFFFFB300);

  double _asDouble(dynamic value) {
    if (value == null) return 0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();

    return double.tryParse(
          value.toString().trim().replaceAll(',', '.'),
        ) ??
        0;
  }

  Future<void> _openAddToCartFlow({
    required BuildContext context,
    required DocumentReference<Map<String, dynamic>> ref,
    required String title,
    required double price,
    required double gelAlPrice,
    required double goturPrice,
  }) async {
    debugPrint(
      '### CHEF GALERI SEPET CLICK | ref=${ref.id} | '
      'isAdmin=$isAdmin | chefId=$chefId | '
      'price=$price | gelAl=$gelAlPrice | gotur=$goturPrice | '
      'imageUrl=$imageUrl',
    );

    if (gelAlPrice <= 0 && price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bu galeri ürünü için Gel-Al veya fiyat bilgisi yok.'),
        ),
      );
      return;
    }

    final gelAlFinalPrice = gelAlPrice > 0 ? gelAlPrice : price;
    final goturFinalPrice = goturPrice > 0 ? goturPrice : null;

    final selected = await showModalBottomSheet<Map<String, dynamic>>(
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
                  'Teslimat tercihi seçin',
                  style: TextStyle(
                    color: gold,
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

    if (selected == null) return;

    final selectedTip = selected['tip'].toString();
    final selectedPrice = selected['fiyat'] as double;

    try {
      debugPrint(
        '### CHEF GALERI ADD START | ref=${ref.id} | '
        'chefId=$chefId | selectedTip=$selectedTip | '
        'selectedPrice=$selectedPrice',
      );

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

      debugPrint(
        '### CHEF GALERI ADD OK | ref=${ref.id} | '
        'selectedTip=$selectedTip | selectedPrice=$selectedPrice',
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
        const Duration(milliseconds: 350),
      );

      if (!context.mounted) return;

      Navigator.of(context, rootNavigator: true).push(
        MaterialPageRoute(
          builder: (_) => const SepetSayfasi(),
        ),
      );
    } catch (e, st) {
      debugPrint('### CHEF GALERI ADD ERROR | $e');
      debugPrint('$st');

      if (!context.mounted) return;

      final isDifferentSellerError = e.toString().contains(
            'Aynı anda yalnızca tek satıcıdan',
          );

      if (!isDifferentSellerError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sepete eklenemedi: $e'),
          ),
        );
        return;
      }

      final shouldClearCart = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text('Sepette başka satıcı var'),
            content: const Text(
              'Sepetinizde başka bir satıcının ürünü var. '
              'Bu ürünü eklemek için mevcut sepeti boşaltıp bu satıcıdan devam edelim mi?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Vazgeç'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Sepeti Boşalt ve Devam Et'),
              ),
            ],
          );
        },
      );

      if (shouldClearCart != true) return;

      try {
        await SepetService.sepetiBosalt();

        debugPrint(
          '### CHEF GALERI CART CLEARED | retry add | ref=${ref.id} | '
          'chefId=$chefId | selectedTip=$selectedTip',
        );

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
                  ? 'Sepet yenilendi, Götür fiyatı ile eklendi'
                  : 'Sepet yenilendi, Gel-Al fiyatı ile eklendi',
            ),
          ),
        );

        await Future<void>.delayed(
          const Duration(milliseconds: 350),
        );

        if (!context.mounted) return;

        Navigator.of(context, rootNavigator: true).push(
          MaterialPageRoute(
            builder: (_) => const SepetSayfasi(),
          ),
        );
      } catch (retryError, retryStack) {
        debugPrint('### CHEF GALERI RETRY ADD ERROR | $retryError');
        debugPrint('$retryStack');

        if (!context.mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sepet yenilendi ama ürün eklenemedi: $retryError'),
          ),
        );
      }
    }
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

            final price = _asDouble(data['price'] ?? data['fiyat']);
            final gelAlPrice = _asDouble(
              data['gelAlFiyat'] ?? data['price'] ?? data['fiyat'],
            );
            final goturPrice = _asDouble(data['goturFiyat']);

            final title = (data['ad'] ?? data['urunAdi'] ?? 'Şef Galeri Ürünü')
                .toString();

            Widget inlinePriceChip({
              required String label,
              required double price,
            }) {
              if (price <= 0) return const SizedBox.shrink();

              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 7,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.48),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: gold.withValues(alpha: 0.38),
                  ),
                ),
                child: Text(
                  '$label ${price.toStringAsFixed(0)} ₺',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
              );
            }

            return Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 7,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.84),
                    Colors.black.withValues(alpha: 0.08),
                  ],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (gelAlPrice > 0 || goturPrice > 0)
                    SizedBox(
                      height: 18,
                      width: double.infinity,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            inlinePriceChip(
                              label: 'Gel-Al',
                              price: gelAlPrice,
                            ),
                            if (gelAlPrice > 0 && goturPrice > 0)
                              const SizedBox(width: 5),
                            inlinePriceChip(
                              label: 'Götür',
                              price: goturPrice,
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (gelAlPrice > 0 || goturPrice > 0)
                    const SizedBox(height: 1),
                  SizedBox(
                    height: 27,
                    width: double.infinity,
                    child: Row(
                      children: [
                        if (isAdmin)
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => _editPrice(context, ref, price),
                            child: SizedBox(
                              width: 32,
                              height: 27,
                              child: Center(
                                child: Container(
                                  width: 25,
                                  height: 25,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: gold,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.35,
                                        ),
                                        blurRadius: 8,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.edit_rounded,
                                    color: Colors.black,
                                    size: 14,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        const Spacer(),
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => _openAddToCartFlow(
                            context: context,
                            ref: ref,
                            title: title,
                            price: price,
                            gelAlPrice: gelAlPrice,
                            goturPrice: goturPrice,
                          ),
                          child: const SizedBox(
                            width: 34,
                            height: 27,
                            child: Center(
                              child: Icon(
                                Icons.add_shopping_cart,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                        ),
                      ],
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
