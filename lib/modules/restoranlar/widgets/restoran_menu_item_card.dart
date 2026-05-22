import 'package:flutter/material.dart';

import '../models/restoran_menu_item_model.dart';

class RestoranMenuItemCard extends StatelessWidget {
  const RestoranMenuItemCard({
    super.key,
    required this.item,
    required this.onTap,
  });

  final RestoranMenuItemModel item;
  final VoidCallback onTap;

  static const Color _gold = Color(0xFFFFB300);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.045),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: _gold.withValues(alpha: item.isFeatured ? 0.32 : 0.14),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 112,
            child: item.imageForUi.isEmpty
                ? Container(
                    color: const Color(0xFF202020),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.restaurant_menu,
                      color: Colors.white38,
                      size: 34,
                    ),
                  )
                : Image.network(
                    item.imageForUi,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: const Color(0xFF202020),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.restaurant_menu,
                          color: Colors.white38,
                          size: 34,
                        ),
                      );
                    },
                  ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(13, 12, 13, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      if (item.isFeatured)
                        const Icon(
                          Icons.workspace_premium,
                          color: _gold,
                          size: 18,
                        ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    item.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12.5,
                      height: 1.32,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 9),
                  Text(
                    item.priceText,
                    style: const TextStyle(
                      color: _gold,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${item.category} • ${item.preparationMinutes} dk',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      InkWell(
                        borderRadius: BorderRadius.circular(999),
                        onTap: onTap,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 11,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: _gold.withValues(alpha: 0.13),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: _gold.withValues(alpha: 0.36),
                            ),
                          ),
                          child: const Text(
                            'Lansmanda aktif',
                            style: TextStyle(
                              color: _gold,
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                    ],
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
