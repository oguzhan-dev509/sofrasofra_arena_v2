import 'package:flutter/material.dart';
import 'restoran_status_badge.dart';

class RestoranPremiumCard extends StatelessWidget {
  const RestoranPremiumCard({
    super.key,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.cuisine,
    required this.district,
    required this.preparationText,
    required this.ratingText,
    required this.serviceText,
    required this.isOpen,
    required this.onTap,
  });

  final String name;
  final String description;
  final String imageUrl;
  final String cuisine;
  final String district;
  final String preparationText;
  final String ratingText;
  final String serviceText;
  final bool isOpen;
  final VoidCallback onTap;
  static const Color _gold = Color(0xFFFFB300);
  static const Color _card = Color(0xFF151515);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 18),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: _gold.withValues(alpha: 0.20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.36),
              blurRadius: 22,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 16 / 8.5,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Positioned.fill(
                    child: imageUrl.trim().isEmpty
                        ? Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Color(0xFF05080D),
                                  Color(0xFF071018),
                                  Color(0xFF101820),
                                ],
                              ),
                            ),
                          )
                        : Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            filterQuality: FilterQuality.medium,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Color(0xFF05080D),
                                      Color(0xFF071018),
                                      Color(0xFF101820),
                                    ],
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: const Icon(
                                  Icons.restaurant_rounded,
                                  color: Colors.white24,
                                  size: 54,
                                ),
                              );
                            },
                          ),
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.05),
                          Colors.black.withValues(alpha: 0.72),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 14,
                    right: 14,
                    bottom: 14,
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        const RestoranStatusBadge(
                          label: 'Kurucu Restoran',
                          icon: Icons.workspace_premium,
                          isGold: true,
                        ),
                        const RestoranStatusBadge(
                          label: 'Lansmana Hazırlanıyor',
                          icon: Icons.lock_clock,
                        ),
                        RestoranStatusBadge(
                          label: isOpen ? 'Açık' : 'Kapalı',
                          icon: isOpen
                              ? Icons.check_circle_rounded
                              : Icons.cancel_rounded,
                          isGold: isOpen,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 15, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13.2,
                      height: 1.35,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 13),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (cuisine.trim().isNotEmpty)
                        RestoranStatusBadge(
                          label: cuisine,
                          icon: Icons.local_dining,
                        ),
                      if (district.trim().isNotEmpty)
                        RestoranStatusBadge(
                          label: district,
                          icon: Icons.location_on_outlined,
                        ),
                      if (serviceText.trim().isNotEmpty)
                        RestoranStatusBadge(
                          label: serviceText,
                          icon: Icons.shopping_bag_outlined,
                          isGold: true,
                        ),
                      if (preparationText.trim().isNotEmpty)
                        RestoranStatusBadge(
                          label: preparationText,
                          icon: Icons.timer_outlined,
                        ),
                      if (ratingText.trim().isNotEmpty)
                        RestoranStatusBadge(
                          label: ratingText,
                          icon: Icons.star_rounded,
                          isGold: true,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
