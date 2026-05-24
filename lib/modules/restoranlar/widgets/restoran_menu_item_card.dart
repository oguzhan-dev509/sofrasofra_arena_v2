import 'package:flutter/material.dart';

import '../models/restoran_menu_item_model.dart';

class RestoranMenuItemCard extends StatelessWidget {
  const RestoranMenuItemCard({
    super.key,
    required this.item,
    required this.onGelAlTap,
    required this.onGoturTap,
    this.canManageMedia = false,
    this.onAddPhotoTap,
    this.onDeletePhotoTap,
  });

  final RestoranMenuItemModel item;
  final VoidCallback onGelAlTap;
  final VoidCallback onGoturTap;
  final bool canManageMedia;
  final VoidCallback? onAddPhotoTap;
  final VoidCallback? onDeletePhotoTap;

  static const Color _gold = Color(0xFFFFB300);
  static const Color _cardBlack = Color(0xFF101010);
  static const Color _cardSoft = Color(0xFF181818);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _cardSoft.withValues(alpha: 0.98),
            _cardBlack.withValues(alpha: 0.99),
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: item.isFeatured
              ? _gold.withValues(alpha: 0.48)
              : Colors.white.withValues(alpha: 0.12),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.40),
            blurRadius: 28,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _HeroImage(
            item: item,
            canManageMedia: canManageMedia,
            onAddPhotoTap: onAddPhotoTap,
            onDeletePhotoTap: onDeletePhotoTap,
          ),
          _PriceStrip(item: item),
          _PremiumContent(
            item: item,
            onGelAlTap: onGelAlTap,
            onGoturTap: onGoturTap,
          ),
        ],
      ),
    );
  }
}

class _HeroImage extends StatelessWidget {
  const _HeroImage({
    required this.item,
    required this.canManageMedia,
    required this.onAddPhotoTap,
    required this.onDeletePhotoTap,
  });

  final RestoranMenuItemModel item;
  final bool canManageMedia;
  final VoidCallback? onAddPhotoTap;
  final VoidCallback? onDeletePhotoTap;
  static const Color _gold = Color(0xFFFFB300);

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 9,
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
                  Colors.black.withValues(alpha: 0.04),
                  Colors.black.withValues(alpha: 0.28),
                  Colors.black.withValues(alpha: 0.82),
                ],
                stops: const [0.0, 0.45, 1.0],
              ),
            ),
          ),
          Positioned(
            top: 14,
            left: 14,
            child: Row(
              children: [
                if (item.isFeatured)
                  const _HeroBadge(
                    label: 'Öne çıkan',
                    icon: Icons.workspace_premium,
                    isGold: true,
                  ),
                if (item.isFeatured) const SizedBox(width: 8),
                _HeroBadge(
                  label: item.category,
                  icon: Icons.restaurant_menu,
                  isGold: false,
                ),
              ],
            ),
          ),
          Positioned(
            right: 14,
            top: 14,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 11,
                vertical: 7,
              ),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.62),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.18),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.timer_outlined,
                    color: Colors.white,
                    size: 14,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    '${item.preparationMinutes} dk',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (canManageMedia)
            Positioned(
              right: 14,
              top: 58,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _MediaIconButton(
                    tooltip: 'Fotoğraf ekle / değiştir',
                    icon: Icons.add_photo_alternate_outlined,
                    onTap: onAddPhotoTap,
                  ),
                  const SizedBox(width: 8),
                  _MediaIconButton(
                    tooltip: 'Fotoğraf sil',
                    icon: Icons.delete_outline,
                    isDanger: true,
                    onTap: onDeletePhotoTap,
                  ),
                ],
              ),
            ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 15,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 23,
                    height: 1.05,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PriceStrip extends StatelessWidget {
  const _PriceStrip({
    required this.item,
  });

  final RestoranMenuItemModel item;

  static const Color _gold = Color(0xFFFFB300);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 13, 16, 12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.30),
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withValues(alpha: 0.08),
          ),
        ),
      ),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          _PriceChip(
            label: 'Gel-Al',
            price: '${item.gelAlFiyat.toStringAsFixed(0)} TL',
            icon: Icons.shopping_bag_outlined,
            isPrimary: true,
          ),
          _PriceChip(
            label: 'Götür',
            price: '${item.goturFiyat.toStringAsFixed(0)} TL',
            icon: Icons.delivery_dining_outlined,
            isPrimary: false,
          ),
        ],
      ),
    );
  }
}

class _PriceChip extends StatelessWidget {
  const _PriceChip({
    required this.label,
    required this.price,
    required this.icon,
    required this.isPrimary,
  });

