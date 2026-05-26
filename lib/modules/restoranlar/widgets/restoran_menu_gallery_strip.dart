import 'package:flutter/material.dart';

import '../../fullscreen_gallery.dart';
import '../models/restoran_menu_item_model.dart';

class RestoranMenuGalleryStrip extends StatelessWidget {
  const RestoranMenuGalleryStrip({
    super.key,
    required this.item,
    this.canManage = false,
    this.busy = false,
    this.onAddGalleryPhoto,
    this.onDeleteGalleryPhoto,
    this.onEditMenuItemTap,
    this.onGelAlTap,
    this.onGoturTap,
  });

  final RestoranMenuItemModel item;
  final bool canManage;
  final bool busy;
  final VoidCallback? onAddGalleryPhoto;
  final ValueChanged<String>? onDeleteGalleryPhoto;
  final ValueChanged<String>? onEditMenuItemTap;
  final ValueChanged<String>? onGelAlTap;
  final ValueChanged<String>? onGoturTap;

  static const Color _gold = Color(0xFFFFB300);

  List<String> get _galleryImages {
    final seen = <String>{};
    final result = <String>[];

    void addUrl(String value) {
      final cleanUrl = value.trim();
      if (cleanUrl.isEmpty) return;
      if (seen.contains(cleanUrl)) return;

      seen.add(cleanUrl);
      result.add(cleanUrl);
    }

    for (final imageUrl in item.images) {
      addUrl(imageUrl);
    }

    return result;
  }

  Set<String> get _galleryOnlyImages {
    return item.images
        .map((url) => url.trim())
        .where((url) => url.isNotEmpty)
        .toSet();
  }

  @override
  Widget build(BuildContext context) {
    final galleryImages = _galleryImages;
    final galleryOnlyImages = _galleryOnlyImages;

    if (galleryImages.length <= 1 && !canManage) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 720;
        final visibleImages = galleryImages.take(6).toList();
        final cardHeight = isCompact ? 240.0 : 310.0;
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.28),
            border: Border(
              bottom: BorderSide(
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: _gold.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: _gold.withValues(alpha: 0.42),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.photo_library_outlined,
                          color: _gold,
                          size: 16,
                        ),
                        const SizedBox(width: 7),
                        Text(
                          '${galleryImages.length} fotoğraf',
                          style: const TextStyle(
                            color: _gold,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  if (canManage)
                    TextButton.icon(
                      onPressed: busy ? null : onAddGalleryPhoto,
                      icon: const Icon(
                        Icons.add_photo_alternate_outlined,
                        size: 18,
                      ),
                      label: const Text('Galeri Foto Ekle'),
                      style: TextButton.styleFrom(
                        foregroundColor: _gold,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        textStyle: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                ],
              ),
              if (visibleImages.isNotEmpty) ...[
                const SizedBox(height: 14),
                if (isCompact)
                  SizedBox(
                    height: cardHeight,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: visibleImages.length,
                      separatorBuilder: (context, index) {
                        return const SizedBox(width: 12);
                      },
                      itemBuilder: (context, index) {
                        final imageUrl = visibleImages[index];
                        final isGalleryImage =
                            galleryOnlyImages.contains(imageUrl);

                        return SizedBox(
                          width: 250,
                          height: cardHeight,
                          child: _GalleryPhotoCard(
                            imageUrl: imageUrl,
                            images: galleryImages,
                            index: index,
                            isGalleryImage: isGalleryImage,
                            canManage: canManage,
                            busy: busy,
                            onDeleteGalleryPhoto: onDeleteGalleryPhoto,
                            onEditMenuItemTap: onEditMenuItemTap,
                            gelAlFiyat: item.gelAlFiyatForImage(imageUrl),
                            goturFiyat: item.goturFiyatForImage(imageUrl),
                            onGelAlTap: onGelAlTap,
                            onGoturTap: onGoturTap,
                          ),
                        );
                      },
                    ),
                  )
                else
                  Wrap(
                    spacing: 14,
                    runSpacing: 14,
                    children: List.generate(visibleImages.length, (index) {
                      final imageUrl = visibleImages[index];
                      final isGalleryImage =
                          galleryOnlyImages.contains(imageUrl);

                      final contentWidth = constraints.maxWidth - 32;
                      final cardWidth = (contentWidth - 28) / 3;

                      return SizedBox(
                        width: cardWidth,
                        height: cardHeight,
                        child: _GalleryPhotoCard(
                          imageUrl: imageUrl,
                          images: galleryImages,
                          index: index,
                          isGalleryImage: isGalleryImage,
                          canManage: canManage,
                          busy: busy,
                          onDeleteGalleryPhoto: onDeleteGalleryPhoto,
                          onEditMenuItemTap: onEditMenuItemTap,
                          gelAlFiyat: item.gelAlFiyatForImage(imageUrl),
                          goturFiyat: item.goturFiyatForImage(imageUrl),
                          onGelAlTap: onGelAlTap,
                          onGoturTap: onGoturTap,
                        ),
                      );
                    }),
                  ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _GalleryPhotoCard extends StatelessWidget {
  const _GalleryPhotoCard({
    required this.imageUrl,
    required this.images,
    required this.index,
    required this.isGalleryImage,
    required this.canManage,
    required this.busy,
    required this.onDeleteGalleryPhoto,
    this.onEditMenuItemTap,
    required this.gelAlFiyat,
    required this.goturFiyat,
    required this.onGelAlTap,
    required this.onGoturTap,
  });

  final String imageUrl;
  final List<String> images;
  final int index;
  final bool isGalleryImage;
  final bool canManage;
  final bool busy;
  final ValueChanged<String>? onDeleteGalleryPhoto;
  final ValueChanged<String>? onEditMenuItemTap;
  final double gelAlFiyat;
  final double goturFiyat;
  final ValueChanged<String>? onGelAlTap;
  final ValueChanged<String>? onGoturTap;

  static const Color _gold = Color(0xFFFFB300);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: index == 0
              ? _gold.withValues(alpha: 0.70)
              : Colors.white.withValues(alpha: 0.16),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Column(
          children: [
            Expanded(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: const Color(0xFF202020),
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.image_not_supported_outlined,
                            color: Colors.white38,
                            size: 28,
                          ),
                        );
                      },
                    ),
                  ),
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.center,
                          colors: [
                            Colors.black.withValues(alpha: 0.20),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 10,
                    top: 10,
                    child: InkWell(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => FullScreenGallery(
                              images: images,
                              initialIndex: index,
                            ),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(999),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.62),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.18),
                          ),
                        ),
                        child: const Icon(
                          Icons.search,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                  if (canManage &&
                      isGalleryImage &&
                      onDeleteGalleryPhoto != null)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: InkWell(
                        onTap: busy
                            ? null
                            : () {
                                onDeleteGalleryPhoto?.call(imageUrl);
                              },
                        borderRadius: BorderRadius.circular(999),
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: const Color(0xFF2B1A1A),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.30),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.30),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.close_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            _GalleryCartActionBar(
              imageUrl: imageUrl,
              gelAlFiyat: gelAlFiyat,
              goturFiyat: goturFiyat,
              onGelAlTap: onGelAlTap,
              onGoturTap: onGoturTap,
              canManage: canManage,
              busy: busy,
              onEditMenuItemTap: onEditMenuItemTap,
            ),
          ],
        ),
      ),
    );
  }
}

