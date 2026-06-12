import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sofrasofra_arena_v2/modules/restoranlar/models/restoran_model.dart';
import 'package:sofrasofra_arena_v2/modules/restoranlar/restoran_detay_sayfasi.dart';
import 'package:sofrasofra_arena_v2/modules/vitrinler/ev_lezzetleri_vitrini.dart';
import 'package:sofrasofra_arena_v2/modules/vitrinler/sef_vitrini_v2.dart';
import 'package:sofrasofra_arena_v2/modules/vitrinler/restoranlar_vitrini.dart';
import 'package:sofrasofra_arena_v2/modules/urun_detay.dart';

class SofrasofraPazaryeriVitrini extends StatelessWidget {
  const SofrasofraPazaryeriVitrini({super.key});

  static const Color _bg = Color(0xFF0D0D0D);
  static const Color _panel = Color(0xFF151515);
  static const Color _panelSoft = Color(0xFF1B1A17);
  static const Color _gold = Color(0xFFFFD54F);
  static const Color _goldSoft = Color(0xFFD6B35A);
  static const Color _text = Colors.white;
  static const Color _muted = Color(0xFFB6ADA0);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 760;

        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: _bg,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: _gold.withValues(alpha: 0.22),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _HeroShowcase(isMobile: isMobile),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  isMobile ? 18 : 26,
                  0,
                  isMobile ? 18 : 26,
                  isMobile ? 20 : 28,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _MarketTitle(),
                    const SizedBox(height: 18),
                    _LiveShowcaseSections(isMobile: isMobile),
                    const SizedBox(height: 28),
                    _HowItWorksPanel(isMobile: isMobile),
                    const SizedBox(height: 22),
                    _FounderApplicationsPanel(isMobile: isMobile),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _LiveShowcaseSections extends StatelessWidget {
  const _LiveShowcaseSections({required this.isMobile});

  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('home_showcase_items')
          .snapshots(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];

        final liveItems = docs
            .map((doc) => _MarketItem.fromFirestore(doc.data()))
            .where((item) => item != null)
            .cast<_MarketItem>()
            .toList()
          ..sort((a, b) => a.order.compareTo(b.order));

        final evItems = liveItems
            .where((item) => item.section == 'ev_lezzetleri')
            .take(8)
            .toList();

        final sefItems = liveItems
            .where((item) => item.section == 'usta_sefler')
            .take(8)
            .toList();

        final restoranItems = liveItems
            .where((item) => item.section == 'restoranlar')
            .take(8)
            .toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ProductSection(
              icon: Icons.home_rounded,
              title: 'Ev Lezzetleri',
              subtitle:
                  'Evde özenle hazırlanan, mahalleden sofraya gelen lezzetler.',
              actionText: 'Tümünü Gör',
              items: evItems.isEmpty ? _evLezzetleriItems : evItems,
              isMobile: isMobile,
            ),
            const SizedBox(height: 26),
            _ProductSection(
              icon: Icons.restaurant_menu_rounded,
              title: 'Usta Şefler',
              subtitle:
                  'Profesyonel şeflerin imza tabakları, davet menüleri ve atölyeleri.',
              actionText: 'Tümünü Gör',
              items: sefItems.isEmpty ? _ustaSefItems : sefItems,
              isMobile: isMobile,
            ),
            const SizedBox(height: 26),
            _ProductSection(
              icon: Icons.storefront_rounded,
              title: 'Restoranlar',
              subtitle:
                  'Mahallenizin restoranlarından gel-al ve götür seçenekli menüler.',
              actionText: 'Tümünü Gör',
              items: restoranItems.isEmpty ? _restoranItems : restoranItems,
              isMobile: isMobile,
            ),
          ],
        );
      },
    );
  }
}