  final String label;
  final String price;
  final IconData icon;
  final bool isPrimary;

  static const Color _gold = Color(0xFFFFB300);

  @override
  Widget build(BuildContext context) {
    final color = isPrimary ? _gold : Colors.white;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 9,
      ),
      decoration: BoxDecoration(
        color: isPrimary
            ? _gold.withValues(alpha: 0.13)
            : Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: isPrimary
              ? _gold.withValues(alpha: 0.45)
              : Colors.white.withValues(alpha: 0.16),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: color,
            size: 15,
          ),
          const SizedBox(width: 7),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            price,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _PremiumContent extends StatelessWidget {
  const _PremiumContent({
    required this.item,
    required this.onGelAlTap,
    required this.onGoturTap,
  });

  final RestoranMenuItemModel item;
  final VoidCallback onGelAlTap;
  final VoidCallback onGoturTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(17, 15, 17, 17),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (item.description.trim().isNotEmpty)
            Text(
              item.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13.5,
                height: 1.38,
                fontWeight: FontWeight.w600,
              ),
            ),
          if (item.description.trim().isNotEmpty) const SizedBox(height: 15),
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 390;

              if (isNarrow) {
                return Column(
                  children: [
                    _PremiumActionButton(
                      label: 'Gel-Al',
                      price: '${item.gelAlFiyat.toStringAsFixed(0)} TL',
                      icon: Icons.shopping_bag_outlined,
                      isPrimary: true,
                      onTap: onGelAlTap,
                    ),
                    const SizedBox(height: 10),
                    _PremiumActionButton(
                      label: 'Götür',
                      price: '${item.goturFiyat.toStringAsFixed(0)} TL',
                      icon: Icons.delivery_dining_outlined,
                      isPrimary: false,
                      onTap: onGoturTap,
                    ),
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(
                    child: _PremiumActionButton(
                      label: 'Gel-Al',
                      price: '${item.gelAlFiyat.toStringAsFixed(0)} TL',
                      icon: Icons.shopping_bag_outlined,
                      isPrimary: true,
                      onTap: onGelAlTap,
                    ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: _PremiumActionButton(
                      label: 'Götür',
                      price: '${item.goturFiyat.toStringAsFixed(0)} TL',
                      icon: Icons.delivery_dining_outlined,
                      isPrimary: false,
                      onTap: onGoturTap,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _PremiumActionButton extends StatelessWidget {
  const _PremiumActionButton({
    required this.label,
    required this.price,
    required this.icon,
    required this.isPrimary,
    required this.onTap,
  });

  final String label;
  final String price;
  final IconData icon;
  final bool isPrimary;
  final VoidCallback onTap;

  static const Color _gold = Color(0xFFFFB300);

  @override
  Widget build(BuildContext context) {
    final backgroundColor = isPrimary
        ? _gold.withValues(alpha: 0.18)
        : Colors.white.withValues(alpha: 0.075);
    final borderColor =
        isPrimary ? _gold.withValues(alpha: 0.56) : Colors.white24;
    final iconColor = isPrimary ? _gold : Colors.white;
    final labelColor = isPrimary ? _gold : Colors.white;
    final priceColor = isPrimary ? Colors.white : Colors.white70;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(
            minHeight: 58,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 13,
            vertical: 11,
          ),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.24),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.10),
                  ),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: labelColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      price,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: priceColor,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_rounded,
                color: iconColor.withValues(alpha: 0.86),
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroBadge extends StatelessWidget {
  const _HeroBadge({
    required this.label,
    required this.icon,
    required this.isGold,
  });

  final String label;
  final IconData icon;
  final bool isGold;

  static const Color _gold = Color(0xFFFFB300);

  @override
  Widget build(BuildContext context) {
    final color = isGold ? _gold : Colors.white;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: isGold
              ? _gold.withValues(alpha: 0.45)
              : Colors.white.withValues(alpha: 0.18),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: color,
            size: 14,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 11.5,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
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
        size: 46,
      ),
    );
  }
}

class _MediaIconButton extends StatelessWidget {
  const _MediaIconButton({
    required this.tooltip,
    required this.icon,
    required this.onTap,
    this.isDanger = false,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback? onTap;
  final bool isDanger;

  static const Color _gold = Color(0xFFFFB300);

  @override
  Widget build(BuildContext context) {
    final color = isDanger ? Colors.redAccent : _gold;

    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: onTap,
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.72),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: color.withValues(alpha: 0.55),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.30),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              icon,
              color: color,
              size: 19,
            ),
          ),
        ),
      ),
    );
  }
}
