import 'package:flutter/material.dart';
import 'package:sofrasofra_arena_v2/services/restoran_service.dart';

import 'models/restoran_model.dart';
import 'restoran_detay_sayfasi.dart';
import 'widgets/restoran_premium_card.dart';

class PremiumRestoranVitrini extends StatelessWidget {
  const PremiumRestoranVitrini({super.key});

  static const Color _gold = Color(0xFFFFB300);
  static const Color _bg = Color(0xFF050505);

  static const List<RestoranModel> _demoRestaurants = [
    RestoranModel(
      id: 'mahalle_ocakbasi',
      name: 'Mahalle Ocakbaşı',
      description:
          'Kebap, ızgara ve günlük sıcak yemekleriyle mahalle lezzetini Sofrasofra standardında sunar.',
      imageUrl: 'https://images.unsplash.com/photo-1555396273-367ea4eb4db5',
      cuisine: 'Kebap & Izgara',
      city: 'İstanbul',
      district: 'Güngören',
      preparationText: '25-35 dk',
      ratingText: '4.8 ★',
      supportsGelAl: true,
      supportsGotur: true,
    ),
    RestoranModel(
      id: 'butik_esnaf_lokantasi',
      name: 'Butik Esnaf Lokantası',
      description:
          'Günlük tencere yemekleri, çorba, pilav ve ev sıcaklığında restoran menüsü.',
      imageUrl: 'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4',
      cuisine: 'Esnaf Lokantası',
      city: 'İstanbul',
      district: 'Kadıköy',
      preparationText: '20-30 dk',
      ratingText: '4.9 ★',
      supportsGelAl: true,
      supportsGotur: true,
    ),
    RestoranModel(
      id: 'sofra_pide_lahmacun',
      name: 'Sofra Pide & Lahmacun',
      description:
          'Taş fırın lezzetleri, mahalleye özel hızlı hazırlık ve kurucu restoran avantajı.',
      imageUrl: 'https://images.unsplash.com/photo-1565299624946-b28f40a0ae38',
      cuisine: 'Pide & Lahmacun',
      city: 'İstanbul',
      district: 'Fatih',
      preparationText: '18-28 dk',
      ratingText: '4.7 ★',
      supportsGelAl: true,
      supportsGotur: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: _gold),
        title: const Text(
          'RESTORANLAR',
          style: TextStyle(
            color: _gold,
            fontSize: 13,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
          ),
        ),
      ),
      body: StreamBuilder<List<RestoranModel>>(
        stream: RestoranService.streamRestaurantsForShowcase(),
        builder: (context, snapshot) {
          final firestoreRestaurants = snapshot.data ?? const <RestoranModel>[];

          final restaurants = firestoreRestaurants.isNotEmpty
              ? firestoreRestaurants
              : _demoRestaurants;

          final showFallbackNotice =
              snapshot.hasError || firestoreRestaurants.isEmpty;

          return ListView(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 32),
            children: [
              const _HeroBlock(),
              if (showFallbackNotice) ...[
                const SizedBox(height: 14),
                _FallbackNotice(
                  hasError: snapshot.hasError,
                ),
              ],
              const SizedBox(height: 20),
              ...restaurants.map(
                (restaurant) => RestoranPremiumCard(
                  name: restaurant.name,
                  description: restaurant.description,
                  imageUrl: restaurant.imageUrl,
                  cuisine: restaurant.cuisine,
                  district: restaurant.locationText,
                  preparationText: restaurant.preparationText,
                  ratingText: restaurant.ratingText,
                  serviceText: restaurant.serviceText,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => RestoranDetaySayfasi(
                          restaurant: restaurant,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _HeroBlock extends StatelessWidget {
  const _HeroBlock();

  static const Color _gold = Color(0xFFFFB300);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.045),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: _gold.withValues(alpha: 0.24),
        ),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Mahallenin restoranları Sofrasofra’da hazırlanıyor.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              height: 1.15,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 10),
          Text(
            'Butik restoranlar, esnaf lokantaları, aile işletmeleri ve yerel lezzet noktaları için premium dijital vitrin altyapısı.',
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

class _FallbackNotice extends StatelessWidget {
  const _FallbackNotice({
    required this.hasError,
  });

  final bool hasError;

  static const Color _gold = Color(0xFFFFB300);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _gold.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _gold.withValues(alpha: 0.24),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline,
            color: _gold,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              hasError
                  ? 'Restoran verileri şu anda okunamadı. Geliştirme önizlemesi gösteriliyor.'
                  : 'Firestore restoran verisi henüz eklenmedi. Geliştirme önizlemesi gösteriliyor.',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12.8,
                height: 1.35,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