class _HeroShowcase extends StatelessWidget {
  const _HeroShowcase({required this.isMobile});

  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 18 : 28),
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(28),
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF201A12),
            SofrasofraPazaryeriVitrini._bg,
            const Color(0xFF111111),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isMobile)
            const _HeroTextBlock()
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Expanded(
                  flex: 6,
                  child: _HeroTextBlock(),
                ),
                const SizedBox(width: 24),
                Expanded(
                  flex: 5,
                  child: _HeroVisualGrid(isMobile: isMobile),
                ),
              ],
            ),
          if (isMobile) ...[
            const SizedBox(height: 20),
            _HeroVisualGrid(isMobile: isMobile),
          ],
          const SizedBox(height: 20),
          const _PremiumSearchBar(),
          const SizedBox(height: 14),
          const _CategoryChips(),
        ],
      ),
    );
  }
}

class _HeroTextBlock extends StatelessWidget {
  const _HeroTextBlock();

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

class _HeroVisualGrid extends StatelessWidget {
  const _HeroVisualGrid({
    required this.isMobile,
  });

  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

class _HeroRestaurantCampaignBanner extends StatelessWidget {
  const _HeroRestaurantCampaignBanner({
    required this.isMobile,
    required this.onTap,
  });

  final bool isMobile;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: SofrasofraPazaryeriVitrini._gold.withValues(
                alpha: 0.62,
              ),
              width: 1.3,
            ),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF49330A),
                Color(0xFF211805),
                Color(0xFF090909),
              ],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                right: isMobile ? -24 : 20,
                bottom: isMobile ? -20 : -12,
                child: Icon(
                  Icons.storefront_rounded,
                  size: isMobile ? 150 : 220,
                  color: SofrasofraPazaryeriVitrini._gold.withValues(
                    alpha: 0.025,
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(isMobile ? 12 : 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.workspace_premium_rounded,
                          color: SofrasofraPazaryeriVitrini._gold,
                          size: 23,
                        ),
                        SizedBox(width: 9),
                        Expanded(
                          child: Text(
                            'KURUCU RESTORAN AVANTAJI',
                            style: TextStyle(
                              color: SofrasofraPazaryeriVitrini._gold,
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.7,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: isMobile ? 12 : 16),
                    Text(
                      'İlk 100 restorana\n1 yıl üyelik ücretsiz',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isMobile ? 23 : 34,
                        height: 1.08,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: isMobile ? 12 : 16),
                    Text(
                      'Gel-Al ve Götür siparişlerini Sofrasofra’ya taşı.',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: isMobile ? 14 : 17,
                        height: 1.4,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: isMobile ? 14 : 18),
                    Row(
                      children: [
                        const Text(
                          'Kalan kontenjan',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.28),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: SofrasofraPazaryeriVitrini._gold,
                              width: 1.2,
                            ),
                          ),
                          child: const Text(
                            '100',
                            style: TextStyle(
                              color: SofrasofraPazaryeriVitrini._gold,
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: isMobile ? 16 : 20),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 11,
                      ),
                      decoration: BoxDecoration(
                        color: SofrasofraPazaryeriVitrini._gold,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'RESTORAN BAŞVURUSU',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          SizedBox(width: 7),
                          Icon(
                            Icons.arrow_forward_rounded,
                            color: Colors.black,
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PremiumSearchBar extends StatelessWidget {
  const _PremiumSearchBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.40),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: SofrasofraPazaryeriVitrini._gold.withValues(alpha: 0.34),
        ),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.search_rounded,
            color: SofrasofraPazaryeriVitrini._gold,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Ne yemek istersin?',
              style: TextStyle(
                color: SofrasofraPazaryeriVitrini._muted,
                fontSize: 15,
              ),
            ),
          ),
          Icon(
            Icons.tune_rounded,
            color: SofrasofraPazaryeriVitrini._gold,
          ),
        ],
      ),
    );
  }
}

class _CategoryChips extends StatelessWidget {
  const _CategoryChips();

