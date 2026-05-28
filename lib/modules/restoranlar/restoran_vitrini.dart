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
      district: 'Üsküdar',
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
              _HeroBlock(
                onPremiumTap: restaurants.isEmpty
                    ? null
                    : () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => RestoranDetaySayfasi(
                              restaurant: restaurants.first,
                            ),
                          ),
                        );
                      },
              ),
              const SizedBox(height: 18),
              const _RestaurantPricingSection(),
              const SizedBox(height: 18),
              const _RestaurantPartnerBanner(),
              if (showFallbackNotice) ...[
                const SizedBox(height: 14),
                _FallbackNotice(
                  hasError: snapshot.hasError,
                ),
              ],
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) {
                  final isCompact = constraints.maxWidth < 760;
                  final cardWidth = isCompact
                      ? constraints.maxWidth
                      : (constraints.maxWidth - 16) / 2;

                  return Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: restaurants.map((restaurant) {
                      return SizedBox(
                        width: cardWidth,
                        child: RestoranPremiumCard(
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
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

class _HeroBadge extends StatelessWidget {
  const _HeroBadge({
    required this.label,
    this.filled = false,
    this.outlined = false,
  });

  final String label;
  final bool filled;
  final bool outlined;

  static const Color _gold = Color(0xFFFFB300);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: filled ? _gold : Colors.black.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: _gold.withValues(alpha: outlined ? 0.55 : 0.28),
        ),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: filled ? Colors.black : _gold,
          fontSize: 12.5,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _HeroBlock extends StatelessWidget {
  const _HeroBlock({this.onPremiumTap});

  final VoidCallback? onPremiumTap;

  static const Color _gold = Color(0xFFFFB300);

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.of(context).size.width < 600;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isCompact ? 18 : 22),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.045),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: _gold.withValues(alpha: 0.24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              _HeroBadge(
                label: 'İlk 100 Kurucu Restoran',
                outlined: true,
              ),
              _HeroBadge(
                label: '100 Kaldı',
                filled: true,
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            'Restoranlar Çok Yakında\nSofrasofra’da',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white,
              fontSize: isCompact ? 27 : 34,
              height: 1.05,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Ürün sizin, emek sizin, kazanç sizin.',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white,
              fontSize: isCompact ? 16 : 19,
              height: 1.15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Kurucu restoranlar için erken görünürlük ve lansman avantajı.',
            maxLines: isCompact ? 2 : 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white70,
              fontSize: isCompact ? 12.5 : 13.5,
              height: 1.25,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: _gold,
                side: const BorderSide(color: _gold),
                padding: EdgeInsets.symmetric(
                  horizontal: isCompact ? 14 : 18,
                  vertical: isCompact ? 10 : 12,
                ),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: onPremiumTap,
              child: Text(
                isCompact ? 'Vitrini Gör' : 'Premium Restoran Vitrinini Gör',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                ),
              ),
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

class _RestaurantPricingSection extends StatelessWidget {
  const _RestaurantPricingSection();

  static const Color _gold = Color(0xFFFFB300);

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.of(context).size.width < 720;

    final packages = const [
      _RestaurantPlanData(
        name: 'Free Restoran',
        price: '0 TL',
        period: 'aylık',
        commission: '%11',
        target: 'Denemek isteyen küçük lokanta',
        highlight: '1 ay ücretsiz deneme',
        features: [
          '6 fotoğraf hakkı',
          'Temel restoran vitrini',
          'Gel-Al / Götür fiyatı',
          'Sepete ekleme ve ödeme',
          'Standart destek',
        ],
      ),
      _RestaurantPlanData(
        name: 'Pro Restoran',
        price: '499 TL',
        period: 'aylık',
        commission: '%7',
        target: 'Aktif satış yapmak isteyen restoran',
        highlight: 'Daha fazla görünürlük',
        features: [
          'Daha geniş menü kapasitesi',
          'Daha fazla galeri alanı',
          'Fotoğraf bazlı fiyatlandırma',
          'Kampanya görünürlüğü',
          'Öncelikli destek',
        ],
      ),
      _RestaurantPlanData(
        name: 'Premium Restoran',
        price: '899 TL',
        period: 'aylık',
        commission: '%4',
        target: 'Maliyeti düşürmek ve öne çıkmak isteyen restoran',
        highlight: 'En düşük komisyon',
        features: [
          'Öncelikli vitrin görünürlüğü',
          'Geniş medya kapasitesi',
          'Radyo / blog tanıtım alanı',
          'Gelişmiş satış vitrini',
          'VIP destek',
        ],
      ),
    ];

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isCompact ? 16 : 20),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: _gold.withValues(alpha: 0.32),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Restoran Paketleri',
            style: TextStyle(
              color: _gold,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Satış yaptıkça daha az komisyon öde, daha fazla görünür ol.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              height: 1.35,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'İyzico ödeme işlem bedeli tüm paketlerde ayrıca ve şeffaf şekilde gösterilir: %4,29 + 0,25 TL.',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12.5,
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 18),
          if (isCompact)
            Column(
              children: packages
                  .map(
                    (plan) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _RestaurantPlanCard(plan: plan),
                    ),
                  )
                  .toList(),
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: packages
                  .map(
                    (plan) => Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: _RestaurantPlanCard(plan: plan),
                      ),
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }
}

class _RestaurantPlanCard extends StatelessWidget {
  const _RestaurantPlanCard({
    required this.plan,
  });

  final _RestaurantPlanData plan;

  static const Color _gold = Color(0xFFFFB300);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFF0B0B0B),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _gold.withValues(alpha: 0.28),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            plan.name,
            style: const TextStyle(
              color: _gold,
              fontSize: 15.5,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                plan.price,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(
                  '/ ${plan.period}',
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _PlanInfoRow(
            label: 'Sofrasofra komisyonu',
            value: plan.commission,
          ),
          const _PlanInfoRow(
            label: 'İyzico işlem bedeli',
            value: '%4,29 + 0,25 TL',
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 7,
            ),
            decoration: BoxDecoration(
              color: _gold.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: _gold.withValues(alpha: 0.32),
              ),
            ),
            child: Text(
              plan.highlight,
              style: const TextStyle(
                color: _gold,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            plan.target,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12.5,
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          ...plan.features.map(
            (feature) => Padding(
              padding: const EdgeInsets.only(bottom: 7),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.check_circle_outline,
                    color: _gold,
                    size: 16,
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      feature,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12.5,
                        height: 1.25,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
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

class _PlanInfoRow extends StatelessWidget {
  const _PlanInfoRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  static const Color _gold = Color(0xFFFFB300);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white60,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: _gold,
              fontSize: 12.5,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _RestaurantPlanData {
  const _RestaurantPlanData({
    required this.name,
    required this.price,
    required this.period,
    required this.commission,
    required this.target,
    required this.highlight,
    required this.features,
  });

  final String name;
  final String price;
  final String period;
  final String commission;
  final String target;
  final String highlight;
  final List<String> features;
}

class _RestaurantPartnerBanner extends StatelessWidget {
  const _RestaurantPartnerBanner();

  static const Color _gold = Color(0xFFFFB300);
  static const Color _card = Color(0xFF101010);
  static const Color _border = Color(0x33FFB300);

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isCompact = width < 720;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isCompact ? 18 : 22),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.30),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: isCompact
          ? const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _PartnerBannerText(),
                SizedBox(height: 16),
                _PartnerOpportunityWrap(),
                SizedBox(height: 16),
                _PartnerBannerCta(),
              ],
            )
          : const Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  flex: 5,
                  child: _PartnerBannerText(),
                ),
                SizedBox(width: 18),
                Expanded(
                  flex: 5,
                  child: _PartnerOpportunityWrap(),
                ),
                SizedBox(width: 18),
                _PartnerBannerCta(),
              ],
            ),
    );
  }
}

