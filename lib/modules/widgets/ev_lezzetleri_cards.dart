import 'package:flutter/material.dart';

class EvKitchenCard extends StatelessWidget {
  final String name;
  final String district;
  final String category;
  final String imageUrl;
  final String badgeType;

  const EvKitchenCard({
    super.key,
    required this.name,
    required this.district,
    required this.category,
    required this.imageUrl,
    this.badgeType = 'none',
  });

  static const Color _gold = Color(0xFFFFB300);

  bool _isHttp(String s) => s.startsWith('http://') || s.startsWith('https://');

  bool get _hasBadge => badgeType.trim().isNotEmpty && badgeType != 'none';

  String get _badgeLabel {
    switch (badgeType) {
      case 'premium':
        return '👑 Premium';
      case 'trusted':
        return '⭐ Güvenilir';
      default:
        return '';
    }
  }

  Color get _badgeBg {
    switch (badgeType) {
      case 'premium':
        return _gold;
      case 'trusted':
        return const Color(0xFF2B2B2B);
      default:
        return Colors.transparent;
    }
  }

  Color get _badgeTextColor {
    switch (badgeType) {
      case 'premium':
        return Colors.black;
      case 'trusted':
        return _gold;
      default:
        return Colors.transparent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final image = imageUrl.trim();

    return Container(
      width: 230,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1B1B1B),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color:
              badgeType == 'premium' ? _gold.withOpacity(0.45) : Colors.white10,
        ),
        boxShadow: badgeType == 'premium'
            ? [
                BoxShadow(
                  color: _gold.withOpacity(0.10),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_hasBadge) ...[
            Align(
              alignment: Alignment.center,
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _badgeBg,
                  borderRadius: BorderRadius.circular(999),
                  border: badgeType == 'trusted'
                      ? Border.all(color: _gold.withOpacity(0.35))
                      : null,
                ),
                child: Text(
                  _badgeLabel,
                  style: TextStyle(
                    color: _badgeTextColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 10.5,
                  ),
                ),
              ),
            ),
          ],
          Container(
            width: 82,
            height: 82,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: _gold, width: 3),
            ),
            child: ClipOval(
              child: _isHttp(image)
                  ? Image.network(
                      image,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _placeholder(),
                    )
                  : _placeholder(),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            category,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _gold,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            district.isEmpty ? 'Mahalle Mutfağı' : district,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11.5,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _gold.withOpacity(0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Text(
              'Ev Yapımı',
              style: TextStyle(
                color: _gold,
                fontWeight: FontWeight.w700,
                fontSize: 10.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: Colors.grey.shade900,
      child: const Center(
        child: Icon(
          Icons.person_outline,
          color: Colors.white54,
          size: 34,
        ),
      ),
    );
  }
}

class EvPremiumProductCard extends StatelessWidget {
  final String title;
  final String kitchen;
  final String subtitle;
  final String category;
  final String locationText;
  final String priceText;
  final String imageUrl;
  final String badgeType;
  final VoidCallback onTap;
  final VoidCallback onAddToCart;

  const EvPremiumProductCard({
    super.key,
    required this.title,
    required this.kitchen,
    required this.subtitle,
    required this.category,
    required this.locationText,
    required this.priceText,
    required this.imageUrl,
    this.badgeType = 'none',
    required this.onTap,
    required this.onAddToCart,
  });

  static const Color _card = Color(0xFF202020);
  static const Color _gold = Color(0xFFFFB300);

  bool _isHttp(String s) => s.startsWith('http://') || s.startsWith('https://');

  bool get _hasBadge => badgeType.trim().isNotEmpty && badgeType != 'none';

  String get _badgeLabel {
    switch (badgeType) {
      case 'premium':
        return '👑 Premium Ev Lezzeti';
      case 'trusted':
        return '⭐ Güvenilir Mutfak';
      default:
        return '';
    }
  }

  Color get _badgeBg {
    switch (badgeType) {
      case 'premium':
        return _gold;
      case 'trusted':
        return const Color(0xFF151515);
      default:
        return Colors.transparent;
    }
  }

  Color get _badgeTextColor {
    switch (badgeType) {
      case 'premium':
        return Colors.black;
      case 'trusted':
        return _gold;
      default:
        return Colors.transparent;
    }
  }

  BoxBorder? get _badgeBorder {
    switch (badgeType) {
      case 'trusted':
        return Border.all(color: _gold.withOpacity(0.30));
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final safeImg = imageUrl.trim();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: Container(
          decoration: BoxDecoration(
            color: _card,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: badgeType == 'premium'
                  ? _gold.withOpacity(0.40)
                  : Colors.white10,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.22),
                blurRadius: 22,
                offset: const Offset(0, 10),
              ),
              if (badgeType == 'premium')
                BoxShadow(
                  color: _gold.withOpacity(0.08),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(28),
                    ),
                    child: AspectRatio(
                      aspectRatio: 16 / 10,
                      child: _isHttp(safeImg)
                          ? Image.network(
                              safeImg,
                              fit: BoxFit.cover,
                              filterQuality: FilterQuality.high,
                              errorBuilder: (_, __, ___) => _imgPlaceholder(),
                            )
                          : _imgPlaceholder(),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.68),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        category,
                        style: const TextStyle(
                          color: _gold,
                          fontWeight: FontWeight.w700,
                          fontSize: 11.5,
                        ),
                      ),
                    ),
                  ),
                  if (_hasBadge)
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: _badgeBg,
                          borderRadius: BorderRadius.circular(999),
                          border: _badgeBorder,
                        ),
                        child: Text(
                          _badgeLabel,
                          style: TextStyle(
                            color: _badgeTextColor,
                            fontWeight: FontWeight.w800,
                            fontSize: 10.8,
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    right: 12,
                    bottom: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: _gold,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text(
                        'Günlük Hazırlanır',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        kitchen,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: _gold,
                        ),
                      ),
                      if (locationText.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on_outlined,
                              size: 16,
                              color: Colors.white60,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                locationText,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  color: Colors.white60,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 6),
                      Expanded(
                        child: Text(
                          subtitle,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12.8,
                            height: 1.45,
                            color: Colors.white70,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          const EvMiniTag(text: 'Ev Yapımı'),
                          const EvMiniTag(text: 'Sıcak Lezzet'),
                          if (badgeType == 'premium')
                            const EvMiniTag(text: 'Premium'),
                          if (badgeType == 'trusted')
                            const EvMiniTag(text: 'Güvenilir'),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              priceText.isEmpty ? 'Fiyat yakında' : priceText,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color:
                                    priceText.isEmpty ? Colors.white38 : _gold,
                                fontWeight: FontWeight.w900,
                                fontSize: 20,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          InkWell(
                            onTap: onAddToCart,
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 11,
                              ),
                              decoration: BoxDecoration(
                                color: _gold,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.add_shopping_cart,
                                    size: 18,
                                    color: Colors.black,
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    'Sepete Ekle',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 12.5,
                                    ),
                                  ),
                                ],
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
        ),
      ),
    );
  }

  Widget _imgPlaceholder() {
    return Container(
      color: Colors.grey.shade900,
      child: const Center(
        child: Icon(
          Icons.image_outlined,
          size: 42,
          color: Colors.white30,
        ),
      ),
    );
  }
}