  static const List<_ChipInfo> _chips = [
    _ChipInfo(Icons.apps_rounded, 'Tümü'),
    _ChipInfo(Icons.home_rounded, 'Ev Lezzetleri'),
    _ChipInfo(Icons.restaurant_menu_rounded, 'Usta Şefler'),
    _ChipInfo(Icons.storefront_rounded, 'Restoranlar'),
    _ChipInfo(Icons.cake_rounded, 'Tatlılar'),
    _ChipInfo(Icons.local_cafe_rounded, 'İçecekler'),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _chips.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final chip = _chips[index];
          final selected = index == 0;

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: selected
                  ? SofrasofraPazaryeriVitrini._gold
                  : Colors.black.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: SofrasofraPazaryeriVitrini._gold.withValues(
                  alpha: selected ? 1 : 0.28,
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  chip.icon,
                  size: 17,
                  color: selected
                      ? Colors.black
                      : SofrasofraPazaryeriVitrini._gold,
                ),
                const SizedBox(width: 7),
                Text(
                  chip.label,
                  style: TextStyle(
                    color: selected ? Colors.black : Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _MarketTitle extends StatelessWidget {
  const _MarketTitle();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sofrasofra Pazaryeri Vitrini',
          style: TextStyle(
            color: SofrasofraPazaryeriVitrini._text,
            fontSize: 30,
            fontWeight: FontWeight.w900,
            height: 1.1,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Satışa uygun ürün ve hizmetleri keşfedin; ev üreticileri, şefler ve restoranlar aynı sofrada buluşsun.',
          style: TextStyle(
            color: SofrasofraPazaryeriVitrini._muted,
            fontSize: 15,
            height: 1.45,
          ),
        ),
      ],
    );
  }
}

class _ProductSection extends StatelessWidget {
  const _ProductSection({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.actionText,
    required this.items,
    required this.isMobile,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String actionText;
  final List<_MarketItem> items;
  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    final cardWidth = isMobile ? 236.0 : 276.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          icon: icon,
          title: title,
          subtitle: subtitle,
          actionText: actionText,
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: isMobile ? 370 : 392,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              return SizedBox(
                width: cardWidth,
                child: _MarketProductCard(item: items[index]),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.actionText,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String actionText;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color:
                      SofrasofraPazaryeriVitrini._gold.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: SofrasofraPazaryeriVitrini._gold
                        .withValues(alpha: 0.34),
                  ),
                ),
                child: Icon(
                  icon,
                  color: SofrasofraPazaryeriVitrini._gold,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: SofrasofraPazaryeriVitrini._text,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: SofrasofraPazaryeriVitrini._muted,
                        fontSize: 13.5,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        TextButton.icon(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text('$title sayfasına bağlantı hazırlanıyor.')),
            );
          },
          icon: const Icon(Icons.arrow_forward_rounded, size: 16),
          label: Text(actionText),
          style: TextButton.styleFrom(
            foregroundColor: SofrasofraPazaryeriVitrini._gold,
          ),
        ),
      ],
    );
  }
}

