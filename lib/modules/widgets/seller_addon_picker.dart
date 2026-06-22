import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

typedef SellerAddonSelectionChanged = void Function(
  List<Map<String, dynamic>> selectedAddons,
  num addonsTotal,
);

class SellerAddonPicker extends StatefulWidget {
  const SellerAddonPicker({
    super.key,
    required this.sellerId,
    this.onSelectionChanged,
  });

  final String sellerId;
  final SellerAddonSelectionChanged? onSelectionChanged;

  @override
  State<SellerAddonPicker> createState() => _SellerAddonPickerState();
}

class _SellerAddonPickerState extends State<SellerAddonPicker> {
  static const String _sharedAddonSellerId = 'zeynep_ev_lezzetleri';
  static const Color _gold = Color(0xFFFFB300);

  final Map<String, int> _quantities = {};

  Stream<QuerySnapshot<Map<String, dynamic>>> _addonStream(
    String sellerId,
  ) {
    return FirebaseFirestore.instance
        .collection('sellers')
        .doc(sellerId)
        .collection('addon_items')
        .where('isActive', isEqualTo: true)
        .snapshots();
  }

  String _quantityKey(
    String sourceSellerId,
    String addonId,
  ) {
    return '$sourceSellerId/$addonId';
  }

  bool _isOrderable(
    Map<String, dynamic> data,
  ) {
    final stockStatus =
        (data['stockStatus'] ?? data['stokDurumu'] ?? 'in_stock')
            .toString()
            .trim();

    return stockStatus == 'in_stock' ||
        stockStatus == 'stokta' ||
        stockStatus == 'Stokta';
  }

