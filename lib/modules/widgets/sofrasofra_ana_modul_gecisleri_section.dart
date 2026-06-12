import 'package:flutter/material.dart';
import 'package:sofrasofra_arena_v2/modules/restoranlar/restoran_vitrini.dart';
import 'package:sofrasofra_arena_v2/modules/vitrinler/ev_lezzetleri_vitrini.dart';
import 'package:sofrasofra_arena_v2/modules/vitrinler/sef_vitrini_v2.dart';

class SofrasofraAnaModulGecisleriSection extends StatelessWidget {
  const SofrasofraAnaModulGecisleriSection({super.key});

  static const Color _bg = Color(0xFF0B0B0B);
  static const Color _card = Color(0xFF151515);
  static const Color _gold = Color(0xFFD4AF37);
  static const Color _textSoft = Color(0xFFE8E0C8);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: _gold.withOpacity(.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Sofrasofra’nın üç ana alanı',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Ev Lezzetleri, Usta Şefler ve Restoranlar arasında hızlıca keşfe çıkın.',
            style: TextStyle(
              color: _textSoft,
              fontSize: 14,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 860;

              final cards = [
                _ModuleCard(
                  title: 'Ev Lezzetleri',
                  badge: 'Ev mutfağından sofraya',
                  description: 'Ev mutfağından gelen ürünleri keşfedin.',
                  buttonText: 'Ev Lezzetleri’ne Git',
                  icon: Icons.home_rounded,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const EvLezzetleriVitrini(
                          city: 'İstanbul',
                          district: 'Güngören',
                        ),
                      ),
                    );
                  },
                ),
                _ModuleCard(
                  title: 'Usta Şefler',
                  badge: 'Şef vitrinleri',
                  description:
                      'Şef vitrinleri, imza tabakları ve hizmetleri inceleyin.',
                  buttonText: 'Usta Şefleri Keşfet',
                  icon: Icons.workspace_premium_rounded,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const SefVitriniV2(),
                      ),
                    );
                  },
                ),
                _ModuleCard(
                  title: 'Restoranlar',
                  badge: 'Online sipariş',
                  description:
                      'Mahalle restoranlarını ve online sipariş seçeneklerini görün.',
                  buttonText: 'Restoranlara Git',
                  icon: Icons.restaurant_menu_rounded,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const PremiumRestoranVitrini(),
                      ),
                    );
                  },
                ),
              ];

              if (isWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (int i = 0; i < cards.length; i++) ...[
                      Expanded(child: cards[i]),
                      if (i != cards.length - 1) const SizedBox(width: 14),
                    ],
                  ],
                );
              }

              return Column(
                children: [
                  for (int i = 0; i < cards.length; i++) ...[
                    cards[i],
                    if (i != cards.length - 1) const SizedBox(height: 12),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ModuleCard extends StatelessWidget {
  const _ModuleCard({
    required this.title,
    required this.badge,
    required this.description,
    required this.buttonText,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String badge;
  final String description;
  final String buttonText;
  final IconData icon;
  final VoidCallback onTap;

  static const Color _card = SofrasofraAnaModulGecisleriSection._card;
  static const Color _gold = SofrasofraAnaModulGecisleriSection._gold;
  static const Color _textSoft = SofrasofraAnaModulGecisleriSection._textSoft;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white.withOpacity(.08)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Chip(
              label: Text(badge),
              backgroundColor: Colors.black.withOpacity(.18),
              side: const BorderSide(color: _gold),
              labelStyle: const TextStyle(
                color: _gold,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 14),
            Icon(icon, color: _gold, size: 30),
            const SizedBox(height: 14),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 19,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: const TextStyle(
                color: _textSoft,
                fontSize: 13,
                height: 1.42,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: onTap,
                style: OutlinedButton.styleFrom(
                  foregroundColor: _gold,
                  side: const BorderSide(color: _gold),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 13,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  buttonText,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