class _MarketProductCard extends StatelessWidget {
  const _MarketProductCard({required this.item});
  void _openShowcaseTarget(BuildContext context, _MarketItem item) {
    final targetType = item.targetType.toLowerCase().trim();
    final targetId = item.targetId.trim();

    if (targetType == 'restaurant' && targetId.isNotEmpty) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => _RestaurantShowcaseTargetPage(
            restaurantId: targetId,
            fallbackTitle: item.name,
          ),
        ),
      );
      return;
    }
    if (targetType == 'ev_product' && targetId.isNotEmpty) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => UrunDetaySayfasi(
            urunAdi: item.name,
            urunFiyat: item.price,
            urunGorsel: item.imageUrl,
            aciklama: item.description,
            dukkanAdi: item.category,
            konum: 'İstanbul',
            youtubeUrl: '',
            urunGorseller: [item.imageUrl],
            productId: targetId,
            sellerId: item.sellerId.isNotEmpty ? item.sellerId : targetId,
            kategori: 'Ev Lezzetleri',
          ),
        ),
      );
      return;
    }
    Widget page;

    switch (item.section) {
      case 'ev_lezzetleri':
        page = const EvLezzetleriVitrini(
          city: 'İstanbul',
          district: 'Kadıköy',
        );
        break;
      case 'usta_sefler':
        page = const SefVitriniV2();
        break;
      case 'restoranlar':
        page = const RestoranlarVitrini();
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${item.name} için bağlantı hazırlanıyor.'),
          ),
        );
        return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => page,
      ),
    );
  }

  final _MarketItem item;
  Widget _buildCardImage() {
    final targetType = item.targetType.toLowerCase().trim();
    final targetId = item.targetId.trim();

    if (targetType != 'restaurant' || targetId.isEmpty) {
      return _networkImage(item.imageUrl);
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('restaurants')
          .doc(targetId)
          .snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data();

        final restaurantImageUrl =
            (data?['imageUrl'] ?? data?['img'] ?? '').toString().trim();

        return _networkImage(restaurantImageUrl);
      },
    );
  }

  Widget _networkImage(String imageUrl) {
    if (imageUrl.trim().isEmpty) {
      return Container(
        color: const Color(0xFF222222),
        alignment: Alignment.center,
        child: Icon(
          item.icon,
          color: SofrasofraPazaryeriVitrini._gold,
          size: 44,
        ),
      );
    }

    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      filterQuality: FilterQuality.medium,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: const Color(0xFF222222),
          alignment: Alignment.center,
          child: Icon(
            item.icon,
            color: SofrasofraPazaryeriVitrini._gold,
            size: 44,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: SofrasofraPazaryeriVitrini._panel,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: SofrasofraPazaryeriVitrini._gold.withValues(alpha: 0.18),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.24),
            blurRadius: 18,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _buildCardImage(),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.06),
                          Colors.black.withValues(alpha: 0.82),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 12,
                    top: 12,
                    child: _SmallPill(text: item.category),
                  ),
                  Positioned(
                    right: 12,
                    top: 12,
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.50),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: SofrasofraPazaryeriVitrini._gold.withValues(
                            alpha: 0.34,
                          ),
                        ),
                      ),
                      child: const Icon(
                        Icons.favorite_border_rounded,
                        color: SofrasofraPazaryeriVitrini._gold,
                        size: 18,
                      ),
                    ),
                  ),
                  Positioned(
                    left: 14,
                    right: 14,
                    bottom: 14,
                    child: Text(
                      item.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        height: 1.1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 13, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: SofrasofraPazaryeriVitrini._muted,
                      fontSize: 13,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.price,
                          style: const TextStyle(
                            color: SofrasofraPazaryeriVitrini._gold,
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _openShowcaseTarget(context, item),
                        icon: Icon(item.ctaIcon, size: 16),
                        label: Text(item.cta),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: SofrasofraPazaryeriVitrini._gold,
                          foregroundColor: Colors.black,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          textStyle: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w900,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
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

class _SmallPill extends StatelessWidget {
  const _SmallPill({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.56),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: SofrasofraPazaryeriVitrini._gold.withValues(alpha: 0.32),
        ),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: SofrasofraPazaryeriVitrini._gold,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _HowItWorksPanel extends StatelessWidget {
  const _HowItWorksPanel({required this.isMobile});

  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    final children = const [
      _StepCard(
        number: '1',
        icon: Icons.explore_rounded,
        title: 'Keşfet',
        text: 'Ev lezzetlerini, şef hizmetlerini ve restoran menülerini görün.',
      ),
      _StepCard(
        number: '2',
        icon: Icons.shopping_cart_checkout_rounded,
        title: 'Sipariş Ver',
        text: 'Ürün veya hizmeti seçin, sepet ve ödeme adımlarına geçin.',
      ),
      _StepCard(
        number: '3',
        icon: Icons.room_service_rounded,
        title: 'Sofraya Gelsin',
        text:
            'Lezzet özenle hazırlansın, gel-al veya götür akışıyla tamamlansın.',
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: SofrasofraPazaryeriVitrini._panelSoft,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: SofrasofraPazaryeriVitrini._gold.withValues(alpha: 0.22),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Nasıl Çalışır?',
            style: TextStyle(
              color: SofrasofraPazaryeriVitrini._text,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 14),
          if (isMobile)
            Column(
              children: [
                for (final child in children) ...[
                  child,
                  if (child != children.last) const SizedBox(height: 12),
                ],
              ],
            )
          else
            Row(
              children: [
                for (int i = 0; i < children.length; i++) ...[
                  Expanded(child: children[i]),
                  if (i != children.length - 1) const SizedBox(width: 14),
                ],
              ],
            ),
        ],
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  const _StepCard({
    required this.number,
    required this.icon,
    required this.title,
    required this.text,
  });

  final String number;
  final IconData icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.24),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: SofrasofraPazaryeriVitrini._gold.withValues(alpha: 0.16),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 17,
            backgroundColor: SofrasofraPazaryeriVitrini._gold,
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Icon(
            icon,
            color: SofrasofraPazaryeriVitrini._gold,
            size: 24,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: SofrasofraPazaryeriVitrini._text,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  text,
                  style: const TextStyle(
                    color: SofrasofraPazaryeriVitrini._muted,
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FounderApplicationsPanel extends StatelessWidget {
  const _FounderApplicationsPanel({required this.isMobile});

  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    final cards = const [
      _FounderCard(
        icon: Icons.home_work_rounded,
        title: 'Ev Üreticisi',
        highlight: 'İlk 100 kurucu üyeye 1 yıl ücretsiz',
        text: 'Evde ürettiğiniz lezzetleri dijital vitrininize taşıyın.',
      ),
      _FounderCard(
        icon: Icons.workspace_premium_rounded,
        title: 'Usta Şef',
        highlight: 'İlk 100 usta şefe 1 yıl ücretsiz',
        text:
            'İmza tabaklarınızı, davet menülerinizi ve atölyelerinizi tanıtın.',
      ),
      _FounderCard(
        icon: Icons.storefront_rounded,
        title: 'Restoran',
        highlight: 'Restoran vitrininizi açın',
        text: 'Menü ürünlerinizi gel-al ve götür seçenekleriyle sunun.',
      ),
      _FounderCard(
        icon: Icons.delivery_dining_rounded,
        title: 'Kurye',
        highlight: 'Mahalle teslimat ağına katılın',
        text: 'Esnek çalışma modeliyle Sofrasofra kurye ağına dahil olun.',
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF211807),
            SofrasofraPazaryeriVitrini._panel,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: SofrasofraPazaryeriVitrini._gold.withValues(alpha: 0.28),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isMobile)
            const _FounderHeader()
          else
            Row(
              children: [
                const Expanded(child: _FounderHeader()),
                const SizedBox(width: 18),
                ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content:
                            Text('Kurucu başvuru yönlendirmesi hazırlanıyor.'),
                      ),
                    );
                  },
                  icon: const Icon(Icons.arrow_forward_rounded),
                  label: const Text('Başvuru Yap'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: SofrasofraPazaryeriVitrini._gold,
                    foregroundColor: Colors.black,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 15,
                    ),
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          if (isMobile) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content:
                          Text('Kurucu başvuru yönlendirmesi hazırlanıyor.'),
                    ),
                  );
                },
                icon: const Icon(Icons.arrow_forward_rounded),
                label: const Text('Başvuru Yap'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: SofrasofraPazaryeriVitrini._gold,
                  foregroundColor: Colors.black,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 18),
          if (isMobile)
            Column(
              children: [
                for (final card in cards) ...[
                  card,
                  if (card != cards.last) const SizedBox(height: 12),
                ],
              ],
            )
          else
            Row(
              children: [
                for (int i = 0; i < cards.length; i++) ...[
                  Expanded(child: cards[i]),
                  if (i != cards.length - 1) const SizedBox(width: 12),
                ],
              ],
            ),
        ],
      ),
    );
  }
}

