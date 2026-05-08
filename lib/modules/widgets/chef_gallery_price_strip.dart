import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:sofrasofra_arena_v2/modules/widgets/chef_gallery_sales_bridge.dart';

class ChefGalleryPriceStrip extends StatelessWidget {
  final String chefId;
  final String imageUrl;

  const ChefGalleryPriceStrip({
    super.key,
    required this.chefId,
    required this.imageUrl,
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

  Widget _chip({
    required String label,
    required double price,
  }) {
    if (price <= 0) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
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

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentReference<Map<String, dynamic>>>(
      future: ChefGallerySalesBridge.ensureGalleryProduct(
        chefId: chefId,
        imageUrl: imageUrl,
      ),
      builder: (context, refSnap) {
        if (!refSnap.hasData) {
          return const SizedBox(height: 24);
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
              return const SizedBox(height: 24);
            }

            return SizedBox(
              height: 24,
              width: double.infinity,
              child: Align(
                alignment: Alignment.centerLeft,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _chip(
                        label: 'Gel-Al',
                        price: gelAlPrice,
                      ),
                      if (gelAlPrice > 0 && goturPrice > 0)
                        const SizedBox(width: 5),
                      _chip(
                        label: 'Götür',
                        price: goturPrice,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
