import 'package:flutter/material.dart';
import 'package:sofrasofra_arena_v2/services/restoran_service.dart';

import 'models/restoran_model.dart';
import 'restoran_detay_sayfasi.dart';
import 'widgets/restoran_premium_card.dart';

class PremiumRestoranVitrini extends StatefulWidget {
  const PremiumRestoranVitrini({super.key});

  @override
  State<PremiumRestoranVitrini> createState() => _PremiumRestoranVitriniState();
}

class _PremiumRestoranVitriniState extends State<PremiumRestoranVitrini> {
  static const Color _gold = Color(0xFFFFB300);
  static const Color _bg = Color(0xFF050505);

  static const List<String> _categories = [
    'Tümü',
    'Kebap & Izgara',
    'Pide & Lahmacun',
    'Döner',
    'Burger',
    'Pizza',
    'Tavuk',
    'Balık',
    'Tatlı',
    'Pastane & Fırın',
    'Kahve',
    'İçecek',
  ];

  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';
  String _selectedCategory = 'Tümü';
  bool _gelAlOnly = false;
  bool _goturOnly = false;
  bool _openOnly = false;
  String _sortMode = 'varsayilan';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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
          final sourceRestaurants = snapshot.data ?? const <RestoranModel>[];

          String normalizeSearchText(String value) {
            return value
                .toLowerCase()
                .replaceAll('ı', 'i')
                .replaceAll('ş', 's')
                .replaceAll('ğ', 'g')
                .replaceAll('ü', 'u')
                .replaceAll('ö', 'o')
                .replaceAll('ç', 'c')
                .replaceAll(RegExp(r'[\s\-_•]+'), '');
          }

          final normalizedQuery = normalizeSearchText(_searchQuery);

          final restaurants = sourceRestaurants.where((restaurant) {
            final matchesCategory = _selectedCategory == 'Tümü' ||
                restaurant.cuisine.trim().toLowerCase() ==
                    _selectedCategory.toLowerCase();

            final searchableText = normalizeSearchText(
              [
                restaurant.name,
                restaurant.description,
                restaurant.cuisine,
                restaurant.city,
                restaurant.district,
                restaurant.serviceText,
              ].join(' '),
            );

            final matchesSearch = normalizedQuery.isEmpty ||
                searchableText.contains(normalizedQuery);

            final matchesGelAl = !_gelAlOnly || restaurant.supportsGelAl;
            final matchesGotur = !_goturOnly || restaurant.supportsGotur;
            final matchesOpen = !_openOnly || restaurant.isOpen;
            return matchesCategory &&
                matchesSearch &&
                matchesGelAl &&
                matchesGotur;
          }).toList();
          int preparationMinutes(RestoranModel restaurant) {
            final match = RegExp(r'\d+').firstMatch(restaurant.preparationText);

            return int.tryParse(match?.group(0) ?? '') ?? 9999;
          }

          double ratingValue(RestoranModel restaurant) {
            final normalized = restaurant.ratingText.replaceAll(',', '.');
            final match = RegExp(r'\d+(?:\.\d+)?').firstMatch(normalized);

            return double.tryParse(match?.group(0) ?? '') ?? 0;
          }

          if (_sortMode == 'en_hizli') {
            restaurants.sort(
              (a, b) => preparationMinutes(a).compareTo(preparationMinutes(b)),
            );
          } else if (_sortMode == 'en_yuksek_puan') {
            restaurants.sort(
              (a, b) => ratingValue(b).compareTo(ratingValue(a)),
            );
          }
          final showFallbackNotice =
              snapshot.hasError || sourceRestaurants.isEmpty;

