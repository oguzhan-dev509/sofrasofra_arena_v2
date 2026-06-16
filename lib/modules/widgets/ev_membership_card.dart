import 'package:flutter/material.dart';

class EvMembershipCard extends StatelessWidget {
  const EvMembershipCard({super.key});

  static const Color _gold = Color(0xFFFFD54F);
  static const Color _panel = Color(0xFF151515);

  static const Color _muted = Color(0xFFB9B2A6);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: _panel,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: _gold.withValues(alpha: 0.20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'EV LEZZETLERİ PAKETLERİ',
            style: TextStyle(
              color: _gold,
              fontSize: 13,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Üreticiler için Free, Pro ve Premium görünürlük karşılaştırması.',
            style: TextStyle(
              color: _muted,
              fontSize: 14,
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 920;

              const cards = [
                EvPlanCard(
                  title: 'Ücretsiz',
                  active: true,
                  features: [
                    'Aylık: 0 TL',
                    'Komisyon: %8',
                    'PAYTR: %1,99',
                    '3 galeri fotoğrafı',
                    '0 video linki',
                    'Temel görünürlük',
                  ],
                ),
                EvPlanCard(
                  title: 'Pro',
                  features: [
                    'Aylık: 149 TL',
                    'Komisyon: %5',
                    'PAYTR: %1,99',
                    '8 galeri fotoğrafı',
                    '1 video linki',
                    'Daha güçlü görünürlük',
                  ],
                ),
                EvPlanCard(
                  title: 'Premium',
                  features: [
                    'Aylık: 299 TL',
                    'Komisyon: %2',
                    'PAYTR: %1,99',
                    '24 galeri fotoğrafı',
                    '3 video linki',
                    'Mahalle vitrin önceliği',
                  ],
                ),
              ];

              if (isWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: cards[0]),
                    const SizedBox(width: 12),
                    Expanded(child: cards[1]),
                    const SizedBox(width: 12),
                    Expanded(child: cards[2]),
                  ],
                );
              }

              return Column(
                children: [
                  cards[0],
                  const SizedBox(height: 12),
                  cards[1],
                  const SizedBox(height: 12),
                  cards[2],
                ],
              );
            },
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: const Text(
              'Not: Pro ve Premium yükseltme akışı yakında açılacak. Şimdilik üreticiler paket farklarını buradan net görebilir.',
              style: TextStyle(
                color: _muted,
                fontSize: 12.5,
                height: 1.45,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class EvPlanCard extends StatelessWidget {
  final String title;
  final List<String> features;
  final bool active;

  const EvPlanCard({
    super.key,
    required this.title,
    required this.features,
    this.active = false,
  });

  static const Color _gold = Color(0xFFFFD54F);
  static const Color _card = Color(0xFF181818);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 188),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: active ? _gold : Colors.white.withValues(alpha: 0.16),
          width: active ? 1.4 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (active) ...[
                const Icon(
                  Icons.verified_rounded,
                  color: _gold,
                  size: 18,
                ),
                const SizedBox(width: 7),
              ],
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: _gold,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...features.map(
            (feature) => Padding(
              padding: const EdgeInsets.only(bottom: 7),
              child: Text(
                '• $feature',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13.5,
                  height: 1.35,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