class _GalleryCartActionBar extends StatelessWidget {
  const _GalleryCartActionBar({
    required this.imageUrl,
    required this.gelAlFiyat,
    required this.goturFiyat,
    required this.onGelAlTap,
    required this.onGoturTap,
    required this.canManage,
    required this.busy,
    this.onEditMenuItemTap,
  });

  final double gelAlFiyat;
  final double goturFiyat;
  final String imageUrl;
  final ValueChanged<String>? onGelAlTap;
  final ValueChanged<String>? onGoturTap;
  final bool canManage;
  final bool busy;
  final ValueChanged<String>? onEditMenuItemTap;

  @override
  Widget build(BuildContext context) {
    final showGelAl = onGelAlTap != null && gelAlFiyat > 0;
    final showGotur = onGoturTap != null && goturFiyat > 0;
    final showEdit = canManage && onEditMenuItemTap != null;

    if (!showEdit && !showGelAl && !showGotur) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 9),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1420).withValues(alpha: 0.96),
        border: Border(
          top: BorderSide(
            color: Colors.white.withValues(alpha: 0.08),
          ),
        ),
      ),
      child: Row(
        children: [
          if (showEdit) ...[
            _GalleryEditActionChip(
              onTap: busy
                  ? null
                  : () {
                      onEditMenuItemTap?.call(imageUrl);
                    },
            ),
            if (showGelAl || showGotur) const SizedBox(width: 7),
          ],
          if (showGelAl)
            Expanded(
              child: _GalleryCartActionChip(
                label: 'Gel-Al',
                price: '${gelAlFiyat.toStringAsFixed(0)} TL',
                icon: Icons.shopping_bag_outlined,
                isPrimary: true,
                onTap: () {
                  onGelAlTap?.call(imageUrl);
                },
              ),
            ),
          if (showGelAl && showGotur) const SizedBox(width: 7),
          if (showGotur)
            Expanded(
              child: _GalleryCartActionChip(
                label: 'Götür',
                price: '${goturFiyat.toStringAsFixed(0)} TL',
                icon: Icons.delivery_dining_outlined,
                isPrimary: false,
                onTap: () {
                  onGoturTap?.call(imageUrl);
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _GalleryEditActionChip extends StatelessWidget {
  const _GalleryEditActionChip({
    required this.onTap,
  });

  final VoidCallback? onTap;

  static const Color _gold = Color(0xFFFFB300);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.62),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: _gold.withValues(alpha: 0.78),
              width: 1.05,
            ),
          ),
          child: const Icon(
            Icons.edit_outlined,
            color: _gold,
            size: 18,
          ),
        ),
      ),
    );
  }
}

class _GalleryCartActionChip extends StatelessWidget {
  const _GalleryCartActionChip({
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
    final borderColor = isPrimary
        ? _gold.withValues(alpha: 0.72)
        : Colors.white.withValues(alpha: 0.22);

    final backgroundColor = isPrimary
        ? _gold.withValues(alpha: 0.13)
        : Colors.white.withValues(alpha: 0.06);

    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 15,
                color: isPrimary ? _gold : Colors.white,
              ),
              const SizedBox(width: 5),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    '$label  $price',
                    maxLines: 1,
                    style: TextStyle(
                      color: isPrimary ? _gold : Colors.white,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.15,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