class _FounderHeader extends StatelessWidget {
  const _FounderHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Row(
          children: [
            Icon(
              Icons.stars_rounded,
              color: SofrasofraPazaryeriVitrini._gold,
            ),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Kurucu Başvurular Açık',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: SofrasofraPazaryeriVitrini._text,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        Text(
          'Ev Lezzetleri ve Usta Şefler için ilk 100 kurucu üyeye 1 yıl ücretsiz avantajı korunuyor.',
          style: TextStyle(
            color: SofrasofraPazaryeriVitrini._muted,
            fontSize: 14,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

class _FounderCard extends StatelessWidget {
  const _FounderCard({
    required this.icon,
    required this.title,
    required this.highlight,
    required this.text,
  });

  final IconData icon;
  final String title;
  final String highlight;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 154),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: SofrasofraPazaryeriVitrini._gold.withValues(alpha: 0.18),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: SofrasofraPazaryeriVitrini._gold,
            size: 28,
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              color: SofrasofraPazaryeriVitrini._text,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            highlight,
            style: const TextStyle(
              color: SofrasofraPazaryeriVitrini._gold,
              fontSize: 12.5,
              fontWeight: FontWeight.w900,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            text,
            style: const TextStyle(
              color: SofrasofraPazaryeriVitrini._muted,
              fontSize: 12.5,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroBadge extends StatelessWidget {
  const _HeroBadge({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 9,
      ),
      decoration: BoxDecoration(
        color: SofrasofraPazaryeriVitrini._gold.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: SofrasofraPazaryeriVitrini._gold.withValues(alpha: 0.24),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: SofrasofraPazaryeriVitrini._gold,
            size: 16,
          ),
          const SizedBox(width: 7),
          Text(
            text,
            style: const TextStyle(
              color: SofrasofraPazaryeriVitrini._text,
              fontWeight: FontWeight.w800,
              fontSize: 12.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _RestaurantShowcaseTargetPage extends StatelessWidget {
  const _RestaurantShowcaseTargetPage({
    required this.restaurantId,
    required this.fallbackTitle,
  });

  final String restaurantId;
  final String fallbackTitle;

  static const Color _gold = Color(0xFFFFB300);
  static const Color _bg = Color(0xFF050505);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: FirebaseFirestore.instance
          .collection('restaurants')
          .doc(restaurantId)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: _bg,
            body: Center(
              child: CircularProgressIndicator(color: _gold),
            ),
          );
        }

        if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
          return Scaffold(
            backgroundColor: _bg,
            appBar: AppBar(
              backgroundColor: Colors.black,
              foregroundColor: _gold,
              title: const Text('Restoran bulunamadı'),
            ),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  '$fallbackTitle vitrini şu anda görüntülenemiyor.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 15,
                    height: 1.45,
                  ),
                ),
              ),
            ),
          );
        }

        final doc = snapshot.data!;
        final restaurant = RestoranModel.fromMap(doc.id, doc.data()!);

        return RestoranDetaySayfasi(restaurant: restaurant);
      },
    );
  }
}