  String _stockLabel(
    Map<String, dynamic> data,
  ) {
    final stockStatus =
        (data['stockStatus'] ?? data['stokDurumu'] ?? 'in_stock')
            .toString()
            .trim();

    if (stockStatus == 'sold_out' ||
        stockStatus == 'stok_tukendi' ||
        stockStatus == 'Stok tükendi') {
      return 'Stok tükendi';
    }

    if (stockStatus == 'temporarily_off' ||
        stockStatus == 'gecici_pasif' ||
        stockStatus == 'Geçici pasif') {
      return 'Geçici pasif';
    }

    return '';
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _validAddons(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    final addons = snapshot.docs.where((doc) {
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
            : int.tryParse(
                  aOrderRaw?.toString() ?? '',
                ) ??
                999;

        final bOrder = bOrderRaw is num
            ? bOrderRaw.toInt()
            : int.tryParse(
                  bOrderRaw?.toString() ?? '',
                ) ??
                999;

        final orderCompare = aOrder.compareTo(bOrder);

        if (orderCompare != 0) {
          return orderCompare;
        }

        final aName = (a.data()['name'] ?? '').toString();

        final bName = (b.data()['name'] ?? '').toString();

        return aName.compareTo(bName);
      });

    return addons;
  }

  void _notifySelection(
    String sourceSellerId,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> addons,
  ) {
    final selectedAddons = <Map<String, dynamic>>[];
    num addonsTotal = 0;

    for (final doc in addons) {
      final key = _quantityKey(
        sourceSellerId,
        doc.id,
      );

      final quantity = _quantities[key] ?? 0;

      if (quantity <= 0) {
        continue;
      }

      final data = doc.data();
      final price = data['price'];

      if (!_isOrderable(data)) {
        continue;
      }

      if (price is! num || price <= 0) {
        continue;
      }

      final total = price * quantity;

      selectedAddons.add({
        'addonId': doc.id,
        'addonSellerId': sourceSellerId,
        'name': (data['name'] ?? '').toString().trim(),
        'description': (data['description'] ?? '').toString().trim(),
        'category': (data['category'] ?? '').toString().trim(),
        'price': price,
        'quantity': quantity,
        'total': total,
      });

      addonsTotal += total;
    }

    widget.onSelectionChanged?.call(
      selectedAddons,
      addonsTotal,
    );
  }

  void _clearInactiveSourceSelections(
    String activeSourceSellerId,
  ) {
    final activePrefix = '$activeSourceSellerId/';

    final keysToRemove = _quantities.keys
        .where(
          (key) => !key.startsWith(activePrefix),
        )
        .toList();

    if (keysToRemove.isEmpty) {
      return;
    }

    for (final key in keysToRemove) {
      _quantities.remove(key);
    }
  }

  Widget _errorCard(
    Object? error,
  ) {
    debugPrint(
      'SELLER ADDON PICKER ERROR => $error',
    );

    return Container(
      margin: const EdgeInsets.only(
        bottom: 16,
      ),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.redAccent.withValues(
          alpha: 0.15,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.redAccent,
        ),
      ),
      child: Text(
        'Ek ürünler okunamadı: $error',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildAddonList({
    required String sourceSellerId,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> addons,
  }) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      _clearInactiveSourceSelections(
        sourceSellerId,
      );
    });

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
          color: Colors.white.withValues(
            alpha: 0.10,
          ),
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

            final description = (data['description'] ?? '').toString().trim();

            final price = data['price'] as num;

            final key = _quantityKey(
              sourceSellerId,
              doc.id,
            );

            final quantity = _quantities[key] ?? 0;

            final isOrderable = _isOrderable(data);

            final stockLabel = _stockLabel(data);

            final priceText = price % 1 == 0
                ? price.toStringAsFixed(0)
                : price.toStringAsFixed(2);

            return Container(
              margin: const EdgeInsets.only(
                top: 8,
              ),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(
                  alpha: 0.05,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withValues(
                    alpha: 0.08,
                  ),
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
                          const SizedBox(
                            height: 3,
                          ),
                          Text(
                            description,
                            style: TextStyle(
                              color: Colors.white.withValues(
                                alpha: 0.62,
                              ),
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                        if (stockLabel.isNotEmpty) ...[
                          const SizedBox(
                            height: 5,
                          ),
                          Text(
                            stockLabel,
                            style: const TextStyle(
                              color: Colors.redAccent,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
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
                              if (quantity <= 0) {
                                return;
                              }

                              setState(() {
                                final nextQuantity = quantity - 1;

                                if (nextQuantity <= 0) {
                                  _quantities.remove(key);
                                } else {
                                  _quantities[key] = nextQuantity;
                                }

                                _notifySelection(
                                  sourceSellerId,
                                  addons,
                                );
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
                            enabled: isOrderable,
                            onTap: () {
                              if (!isOrderable) {
                                return;
                              }

                              setState(() {
                                _quantities[key] = quantity + 1;

                                _notifySelection(
                                  sourceSellerId,
                                  addons,
                                );
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
  }

  Widget _buildSharedAddonFallback() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _addonStream(
        _sharedAddonSellerId,
      ),
      builder: (
        context,
        sharedSnapshot,
      ) {
        debugPrint(
          'SELLER ADDON SHARED SNAPSHOT '
          'requestedSellerId=${widget.sellerId} '
          'sourceSellerId=$_sharedAddonSellerId '
          'hasData=${sharedSnapshot.hasData} '
          'docs=${sharedSnapshot.data?.docs.length ?? 0} '
          'error=${sharedSnapshot.error}',
        );

        if (sharedSnapshot.hasError) {
          return _errorCard(
            sharedSnapshot.error,
          );
        }

        if (!sharedSnapshot.hasData) {
          return const SizedBox.shrink();
        }

        final sharedAddons = _validAddons(
          sharedSnapshot.data!,
        );

        if (sharedAddons.isEmpty) {
          return const SizedBox.shrink();
        }

        return _buildAddonList(
          sourceSellerId: _sharedAddonSellerId,
          addons: sharedAddons,
        );
      },
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final requestedSellerId = widget.sellerId.trim();

    debugPrint(
      'SELLER ADDON PICKER BUILD '
      'requestedSellerId=$requestedSellerId',
    );

    if (requestedSellerId.isEmpty) {
      return const SizedBox.shrink();
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _addonStream(
        requestedSellerId,
      ),
      builder: (
        context,
        ownSnapshot,
      ) {
        debugPrint(
          'SELLER ADDON OWN SNAPSHOT '
          'requestedSellerId=$requestedSellerId '
          'hasData=${ownSnapshot.hasData} '
          'docs=${ownSnapshot.data?.docs.length ?? 0} '
          'error=${ownSnapshot.error}',
        );

        if (ownSnapshot.hasError) {
          return _errorCard(
            ownSnapshot.error,
          );
        }

        if (!ownSnapshot.hasData) {
          return const SizedBox.shrink();
        }

        final ownAddons = _validAddons(
          ownSnapshot.data!,
        );

        if (ownAddons.isNotEmpty) {
          return _buildAddonList(
            sourceSellerId: requestedSellerId,
            addons: ownAddons,
          );
        }

        if (requestedSellerId == _sharedAddonSellerId) {
          return const SizedBox.shrink();
        }

        return _buildSharedAddonFallback();
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
  Widget build(
    BuildContext context,
  ) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 28,
        height: 28,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: enabled
              ? _gold.withValues(
                  alpha: 0.16,
                )
              : Colors.white.withValues(
                  alpha: 0.05,
                ),
          shape: BoxShape.circle,
          border: Border.all(
            color: enabled
                ? _gold.withValues(
                    alpha: 0.70,
                  )
                : Colors.white.withValues(
                    alpha: 0.10,
                  ),
          ),
        ),
        child: Icon(
          icon,
          size: 16,
          color: enabled
              ? _gold
              : Colors.white.withValues(
                  alpha: 0.30,
                ),
        ),
      ),
    );
  }
}
