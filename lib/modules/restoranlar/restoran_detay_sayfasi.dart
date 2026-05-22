import 'package:flutter/material.dart';

import 'models/restoran_model.dart';
import 'widgets/restoran_status_badge.dart';

class RestoranDetaySayfasi extends StatelessWidget {
  const RestoranDetaySayfasi({
    super.key,
    required this.restaurant,
  });

  final RestoranModel restaurant;

  static const Color _gold = Color(0xFFFFB300);
  static const Color _bg = Color(0xFF050505);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: _gold),
        title: const Text(
          'RESTORAN DETAYI',
          style: TextStyle(
            color: _gold,
            fontSize: 13,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 34),
        children: [
          _CoverSection(restaurant: restaurant),
          const SizedBox(height: 18),
          _InfoSection(restaurant: restaurant),
          const SizedBox(height: 18),
          _LaunchNotice(restaurant: restaurant),
          const SizedBox(height: 18),
          _MenuPreviewSection(),
        ],
      ),
    );
  }
}

class _CoverSection extends StatelessWidget {
  const _CoverSection({required this.restaurant});

  final RestoranModel restaurant;

  static const Color _gold = Color(0xFFFFB300);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 280,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: _gold.withValues(alpha: 0.22),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.42),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            restaurant.imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: const Color(0xFF202020),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.restaurant_menu,
                  color: Colors.white38,
                  size: 54,
                ),
              );
            },
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.08),
                  Colors.black.withValues(alpha: 0.80),
                ],
              ),
            ),
          ),
          Positioned(
            left: 18,
            right: 18,
            bottom: 18,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                const RestoranStatusBadge(
                  label: 'Kurucu Restoran',
                  icon: Icons.workspace_premium,
                  isGold: true,
                ),
                RestoranStatusBadge(
                  label: restaurant.launchStatusText,
                  icon: Icons.lock_clock,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  const _InfoSection({required this.restaurant});

  final RestoranModel restaurant;

  static const Color _gold = Color(0xFFFFB300);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.045),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: _gold.withValues(alpha: 0.20),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            restaurant.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              height: 1.12,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            restaurant.description,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14.5,
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              RestoranStatusBadge(
                label: restaurant.cuisine,
                icon: Icons.local_dining,
              ),
              RestoranStatusBadge(
                label: restaurant.locationText,
                icon: Icons.location_on_outlined,
              ),
              RestoranStatusBadge(
                label: restaurant.serviceText,
                icon: Icons.shopping_bag_outlined,
                isGold: true,
              ),
              RestoranStatusBadge(
                label: restaurant.preparationText,
                icon: Icons.timer_outlined,
              ),
              RestoranStatusBadge(
                label: restaurant.ratingText,
                icon: Icons.star_rounded,
                isGold: true,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LaunchNotice extends StatelessWidget {
  const _LaunchNotice({required this.restaurant});

  final RestoranModel restaurant;

  static const Color _gold = Color(0xFFFFB300);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _gold.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: _gold.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline,
            color: _gold,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '${restaurant.name} için siparişler lansman döneminde aktif edilecek. '
              'Bu sayfa restoran menüsü, servis modeli ve müşteri deneyimi için hazırlık ekranıdır.',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13.8,
                height: 1.45,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuPreviewSection extends StatelessWidget {
  static const Color _gold = Color(0xFFFFB300);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.10),
        ),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Menü altyapısı hazırlanıyor',
            style: TextStyle(
              color: _gold,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 10),
          Text(
            'Bir sonraki aşamada restoran ürünleri, menü kategorileri, Gel-Al / Götür fiyatları ve sepete hazır ürün modeli bu alana bağlanacak.',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
