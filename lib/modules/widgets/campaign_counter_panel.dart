import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class CampaignCounterPanel extends StatelessWidget {
  const CampaignCounterPanel({super.key});

  static const Color _gold = Color(0xFFFFB300);
  static const Color _panel = Color(0xFF151515);

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

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _TopCampaignBox(),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 720;

                final cards = [
                  Expanded(
                    child: _CampaignCard(
                      title: 'Ev Lezzetleri',
                      headline: 'İlk 100 kurucu üreticiye 1 yıl ücretsiz',
                      subtitle: 'Evde pişen emeğinizi mahallede görünür kılın.',
                      remaining: evKalan,
                    ),
                  ),
                  const SizedBox(width: 12, height: 12),
                  Expanded(
                    child: _CampaignCard(
                      title: 'Usta Şefler',
                      headline: 'İlk 100 kurucu şefe 1 yıl ücretsiz',
                      subtitle:
                          'İmza mutfağınızı, eğitiminizi ve uzmanlığınızı görünür kılın.',
                      remaining: sefKalan,
                    ),
                  ),
                ];

                if (isWide) {
                  return Row(children: cards);
                }

                return Column(
                  children: [
                    _CampaignCard(
                      title: 'Ev Lezzetleri',
                      headline: 'İlk 100 üreticiye 1 yıl ücretsiz',
                      subtitle: 'Ev mutfağınızı kazanca dönüştürün.',
                      remaining: evKalan,
                    ),
                    const SizedBox(height: 12),
                    _CampaignCard(
                      title: 'Usta Şefler',
                      headline: 'İlk 100 şefe 1 yıl ücretsiz',
                      subtitle: 'Markanızı ve bilginizi gelire dönüştürün.',
                      remaining: sefKalan,
                    ),
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
            'YAYIN ÖNCESİ KURUCU KONTENJAN',
            style: TextStyle(
              color: _gold,
              fontSize: 14,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.1,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Kurucu üretici ve kurucu şef başvuruları açıldı.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Ev Lezzetleri ve Usta Şefler için sınırlı süre ücretsiz katılım fırsatı.',
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
