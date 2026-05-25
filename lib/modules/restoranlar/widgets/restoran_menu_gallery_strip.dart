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
  });

  final RestoranMenuItemModel item;
  final bool canManage;
  final bool busy;
  final VoidCallback? onAddGalleryPhoto;
  final ValueChanged<String>? onDeleteGalleryPhoto;

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

        final cardHeight = isCompact ? 150.0 : 220.0;

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
                          width: 210,
                          height: cardHeight,
                          child: _GalleryPhotoCard(
                            imageUrl: imageUrl,
                            images: galleryImages,
                            index: index,
                            isGalleryImage: isGalleryImage,
                            canManage: canManage,
                            busy: busy,
                            onDeleteGalleryPhoto: onDeleteGalleryPhoto,
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
  });

  final String imageUrl;
  final List<String> images;
  final int index;
  final bool isGalleryImage;
  final bool canManage;
  final bool busy;
  final ValueChanged<String>? onDeleteGalleryPhoto;

  static const Color _gold = Color(0xFFFFB300);

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: index == 0
                    ? _gold.withValues(alpha: 0.70)
                    : Colors.white.withValues(alpha: 0.16),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.34),
                  blurRadius: 16,
                  offset: const Offset(0, 9),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
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
        ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.center,
                colors: [
                  Colors.black.withValues(alpha: 0.52),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        Positioned(
          right: 10,
          bottom: 10,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 9,
              vertical: 5,
            ),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.58),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.16),
              ),
            ),
            child: Text(
              '${index + 1}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w900,
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
                color: Colors.black.withValues(alpha: 0.68),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.22),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.30),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.zoom_in_rounded,
                color: Colors.white,
                size: 19,
              ),
            ),
          ),
        ),
        if (canManage && isGalleryImage && onDeleteGalleryPhoto != null)
          Positioned(
            top: -7,
            right: -7,
            child: InkWell(
              onTap: busy
                  ? null
                  : () {
                      onDeleteGalleryPhoto?.call(imageUrl);
                    },
              borderRadius: BorderRadius.circular(999),
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.84),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _gold.withValues(alpha: 0.80),
                  ),
                ),
                child: const Icon(
                  Icons.close,
                  size: 16,
                  color: Colors.white,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