class EvMiniTag extends StatelessWidget {
  final String text;

  const EvMiniTag({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white10),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class EvHorizontalFoodCard extends StatelessWidget {
  final String title;
  final String kitchen;
  final String subtitle;
  final String locationText;
  final String priceText;
  final String imageUrl;
  final String badgeType;
  final VoidCallback onTap;
  final VoidCallback onAddToCart;

  const EvHorizontalFoodCard({
    super.key,
    required this.title,
    required this.kitchen,
    required this.subtitle,
    required this.locationText,
    required this.priceText,
    required this.imageUrl,
    this.badgeType = 'none',
    required this.onTap,
    required this.onAddToCart,
  });

  static const Color _gold = Color(0xFFFFB300);

  bool _isHttp(String s) => s.startsWith('http://') || s.startsWith('https://');

  bool get _hasBadge => badgeType.trim().isNotEmpty && badgeType != 'none';

  String get _badgeLabel {
    switch (badgeType) {
      case 'premium':
        return '👑 Premium';
      case 'trusted':
        return '⭐ Güvenilir';
      default:
        return '';
    }
  }

  Color get _badgeBg {
    switch (badgeType) {
      case 'premium':
        return _gold;
      case 'trusted':
        return const Color(0xFF151515);
      default:
        return Colors.transparent;
    }
  }

  Color get _badgeTextColor {
    switch (badgeType) {
      case 'premium':
        return Colors.black;
      case 'trusted':
        return _gold;
      default:
        return Colors.transparent;
    }
  }

  BoxBorder? get _badgeBorder {
    switch (badgeType) {
      case 'trusted':
        return Border.all(color: _gold.withOpacity(0.30));
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final safeImg = imageUrl.trim();

    return SizedBox(
      width: 260,
      child: Material(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: badgeType == 'premium'
                    ? _gold.withOpacity(0.38)
                    : Colors.white10,
              ),
              boxShadow: badgeType == 'premium'
                  ? [
                      BoxShadow(
                        color: _gold.withOpacity(0.08),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ]
                  : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                      child: SizedBox(
                        height: 145,
                        width: double.infinity,
                        child: _isHttp(safeImg)
                            ? Image.network(
                                safeImg,
                                fit: BoxFit.cover,
                                filterQuality: FilterQuality.high,
                                errorBuilder: (_, __, ___) => _imgPlaceholder(),
                              )
                            : _imgPlaceholder(),
                      ),
                    ),
                    if (_hasBadge)
                      Positioned(
                        top: 10,
                        right: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: _badgeBg,
                            borderRadius: BorderRadius.circular(999),
                            border: _badgeBorder,
                          ),
                          child: Text(
                            _badgeLabel,
                            style: TextStyle(
                              color: _badgeTextColor,
                              fontWeight: FontWeight.w800,
                              fontSize: 10.5,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          kitchen,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: _gold,
                            fontWeight: FontWeight.w700,
                            fontSize: 12.5,
                          ),
                        ),
                        if (locationText.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            locationText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white60,
                              fontSize: 11.5,
                            ),
                          ),
                        ],
                        const SizedBox(height: 4),
                        Expanded(
                          child: Text(
                            subtitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              height: 1.4,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                priceText,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: _gold,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                            InkWell(
                              onTap: onAddToCart,
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: _gold,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.add_shopping_cart,
                                  size: 18,
                                  color: Colors.black,
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
          ),
        ),
      ),
    );
  }

  Widget _imgPlaceholder() {
    return Container(
      color: Colors.grey.shade900,
      child: const Center(
        child: Icon(
          Icons.image_outlined,
          size: 36,
          color: Colors.white30,
        ),
      ),
    );
  }
}
