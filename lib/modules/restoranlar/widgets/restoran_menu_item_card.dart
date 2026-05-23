import 'package:flutter/material.dart';

import '../models/restoran_menu_item_model.dart';

class RestoranMenuItemCard extends StatelessWidget {
  const RestoranMenuItemCard({
    super.key,
    required this.item,
    required this.onGelAlTap,
    required this.onGoturTap,
  });

  final RestoranMenuItemModel item;
  final VoidCallback onGelAlTap;
  final VoidCallback onGoturTap;

  static const Color _gold = Color(0xFFFFB300);
  static const Color _panel = Color(0xFF111111);
  static const Color _panelSoft = Color(0xFF171717);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _panelSoft.withValues(alpha: 0.96),
            _panel.withValues(alpha: 0.98),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: item.isFeatured
              ? _gold.withValues(alpha: 0.38)
              : Colors.white.withValues(alpha: 0.11),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.32),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 520;

          if (isCompact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _MenuImage(
                  item: item,
                  height: 190,
                  width: double.infinity,
                ),
                _MenuContent(
                  item: item,
                  onGelAlTap: onGelAlTap,
                  onGoturTap: onGoturTap,
                ),
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _MenuImage(
                item: item,
                width: 156,
                height: 172,
              ),
              Expanded(
                child: _MenuContent(
                  item: item,
                  onGelAlTap: onGelAlTap,
                  onGoturTap: onGoturTap,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _MenuImage extends StatelessWidget {
  const _MenuImage({
    required this.item,
    required this.width,
    required this.height,
  });

  final RestoranMenuItemModel item;
  final double width;
  final double height;

  static const Color _gold = Color(0xFFFFB300);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          item.imageForUi.isEmpty
              ? const _ImageFallback()
              : Image.network(
                  item.imageForUi,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const _ImageFallback();
                  },
                ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.02),
                  Colors.black.withValues(alpha: 0.44),
                ],
              ),
            ),
          ),
          if (item.isFeatured)
            Positioned(
              top: 10,
              left: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.62),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: _gold.withValues(alpha: 0.42),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.workspace_premium,
                      color: _gold,
                      size: 13,
                    ),
                    SizedBox(width: 5),
                    Text(
                      'Öne çıkan',
                      style: TextStyle(
                        color: _gold,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MenuContent extends StatelessWidget {
  const _MenuContent({
    required this.item,
    required this.onGelAlTap,
    required this.onGoturTap,
  });

  final RestoranMenuItemModel item;
  final VoidCallback onGelAlTap;
  final VoidCallback onGoturTap;

  static const Color _gold = Color(0xFFFFB300);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(15, 14, 15, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              height: 1.08,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            item.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12.8,
              height: 1.36,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            item.priceText,
            style: const TextStyle(
              color: _gold,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _MiniBadge(
                label: item.category,
                icon: Icons.category_outlined,
              ),
              _MiniBadge(
                label: '${item.preparationMinutes} dk',
                icon: Icons.timer_outlined,
              ),
            ],
          ),
          const SizedBox(height: 13),
          Wrap(
            spacing: 9,
            runSpacing: 9,
            children: [
              _ActionPill(
                label: 'Gel-Al ${item.gelAlFiyat.toStringAsFixed(0)} TL',
                icon: Icons.shopping_bag_outlined,
                isPrimary: true,
                onTap: onGelAlTap,
              ),
              _ActionPill(
                label: 'Götür ${item.goturFiyat.toStringAsFixed(0)} TL',
                icon: Icons.delivery_dining_outlined,
                isPrimary: false,
                onTap: onGoturTap,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionPill extends StatelessWidget {
  const _ActionPill({
    required this.label,
    required this.icon,
    required this.isPrimary,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isPrimary;
  final VoidCallback onTap;

  static const Color _gold = Color(0xFFFFB300);

  @override
  Widget build(BuildContext context) {
    final borderColor =
        isPrimary ? _gold.withValues(alpha: 0.50) : Colors.white24;
    final backgroundColor = isPrimary
        ? _gold.withValues(alpha: 0.15)
        : Colors.white.withValues(alpha: 0.075);
    final textColor = isPrimary ? _gold : Colors.white;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 13,
            vertical: 9,
          ),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: textColor,
                size: 15,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: textColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ImageFallback extends StatelessWidget {
  const _ImageFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF202020),
      alignment: Alignment.center,
      child: const Icon(
        Icons.restaurant_menu,
        color: Colors.white38,
        size: 38,
      ),
    );
  }
}

class _MiniBadge extends StatelessWidget {
  const _MiniBadge({
    required this.label,
    required this.icon,
  });

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.12),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: Colors.white60,
            size: 13,
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