          return ListView(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 32),
            children: [
              const Text(
                'Mahallendeki Restoranları Keşfet',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              const SizedBox(height: 16),
              TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
                decoration: InputDecoration(
                  hintText: 'Restoran, kategori veya bölge ara…',
                  hintStyle: const TextStyle(
                    color: Colors.white54,
                    fontWeight: FontWeight.w600,
                  ),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: _gold,
                  ),
                  suffixIcon: _searchQuery.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Aramayı temizle',
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                          icon: const Icon(
                            Icons.close_rounded,
                            color: Colors.white70,
                          ),
                        ),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.055),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 15,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide(
                      color: _gold.withValues(alpha: 0.24),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: const BorderSide(
                      color: _gold,
                      width: 1.4,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 42,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _categories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final category = _categories[index];
                    final selected = category == _selectedCategory;

                    return ChoiceChip(
                      selected: selected,
                      showCheckmark: false,
                      label: Text(category),
                      onSelected: (_) {
                        setState(() {
                          _selectedCategory = category;
                        });
                      },
                      labelStyle: TextStyle(
                        color: selected ? Colors.black : Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 12.5,
                      ),
                      selectedColor: _gold,
                      backgroundColor: Colors.white.withValues(alpha: 0.055),
                      side: BorderSide(
                        color: selected ? _gold : _gold.withValues(alpha: 0.24),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 9,
                runSpacing: 9,
                children: [
                  FilterChip(
                    selected: _gelAlOnly,
                    showCheckmark: false,
                    avatar: Icon(
                      Icons.storefront_rounded,
                      size: 18,
                      color: _gelAlOnly ? Colors.black : _gold,
                    ),
                    label: const Text('Gel-Al'),
                    onSelected: (selected) {
                      _searchController.clear();

                      setState(() {
                        _searchQuery = '';
                        _gelAlOnly = selected;

                        if (selected) {
                          _goturOnly = false;
                        }
                      });
                    },
                    labelStyle: TextStyle(
                      color: _gelAlOnly ? Colors.black : Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                    selectedColor: _gold,
                    backgroundColor: Colors.white.withValues(alpha: 0.055),
                    side: BorderSide(
                      color: _gelAlOnly ? _gold : _gold.withValues(alpha: 0.24),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  FilterChip(
                    selected: _openOnly,
                    showCheckmark: false,
                    avatar: Icon(
                      Icons.store_rounded,
                      size: 18,
                      color: _openOnly ? Colors.black : _gold,
                    ),
                    label: const Text('Açık Restoranlar'),
                    onSelected: (selected) {
                      setState(() {
                        _openOnly = selected;
                      });
                    },
                    labelStyle: TextStyle(
                      color: _openOnly ? Colors.black : Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                    selectedColor: _gold,
                    backgroundColor: Colors.white.withValues(alpha: 0.055),
                    side: BorderSide(
                      color: _openOnly ? _gold : _gold.withValues(alpha: 0.24),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  FilterChip(
                    selected: _goturOnly,
                    showCheckmark: false,
                    avatar: Icon(
                      Icons.delivery_dining_rounded,
                      size: 18,
                      color: _goturOnly ? Colors.black : _gold,
                    ),
                    label: const Text('Götür'),
                    onSelected: (selected) {
                      _searchController.clear();

                      setState(() {
                        _searchQuery = '';
                        _goturOnly = selected;

                        if (selected) {
                          _gelAlOnly = false;
                        }
                      });
                    },
                    labelStyle: TextStyle(
                      color: _goturOnly ? Colors.black : Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                    selectedColor: _gold,
                    backgroundColor: Colors.white.withValues(alpha: 0.055),
                    side: BorderSide(
                      color: _goturOnly ? _gold : _gold.withValues(alpha: 0.24),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  if (_gelAlOnly ||
                      _goturOnly ||
                      _openOnly ||
                      _sortMode != 'varsayilan')
                    ActionChip(
                      avatar: const Icon(
                        Icons.refresh_rounded,
                        size: 18,
                        color: Colors.white70,
                      ),
                      label: const Text('Filtreyi Temizle'),
                      onPressed: () {
                        setState(() {
                          _gelAlOnly = false;
                          _goturOnly = false;
                          _openOnly = false;
                          _sortMode = 'varsayilan';
                        });
                      },
                      labelStyle: const TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w700,
                      ),
                      backgroundColor: Colors.white.withValues(alpha: 0.045),
                      side: BorderSide(
                        color: Colors.white.withValues(alpha: 0.12),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 9,
                runSpacing: 9,
                children: [
                  ChoiceChip(
                    selected: _sortMode == 'en_hizli',
                    showCheckmark: false,
                    avatar: Icon(
                      Icons.bolt_rounded,
                      size: 18,
                      color: _sortMode == 'en_hizli' ? Colors.black : _gold,
                    ),
                    label: const Text('En Hızlı'),
                    onSelected: (selected) {
                      setState(() {
                        _sortMode = selected ? 'en_hizli' : 'varsayilan';
                      });
                    },
                    labelStyle: TextStyle(
                      color:
                          _sortMode == 'en_hizli' ? Colors.black : Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                    selectedColor: _gold,
                    backgroundColor: Colors.white.withValues(alpha: 0.055),
                    side: BorderSide(
                      color: _sortMode == 'en_hizli'
                          ? _gold
                          : _gold.withValues(alpha: 0.24),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  ChoiceChip(
                    selected: _sortMode == 'en_yuksek_puan',
                    showCheckmark: false,
                    avatar: Icon(
                      Icons.star_rounded,
                      size: 18,
                      color:
                          _sortMode == 'en_yuksek_puan' ? Colors.black : _gold,
                    ),
                    label: const Text('En Yüksek Puan'),
                    onSelected: (selected) {
                      setState(() {
                        _sortMode = selected ? 'en_yuksek_puan' : 'varsayilan';
                      });
                    },
                    labelStyle: TextStyle(
                      color: _sortMode == 'en_yuksek_puan'
                          ? Colors.black
                          : Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                    selectedColor: _gold,
                    backgroundColor: Colors.white.withValues(alpha: 0.055),
                    side: BorderSide(
                      color: _sortMode == 'en_yuksek_puan'
                          ? _gold
                          : _gold.withValues(alpha: 0.24),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ],
              ),
              if (showFallbackNotice) ...[
                const SizedBox(height: 14),
                _FallbackNotice(
                  hasError: snapshot.hasError,
                ),
              ],
              const SizedBox(height: 18),
              if (restaurants.isEmpty) ...[
                const SizedBox(height: 28),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.045),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _gold.withValues(alpha: 0.22),
                    ),
                  ),
                  child: const Column(
                    children: [
                      Icon(
                        Icons.search_off_rounded,
                        color: _gold,
                        size: 42,
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Aramanıza uygun restoran bulunamadı.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Başka bir restoran adı, kategori veya bölge deneyin.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white60,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (restaurants.isNotEmpty)
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
                            isOpen: restaurant.isOpen,
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
              const SizedBox(height: 22),
              const _RestaurantPartnerBanner(),
            ],
          );
        },
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
