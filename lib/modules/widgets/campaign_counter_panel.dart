import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class CampaignCounterPanel extends StatelessWidget {
  const CampaignCounterPanel({super.key});

  DocumentReference<Map<String, dynamic>> get _ref =>
      FirebaseFirestore.instance.collection('campaignSettings').doc('main');

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _ref.snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data() ?? {};

        final evKalan = _readInt(data['evKalan'], fallback: 100);
        final sefKalan = _readInt(data['sefKalan'], fallback: 100);
        final restoranKalan = _readInt(data['restoranKalan'], fallback: 100);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _TopCampaignBox(),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 720;

                final campaignCards = [
                  _CampaignCard(
                    title: 'Ev Lezzetleri',
                    headline: 'İlk 100 kurucu üreticiye 1 yıl ücretsiz',
                    subtitle: 'Evde pişen emeğinizi mahallede görünür kılın.',
                    remaining: evKalan,
                  ),
                  _CampaignCard(
                    title: 'Usta Şefler',
                    headline: 'İlk 100 kurucu şefe 1 yıl ücretsiz',
                    subtitle:
                        'İmza mutfağınızı, eğitiminizi ve uzmanlığınızı görünür kılın.',
                    remaining: sefKalan,
                  ),
                  _CampaignCard(
                    title: 'Restoranlar',
                    headline: 'İlk 100 kurucu restorana 1 yıl ücretsiz',
                    subtitle:
                        'Gel-Al ve Götür siparişlerinizi dijital vitrine taşıyın.',
                    remaining: restoranKalan,
                  ),
                ];

                if (isWide) {
                  return Row(
                    children: [
                      for (var i = 0; i < campaignCards.length; i++) ...[
                        Expanded(child: campaignCards[i]),
                        if (i != campaignCards.length - 1)
                          const SizedBox(width: 12),
                      ],
                    ],
                  );
                }

                return Column(
                  children: [
                    for (var i = 0; i < campaignCards.length; i++) ...[
                      campaignCards[i],
                      if (i != campaignCards.length - 1)
                        const SizedBox(height: 12),
                    ],
                  ],
                );
              },
            ),
          ],
        );
      },
    );
  }

  static int _readInt(dynamic value, {required int fallback}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return fallback;
  }
}

class _TopCampaignBox extends StatelessWidget {
  const _TopCampaignBox();

  static const Color _gold = Color(0xFFFFB300);
  static const Color _panel = Color(0xFF151515);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _panel,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _gold.withValues(alpha: 0.35)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SOFRASOFRA ABONELİK AVANTAJI',
            style: TextStyle(
              color: _gold,
              fontSize: 14,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.1,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Her yeni abone için 30 gün ücretsiz deneme süreci başladı.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Ev Lezzetleri, Usta Şefler ve Restoranlar için sınırlı süreli ücretsiz katılım fırsatı.',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _CampaignCard extends StatelessWidget {
  final String title;
  final String headline;
  final String subtitle;
  final int remaining;

  const _CampaignCard({
    required this.title,
    required this.headline,
    required this.subtitle,
    required this.remaining,
  });

  static const Color _gold = Color(0xFFFFB300);
  static const Color _panel = Color(0xFF151515);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _panel,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _gold.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              color: _gold,
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            headline,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 21,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text(
                'Kalan kontenjan',
                style: TextStyle(
                  color: Colors.white60,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 10),
              _NumberBox(value: remaining),
            ],
          ),
        ],
      ),
    );
  }
}

class _NumberBox extends StatelessWidget {
  final int value;

  const _NumberBox({required this.value});

  static const Color _gold = Color(0xFFFFB300);

  @override
  Widget build(BuildContext context) {
    final text = value.clamp(0, 999).toString().padLeft(3, '0');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _gold.withValues(alpha: 0.6)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: _gold,
          fontSize: 20,
          fontWeight: FontWeight.w900,
          letterSpacing: 2,
        ),
      ),
    );
  }
}