class _MarketItem {
  const _MarketItem({
    required this.category,
    required this.name,
    required this.description,
    required this.price,
    required this.cta,
    required this.ctaIcon,
    required this.icon,
    required this.imageUrl,
    this.section = '',
    this.order = 999,
    this.targetType = '',
    this.targetId = '',
    this.sponsored = false,
    this.sellerId = '',
  });

  final String category;
  final String name;
  final String description;
  final String price;
  final String cta;
  final IconData ctaIcon;
  final IconData icon;
  final String imageUrl;

  final String section;
  final int order;
  final String targetType;
  final String targetId;
  final String sellerId;
  final bool sponsored;

  static _MarketItem? fromFirestore(Map<String, dynamic> data) {
    final active = data['active'];
    if (active == false) return null;

    final section = (data['section'] ?? '').toString().trim();
    final title = (data['title'] ?? data['name'] ?? '').toString().trim();
    final imageUrl = (data['imageUrl'] ?? '').toString().trim();

    if (section.isEmpty || title.isEmpty || imageUrl.isEmpty) {
      return null;
    }

    final categoryLabel =
        (data['categoryLabel'] ?? _categoryFromSection(section)).toString();

    final ctaText = (data['ctaText'] ?? _ctaFromSection(section)).toString();

    return _MarketItem(
      section: section,
      category: categoryLabel,
      name: title,
      description: (data['description'] ?? '').toString(),
      price: (data['priceText'] ?? '').toString(),
      cta: ctaText,
      ctaIcon: _ctaIconFromSection(section),
      icon: _iconFromSection(section),
      imageUrl: imageUrl,
      order: _intFromValue(data['order'], fallback: 999),
      targetType: (data['targetType'] ?? '').toString(),
      sellerId: (data['sellerId'] ?? data['dukkanId'] ?? '').toString(),
      targetId: (data['targetId'] ?? '').toString(),
      sponsored: data['sponsored'] == true,
    );
  }

