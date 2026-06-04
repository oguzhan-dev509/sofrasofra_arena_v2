import 'package:flutter/material.dart';
import '../../fullscreen_gallery.dart';
import '../models/restoran_menu_item_model.dart';
import 'restoran_menu_gallery_strip.dart';

class RestoranMenuItemCard extends StatelessWidget {
  const RestoranMenuItemCard({
    super.key,
    required this.item,
    required this.onGelAlTap,
    required this.onGoturTap,
    this.canManageMedia = false,
    this.onAddPhotoTap,
    this.onDeletePhotoTap,
    this.onAddGalleryPhotoTap,
    this.onDeleteGalleryPhotoTap,
    this.onEditMenuItemTap,
    this.onAddProfilePhotoTap,
    this.onDeleteProfilePhotoTap,
  });

  final RestoranMenuItemModel item;
  final ValueChanged<String> onGelAlTap;
  final ValueChanged<String> onGoturTap;
  final bool canManageMedia;
  final VoidCallback? onAddPhotoTap;
  final VoidCallback? onDeletePhotoTap;
  final VoidCallback? onAddGalleryPhotoTap;
  final ValueChanged<String>? onDeleteGalleryPhotoTap;
  final VoidCallback? onAddProfilePhotoTap;
  final VoidCallback? onDeleteProfilePhotoTap;
  final ValueChanged<String>? onEditMenuItemTap;

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
            onAddProfilePhotoTap: onAddProfilePhotoTap,
            onDeleteProfilePhotoTap: onDeleteProfilePhotoTap,
          ),
          RestoranMenuGalleryStrip(
            item: item,
            canManage: canManageMedia,
            onAddGalleryPhoto: onAddGalleryPhotoTap,
            onDeleteGalleryPhoto: onDeleteGalleryPhotoTap,
            onEditMenuItemTap: onEditMenuItemTap,
            onGelAlTap: onGelAlTap,
            onGoturTap: onGoturTap,
          ),
          _PremiumContent(item: item),
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
    required this.onAddProfilePhotoTap,
    required this.onDeleteProfilePhotoTap,
  });

  final RestoranMenuItemModel item;
  final bool canManageMedia;
  final VoidCallback? onAddPhotoTap;
  final VoidCallback? onDeletePhotoTap;
  final VoidCallback? onAddProfilePhotoTap;
  final VoidCallback? onDeleteProfilePhotoTap;
  @override
  Widget build(BuildContext context) {
    final galleryImages = <String>[
      if (item.img.trim().isNotEmpty) item.img.trim(),
      ...item.images.map((url) => url.trim()).where((url) => url.isNotEmpty),
    ];

    final heroImageUrl = galleryImages.isNotEmpty ? galleryImages.first : '';

    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Stack(
        fit: StackFit.expand,
        children: [
          heroImageUrl.isEmpty
              ? const _ImageFallback()
              : GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => FullScreenGallery(
                          images: galleryImages,
                          initialIndex: 0,
                        ),
                      ),
                    );
                  },
                  child: Image.network(
                    heroImageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const _ImageFallback();
                    },
                  ),
                ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.00),
                  Colors.black.withValues(alpha: 0.12),
                  Colors.black.withValues(alpha: 0.48),
                ],
                stops: const [0.0, 0.55, 1.0],
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
                color: Colors.black.withValues(alpha: 0.42),
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
            left: 18,
            bottom: 70,
            child: _ProfileAvatarOverlay(
              imageUrl: item.profileImg,
              canManageMedia: canManageMedia,
              onAddProfilePhotoTap: onAddProfilePhotoTap,
              onDeleteProfilePhotoTap: onDeleteProfilePhotoTap,
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

class _PremiumContent extends StatelessWidget {
  const _PremiumContent({
    required this.item,
  });

  final RestoranMenuItemModel item;

  @override
  Widget build(BuildContext context) {
    final description = item.description.trim();

    if (description.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(17, 13, 17, 17),
      child: Text(
        description,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 13.5,
          height: 1.38,
          fontWeight: FontWeight.w600,
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

class _ProfileAvatarOverlay extends StatelessWidget {
  const _ProfileAvatarOverlay({
    required this.imageUrl,
    required this.canManageMedia,
    required this.onAddProfilePhotoTap,
    required this.onDeleteProfilePhotoTap,
  });

  final String imageUrl;
  final bool canManageMedia;
  final VoidCallback? onAddProfilePhotoTap;
  final VoidCallback? onDeleteProfilePhotoTap;

  static const Color _gold = Color(0xFFFFB300);

  @override
  Widget build(BuildContext context) {
    final cleanUrl = imageUrl.trim();
    final hasImage = cleanUrl.isNotEmpty;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 82,
          height: 82,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.black.withValues(alpha: 0.50),
            border: Border.all(
              color: _gold.withValues(alpha: 0.72),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.34),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: hasImage
              ? Image.network(
                  cleanUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const _ProfileAvatarFallback();
                  },
                )
              : const _ProfileAvatarFallback(),
        ),
        if (canManageMedia)
          Positioned(
            right: -6,
            bottom: -6,
            child: InkWell(
              onTap: onAddProfilePhotoTap,
              borderRadius: BorderRadius.circular(999),
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.84),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _gold.withValues(alpha: 0.78),
                  ),
                ),
                child: const Icon(
                  Icons.add_a_photo_outlined,
                  color: _gold,
                  size: 16,
                ),
              ),
            ),
          ),
        if (canManageMedia && hasImage && onDeleteProfilePhotoTap != null)
          Positioned(
            right: -6,
            top: -6,
            child: InkWell(
              onTap: onDeleteProfilePhotoTap,
              borderRadius: BorderRadius.circular(999),
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.86),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.redAccent.withValues(alpha: 0.72),
                  ),
                ),
                child: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 15,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _ProfileAvatarFallback extends StatelessWidget {
  const _ProfileAvatarFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF171717),
      alignment: Alignment.center,
      child: const Icon(
        Icons.restaurant_menu,
        color: Colors.white54,
        size: 34,
      ),
    );
  }
}
