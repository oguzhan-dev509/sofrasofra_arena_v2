import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

typedef RestaurantAddonSelectionChanged = void Function(
  List<Map<String, dynamic>> selectedAddons,
  num addonsTotal,
);

class RestaurantAddonPicker extends StatefulWidget {
  const RestaurantAddonPicker({
    super.key,
    required this.restaurantId,
    this.onSelectionChanged,
  });

  final String restaurantId;
  final RestaurantAddonSelectionChanged? onSelectionChanged;
  @override
  State<RestaurantAddonPicker> createState() => _RestaurantAddonPickerState();
}

class _RestaurantAddonPickerState extends State<RestaurantAddonPicker> {
  final Map<String, int> _quantities = {};

  static const Color _gold = Color(0xFFFFB300);
  void _notifySelection(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> addons,
  ) {
    final selectedAddons = <Map<String, dynamic>>[];
    num addonsTotal = 0;

    for (final doc in addons) {
      final quantity = _quantities[doc.id] ?? 0;

      if (quantity <= 0) continue;

      final data = doc.data();
      final price = data['price'];
      final stockStatus =
          (data['stockStatus'] ?? data['stokDurumu'] ?? 'in_stock')
              .toString()
              .trim();

      final isOrderable = stockStatus == 'in_stock' ||
          stockStatus == 'stokta' ||
          stockStatus == 'Stokta';

      if (!isOrderable) continue;
      if (price is! num || price <= 0) continue;

      final total = price * quantity;

      selectedAddons.add({
        'addonId': doc.id,
        'name': (data['name'] ?? '').toString().trim(),
        'description': (data['description'] ?? '').toString().trim(),
        'category': (data['category'] ?? '').toString().trim(),
        'price': price,
        'quantity': quantity,
        'total': total,
      });

      addonsTotal += total;
    }

    widget.onSelectionChanged?.call(selectedAddons, addonsTotal);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('restaurants')
          .doc(widget.restaurantId)
          .collection('addon_items')
          .where('isActive', isEqualTo: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          debugPrint('RESTAURANT ADDON PICKER ERROR => ${snapshot.error}');

          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.redAccent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.redAccent),
            ),
            child: Text(
              'Ek ürünler okunamadı: ${snapshot.error}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox.shrink();
        }

        final addons = snapshot.data!.docs.where((doc) {
          final data = doc.data();
          final name = (data['name'] ?? '').toString().trim();
          final price = data['price'];

          return name.isNotEmpty && price is num && price > 0;
        }).toList()
          ..sort((a, b) {
            final aOrderRaw = a.data()['sortOrder'];
            final bOrderRaw = b.data()['sortOrder'];

            final aOrder = aOrderRaw is num
                ? aOrderRaw.toInt()
                : int.tryParse(aOrderRaw?.toString() ?? '') ?? 999;

            final bOrder = bOrderRaw is num
                ? bOrderRaw.toInt()
                : int.tryParse(bOrderRaw?.toString() ?? '') ?? 999;

            return aOrder.compareTo(bOrder);
          });

        if (addons.isEmpty) {
          return const SizedBox.shrink();
        }

        return Container(
          margin: const EdgeInsets.only(
            left: 4,
            right: 4,
            bottom: 22,
            top: 8,
          ),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF121212),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.10),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.add_circle_outline,
                    color: _gold,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Yanına Ekleyebileceklerin',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ...addons.map((doc) {
                final data = doc.data();
                final name = (data['name'] ?? '').toString().trim();
                final description =
                    (data['description'] ?? '').toString().trim();
                final price = data['price'] as num;

                final priceText = price % 1 == 0
                    ? price.toStringAsFixed(0)
                    : price.toStringAsFixed(2);

                final quantity = _quantities[doc.id] ?? 0;
                final stockStatus =
                    (data['stockStatus'] ?? data['stokDurumu'] ?? 'in_stock')
                        .toString()
                        .trim();

                final isOrderable = stockStatus == 'in_stock' ||
                    stockStatus == 'stokta' ||
                    stockStatus == 'Stokta';

                final stockLabel = stockStatus == 'sold_out' ||
                        stockStatus == 'stok_tukendi' ||
                        stockStatus == 'Stok tükendi'
                    ? 'Stok tükendi'
                    : stockStatus == 'temporarily_off' ||
                            stockStatus == 'gecici_pasif' ||
                            stockStatus == 'Geçici pasif'
                        ? 'Geçici pasif'
                        : '';
                return Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            if (description.isNotEmpty) ...[
                              const SizedBox(height: 3),
                              Text(
                                description,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.62),
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '$priceText TL',
                            style: const TextStyle(
                              color: _gold,
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _AddonQuantityButton(
                                icon: Icons.remove,
                                enabled: quantity > 0,
                                onTap: () {
                                  if (quantity <= 0) return;

                                  setState(() {
                                    final nextQuantity = quantity - 1;

                                    if (nextQuantity <= 0) {
                                      _quantities.remove(doc.id);
                                    } else {
                                      _quantities[doc.id] = nextQuantity;
                                    }

                                    _notifySelection(addons);
                                  });
                                },
                              ),
                              Container(
                                width: 30,
                                alignment: Alignment.center,
                                child: Text(
                                  '$quantity',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                              _AddonQuantityButton(
                                icon: Icons.add,
                                enabled: true,
                                onTap: () {
                                  setState(() {
                                    _quantities[doc.id] = quantity + 1;
                                    _notifySelection(addons);
                                  });
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }
}

class _AddonQuantityButton extends StatelessWidget {
  const _AddonQuantityButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  static const Color _gold = Color(0xFFFFB300);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 28,
        height: 28,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: enabled
              ? _gold.withValues(alpha: 0.16)
              : Colors.white.withValues(alpha: 0.05),
          shape: BoxShape.circle,
          border: Border.all(
            color: enabled
                ? _gold.withValues(alpha: 0.70)
                : Colors.white.withValues(alpha: 0.10),
          ),
        ),
        child: Icon(
          icon,
          size: 16,
          color: enabled ? _gold : Colors.white.withValues(alpha: 0.30),
        ),
      ),
    );
  }
}