  static String _categoryFromSection(String section) {
    switch (section) {
      case 'ev_lezzetleri':
        return 'Ev Lezzetleri';
      case 'usta_sefler':
        return 'Usta Şefler';
      case 'restoranlar':
        return 'Restoranlar';
      default:
        return 'Sofrasofra';
    }
  }

  static String _ctaFromSection(String section) {
    switch (section) {
      case 'ev_lezzetleri':
        return 'Sepete Ekle';
      case 'usta_sefler':
        return 'Detayı Gör';
      case 'restoranlar':
        return 'Siparişe Başla';
      default:
        return 'Detayı Gör';
    }
  }

  static IconData _ctaIconFromSection(String section) {
    switch (section) {
      case 'ev_lezzetleri':
        return Icons.shopping_bag_rounded;
      case 'usta_sefler':
        return Icons.arrow_forward_rounded;
      case 'restoranlar':
        return Icons.room_service_rounded;
      default:
        return Icons.arrow_forward_rounded;
    }
  }

  static IconData _iconFromSection(String section) {
    switch (section) {
      case 'ev_lezzetleri':
        return Icons.home_rounded;
      case 'usta_sefler':
        return Icons.restaurant_menu_rounded;
      case 'restoranlar':
        return Icons.storefront_rounded;
      default:
        return Icons.restaurant_rounded;
    }
  }

  static int _intFromValue(dynamic value, {required int fallback}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }
}

class _ChipInfo {
  const _ChipInfo(this.icon, this.label);

  final IconData icon;
  final String label;
}

const List<_MarketItem> _evLezzetleriItems = [
  _MarketItem(
    category: 'Ev Lezzetleri',
    name: 'Ev Mantısı',
    description: 'İncecik hamur, dana kıyma ve ev yapımı yoğurtla hazırlanır.',
    price: '₺180',
    cta: 'Sepete Ekle',
    ctaIcon: Icons.shopping_bag_rounded,
    icon: Icons.home_rounded,
    imageUrl:
        'https://images.unsplash.com/photo-1604909052743-94e838986d24?auto=format&fit=crop&w=900&q=80',
  ),
  _MarketItem(
    category: 'Ev Lezzetleri',
    name: 'Zeytinyağlı Sarma',
    description:
        'Zeytinyağı, limon ve taze otlarla hazırlanan geleneksel sarma.',
    price: '₺150',
    cta: 'Sepete Ekle',
    ctaIcon: Icons.shopping_bag_rounded,
    icon: Icons.home_rounded,
    imageUrl:
        'https://images.unsplash.com/photo-1600891964599-f61ba0e24092?auto=format&fit=crop&w=900&q=80',
  ),
  _MarketItem(
    category: 'Ev Lezzetleri',
    name: 'Ev Baklavası',
    description: 'El açması yufka, fıstık ve geleneksel şerbet dengesi.',
    price: '₺220',
    cta: 'Sepete Ekle',
    ctaIcon: Icons.shopping_bag_rounded,
    icon: Icons.home_rounded,
    imageUrl:
        'https://images.unsplash.com/photo-1621939514649-280e2ee25f60?auto=format&fit=crop&w=900&q=80',
  ),
  _MarketItem(
    category: 'Ev Lezzetleri',
    name: 'El Açması Börek',
    description: 'Peynirli, çıtır ve geleneksel ev böreği lezzeti.',
    price: '₺150',
    cta: 'Sepete Ekle',
    ctaIcon: Icons.shopping_bag_rounded,
    icon: Icons.home_rounded,
    imageUrl:
        'https://images.unsplash.com/photo-1611765083444-a3ce30f1c885?auto=format&fit=crop&w=900&q=80',
  ),
];

