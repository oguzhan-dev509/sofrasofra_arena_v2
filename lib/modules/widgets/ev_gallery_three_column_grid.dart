import 'package:flutter/material.dart';
import 'package:sofrasofra_arena_v2/modules/widgets/ev_gallery_sales_bridge.dart';

class EvGalleryThreeColumnGrid extends StatelessWidget {
  const EvGalleryThreeColumnGrid({
    super.key,
    required this.images,
    required this.selectedIndex,
    required this.canManageMedia,
    this.showSalesActions = true,
    required this.productId,
    required this.sellerId,
    required this.dukkanAdi,
    this.selectedAddons = const <Map<String, dynamic>>[],
    this.addonsTotal = 0,
    required this.onSelected,
  });

  final List<String> images;
  final int selectedIndex;
  final bool canManageMedia;
  final bool showSalesActions;
  final String productId;
  final String sellerId;
  final String dukkanAdi;
  final List<Map<String, dynamic>> selectedAddons;
  final num addonsTotal;
  final ValueChanged<int> onSelected;

  static const Color _gold = Color(0xFFFFB300);
  static const Color _border = Color(0x22FFFFFF);
  static const Color _textMuted = Color(0xFF9CA3AF);

  @override
  Widget build(BuildContext context) {
    if (images.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final gap = MediaQuery.of(context).size.width < 600 ? 10.0 : 14.0;
        final imageHeight =
            MediaQuery.of(context).size.width < 600 ? 150.0 : 215.0;

        const columns = 3;

        final itemWidth =
            ((constraints.maxWidth - (gap * (columns - 1))) / columns)
                .clamp(90.0, 360.0)
                .toDouble();

        final rowCount = (images.length / columns).ceil();

        return Column(
          children: List.generate(rowCount, (rowIndex) {
            final startIndex = rowIndex * columns;

            return Padding(
              padding: EdgeInsets.only(
                bottom: rowIndex == rowCount - 1 ? 0 : gap,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: List.generate(columns, (columnIndex) {
                  final index = startIndex + columnIndex;

                  if (index >= images.length) {
                    return Padding(
                      padding: EdgeInsets.only(
                        right: columnIndex == columns - 1 ? 0 : gap,
                      ),
                      child: SizedBox(width: itemWidth),
                    );
                  }

                  final imageUrl = images[index];
                  final isSelected = index == selectedIndex;

                  return Padding(
                    padding: EdgeInsets.only(
                      right: columnIndex == columns - 1 ? 0 : gap,
                    ),
                    child: SizedBox(
                      width: itemWidth,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GestureDetector(
                            onTap: () => onSelected(index),
                            child: SizedBox(
                              width: itemWidth,
                              height: imageHeight,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(22),
                                  border: Border.all(
                                    color: isSelected ? _gold : _border,
                                    width: isSelected ? 3 : 1.2,
                                  ),
                                  color: const Color(0xFF111111),
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color:
                                                _gold.withValues(alpha: 0.28),
                                            blurRadius: 18,
                                            offset: const Offset(0, 8),
                                          ),
                                        ]
                                      : const [],
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(3),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(18),
                                    child: Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        Image.network(
                                          imageUrl,
                                          fit: BoxFit.cover,
                                          gaplessPlayback: true,
                                          filterQuality: FilterQuality.medium,
                                          loadingBuilder: (
                                            context,
                                            child,
                                            loadingProgress,
                                          ) {
                                            if (loadingProgress == null) {
                                              return child;
                                            }

                                            return Container(
                                              color: const Color(0xFF111111),
                                              alignment: Alignment.center,
                                              child: const SizedBox(
                                                width: 18,
                                                height: 18,
                                                child:
                                                    CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  color: _gold,
                                                ),
                                              ),
                                            );
                                          },
                                          errorBuilder: (_, __, ___) =>
                                              Container(
                                            color: const Color(0xFF151515),
                                            alignment: Alignment.center,
                                            child: const Icon(
                                              Icons
                                                  .image_not_supported_outlined,
                                              color: _textMuted,
                                              size: 22,
                                            ),
                                          ),
                                        ),
                                        if (canManageMedia)
                                          Positioned(
                                            left: 8,
                                            top: 8,
                                            child: InkWell(
                                              borderRadius:
                                                  BorderRadius.circular(999),
                                              onTap: () async {
                                                onSelected(index);

                                                if (productId.isEmpty ||
                                                    sellerId.isEmpty ||
                                                    imageUrl.trim().isEmpty) {
                                                  ScaffoldMessenger.of(context)
                                                      .showSnackBar(
                                                    const SnackBar(
                                                      content: Text(
                                                        'Galeri ürünü için eksik bilgi var.',
                                                      ),
                                                      backgroundColor:
                                                          Colors.redAccent,
                                                    ),
                                                  );
                                                  return;
                                                }

                                                final ref =
                                                    await EvGallerySalesBridge
                                                        .ensureGalleryProduct(
                                                  ownerProductId: productId,
                                                  sellerId: sellerId,
                                                  dukkanAdi: dukkanAdi,
                                                  imageUrl: imageUrl,
                                                );

                                                if (!context.mounted) return;

                                                await EvGallerySalesBridge
                                                    .editGalleryProductInfo(
                                                  context: context,
                                                  ref: ref,
                                                  current: 0,
                                                );
                                              },
                                              child: Container(
                                                width: 34,
                                                height: 34,
                                                decoration: BoxDecoration(
                                                  color: _gold.withValues(
                                                    alpha: 0.96,
                                                  ),
                                                  shape: BoxShape.circle,
                                                  border: Border.all(
                                                    color:
                                                        Colors.black.withValues(
                                                      alpha: 0.22,
                                                    ),
                                                  ),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.black
                                                          .withValues(
                                                        alpha: 0.35,
                                                      ),
                                                      blurRadius: 8,
                                                      offset:
                                                          const Offset(0, 3),
                                                    ),
                                                  ],
                                                ),
                                                child: const Icon(
                                                  Icons.edit_rounded,
                                                  color: Colors.black,
                                                  size: 18,
                                                ),
                                              ),
                                            ),
                                          ),
                                        if (isSelected)
                                          Positioned(
                                            right: 8,
                                            top: 8,
                                            child: Container(
                                              padding: const EdgeInsets.all(6),
                                              decoration: BoxDecoration(
                                                color: Colors.black.withValues(
                                                  alpha: 0.65,
                                                ),
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color: _gold.withValues(
                                                    alpha: 0.75,
                                                  ),
                                                ),
                                              ),
                                              child: const Icon(
                                                Icons.check_rounded,
                                                color: _gold,
                                                size: 18,
                                              ),
                                            ),
                                          ),
                                        Positioned(
                                          left: 8,
                                          bottom: 8,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 5,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.black.withValues(
                                                alpha: 0.65,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(999),
                                            ),
                                            child: Text(
                                              '${index + 1}/${images.length}',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 11,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          if (showSalesActions) ...[
                            const SizedBox(height: 8),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 6),
                              child: EvGallerySalesActions(
                                ownerProductId: productId,
                                sellerId: sellerId,
                                dukkanAdi: dukkanAdi,
                                imageUrl: imageUrl,
                                selectedAddons: selectedAddons,
                                addonsTotal: addonsTotal,
                                isAdmin: false,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }),
              ),
            );
          }),
        );
      },
    );
  }
}
