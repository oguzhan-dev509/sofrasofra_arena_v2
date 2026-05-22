import 'package:flutter/material.dart';
import 'widgets/restoran_premium_card.dart';

class PremiumRestoranVitrini extends StatelessWidget {
  const PremiumRestoranVitrini({super.key});

  static const Color _gold = Color(0xFFFFB300);
  static const Color _bg = Color(0xFF050505);

  static const List<Map<String, String>> _demoRestaurants = [
    {
      'name': 'Mahalle Ocakbaşı',
      'description':
          'Kebap, ızgara ve günlük sıcak yemekleriyle mahalle lezzetini Sofrasofra standardında sunar.',
      'imageUrl': 'https://images.unsplash.com/photo-1555396273-367ea4eb4db5',
      'cuisine': 'Kebap & Izgara',
      'district': 'Güngören',
      'preparation': '25-35 dk',
      'rating': '4.8 ★',
    },
    {
      'name': 'Butik Esnaf Lokantası',
      'description':
          'Günlük tencere yemekleri, çorba, pilav ve ev sıcaklığında restoran menüsü.',
      'imageUrl':
          'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4',
      'cuisine': 'Esnaf Lokantası',
      'district': 'Kadıköy',
      'preparation': '20-30 dk',
      'rating': '4.9 ★',
    },
    {
      'name': 'Sofra Pide & Lahmacun',
      'description':
          'Taş fırın lezzetleri, mahalleye özel hızlı hazırlık ve kurucu restoran avantajı.',
      'imageUrl':
          'https://images.unsplash.com/photo-1565299624946-b28f40a0ae38',
      'cuisine': 'Pide & Lahmacun',
      'district': 'Fatih',
      'preparation': '18-28 dk',
      'rating': '4.7 ★',
    },
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
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 32),
        children: [
          _HeroBlock(),
          const SizedBox(height: 20),
          ..._demoRestaurants.map(
            (restaurant) => RestoranPremiumCard(
              name: restaurant['name'] ?? '',
              description: restaurant['description'] ?? '',
              imageUrl: restaurant['imageUrl'] ?? '',
              cuisine: restaurant['cuisine'] ?? '',
              district: restaurant['district'] ?? '',
              preparationText: restaurant['preparation'] ?? '',
              ratingText: restaurant['rating'] ?? '',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Restoran siparişleri lansman döneminde aktif edilecek.',
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroBlock extends StatelessWidget {
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