const List<_MarketItem> _ustaSefItems = [
  _MarketItem(
    category: 'Usta Şefler',
    name: 'Şefin İmza Tabağı',
    description: 'Mevsimine özel, şefin imzasını taşıyan premium tabak.',
    price: '₺480’den başlayan',
    cta: 'Detayı Gör',
    ctaIcon: Icons.arrow_forward_rounded,
    icon: Icons.restaurant_menu_rounded,
    imageUrl:
        'https://images.unsplash.com/photo-1414235077428-338989a2e8c0?auto=format&fit=crop&w=900&q=80',
  ),
  _MarketItem(
    category: 'Usta Şefler',
    name: 'Özel Davet Menüsü',
    description: 'Özel günler ve davetler için kişiye özel menü.',
    price: '₺1.250’den başlayan',
    cta: 'Detayı Gör',
    ctaIcon: Icons.arrow_forward_rounded,
    icon: Icons.restaurant_menu_rounded,
    imageUrl:
        'https://images.unsplash.com/photo-1551218808-94e220e084d2?auto=format&fit=crop&w=900&q=80',
  ),
  _MarketItem(
    category: 'Usta Şefler',
    name: 'Catering / Özel Gün',
    description: 'Toplantı, kutlama ve özel organizasyonlar için hizmet.',
    price: '₺2.500’den başlayan',
    cta: 'Detayı Gör',
    ctaIcon: Icons.arrow_forward_rounded,
    icon: Icons.restaurant_menu_rounded,
    imageUrl:
        'https://images.unsplash.com/photo-1555244162-803834f70033?auto=format&fit=crop&w=900&q=80',
  ),
  _MarketItem(
    category: 'Usta Şefler',
    name: 'Gastronomi Atölyesi',
    description: 'Şeflerle uygulamalı yemek, sunum ve mutfak atölyeleri.',
    price: '₺850’den başlayan',
    cta: 'Detayı Gör',
    ctaIcon: Icons.arrow_forward_rounded,
    icon: Icons.restaurant_menu_rounded,
    imageUrl:
        'https://images.unsplash.com/photo-1556910103-1c02745aae4d?auto=format&fit=crop&w=900&q=80',
  ),
];

const List<_MarketItem> _restoranItems = [
  _MarketItem(
    category: 'Restoranlar',
    name: 'Günün Çorbası',
    description: 'Günlük taze, sıcak ve mevsimlik restoran başlangıcı.',
    price: '₺120',
    cta: 'Siparişe Başla',
    ctaIcon: Icons.room_service_rounded,
    icon: Icons.storefront_rounded,
    imageUrl:
        'https://images.unsplash.com/photo-1547592166-23ac45744acd?auto=format&fit=crop&w=900&q=80',
  ),
  _MarketItem(
    category: 'Restoranlar',
    name: 'Kaşarlı Pide',
    description: 'Taş fırından çıkan bol kaşarlı sıcak pide.',
    price: '₺170',
    cta: 'Siparişe Başla',
    ctaIcon: Icons.room_service_rounded,
    icon: Icons.storefront_rounded,
    imageUrl:
        'https://images.unsplash.com/photo-1633321702518-7feccafb94d5?auto=format&fit=crop&w=900&q=80',
  ),
  _MarketItem(
    category: 'Restoranlar',
    name: 'Izgara Ana Yemek',
    description: 'Izgara et, tavuk ve mevsim garnitürleriyle ana yemek.',
    price: '₺320’den başlayan',
    cta: 'Siparişe Başla',
    ctaIcon: Icons.room_service_rounded,
    icon: Icons.storefront_rounded,
    imageUrl:
        'https://images.unsplash.com/photo-1544025162-d76694265947?auto=format&fit=crop&w=900&q=80',
  ),
  _MarketItem(
    category: 'Restoranlar',
    name: 'Sütlü Tatlı',
    description: 'Geleneksel, hafif ve günlük hazırlanan tatlı seçkisi.',
    price: '₺110',
    cta: 'Siparişe Başla',
    ctaIcon: Icons.room_service_rounded,
    icon: Icons.storefront_rounded,
    imageUrl:
        'https://images.unsplash.com/photo-1488477181946-6428a0291777?auto=format&fit=crop&w=900&q=80',
  ),
];
