import 'package:flutter/material.dart';

import '../models/restoran_menu_item_model.dart';

class RestoranMenuGalleryStrip extends StatelessWidget {
  const RestoranMenuGalleryStrip({
    super.key,
    required this.item,
  });

  final RestoranMenuItemModel item;

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

    addUrl(item.img);

    for (final imageUrl in item.images) {
      addUrl(imageUrl);
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    final galleryImages = _galleryImages;

    if (galleryImages.length <= 1) {
      return const SizedBox.shrink();
    }

    final visibleImages = galleryImages.take(4).toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.24),
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withValues(alpha: 0.08),
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 7,
            ),
            decoration: BoxDecoration(
              color: _gold.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: _gold.withValues(alpha: 0.38),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.photo_library_outlined,
                  color: _gold,
                  size: 14,
                ),
                const SizedBox(width: 6),
                Text(
                  '${galleryImages.length} fotoğraf',
                  style: const TextStyle(
                    color: _gold,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: visibleImages.length,
                separatorBuilder: (context, index) {
                  return const SizedBox(width: 8);
                },
                itemBuilder: (context, index) {
                  final imageUrl = visibleImages[index];

                  return Container(
                    width: 56,
                    height: 44,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: index == 0
                            ? _gold.withValues(alpha: 0.62)
                            : Colors.white.withValues(alpha: 0.14),
                      ),
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
                            size: 18,
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