class _PartnerBannerText extends StatelessWidget {
  const _PartnerBannerText();

  static const Color _gold = Color(0xFFFFB300);

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'SPONSORLU RESTORAN VİTRİNİ',
          style: TextStyle(
            color: _gold,
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.4,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Restoranını Daha Görünür Hale Getir',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w900,
            height: 1.15,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Öne çıkmak isteyen restoranlar için Sofrasofra vitrin alanı. Mahallenizdeki lezzetinizi daha fazla müşteriye gösterin.',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            height: 1.45,
          ),
        ),
      ],
    );
  }
}

class _PartnerOpportunityWrap extends StatelessWidget {
  const _PartnerOpportunityWrap();

  @override
  Widget build(BuildContext context) {
    return const Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _PartnerOpportunityChip(
          icon: Icons.campaign_outlined,
          label: 'Sponsorlu Vitrin',
        ),
        _PartnerOpportunityChip(
          icon: Icons.star_border_rounded,
          label: 'Haftanın Restoranı',
        ),
        _PartnerOpportunityChip(
          icon: Icons.location_on_outlined,
          label: 'Mahallede Öne Çık',
        ),
      ],
    );
  }
}

class _PartnerOpportunityChip extends StatelessWidget {
  const _PartnerOpportunityChip({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  static const Color _gold = Color(0xFFFFB300);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: _gold.withValues(alpha: 0.22),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: _gold, size: 17),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _PartnerBannerCta extends StatelessWidget {
  const _PartnerBannerCta();

  static const Color _gold = Color(0xFFFFB300);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        color: _gold.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _gold.withValues(alpha: 0.55),
        ),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.trending_up_rounded,
            color: _gold,
            size: 18,
          ),
          SizedBox(width: 8),
          Text(
            'Restoranımı Öne Çıkar',
            style: TextStyle(
              color: _gold,
              fontSize: 12.5,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
