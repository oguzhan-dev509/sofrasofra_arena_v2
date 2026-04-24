import 'package:flutter/material.dart';

class SefMarkaHeroSection extends StatelessWidget {
  final String profileName;
  final String heroTagline;
  final String heroDescription;

  const SefMarkaHeroSection({
    super.key,
    required this.profileName,
    required this.heroTagline,
    required this.heroDescription,
  });

  static const Color gold = Color(0xFFFFB300);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            gold.withOpacity(0.14),
            Colors.transparent,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withOpacity(0.10),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.workspace_premium_rounded, color: gold, size: 18),
              SizedBox(width: 8),
              Text(
                'MARKA KİMLİĞİ & KARİYER VİTRİNİ',
                style: TextStyle(
                  color: gold,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            profileName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w900,
              height: 1.08,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            heroTagline,
            style: const TextStyle(
              color: gold,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            heroDescription,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12.2,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: const [
              _MetricChip(
                icon: Icons.restaurant_menu_rounded,
                label: 'İmza Tabaklar',
                value: '12+',
              ),
              _MetricChip(
                icon: Icons.groups_rounded,
                label: 'Etkinlik / Davet',
                value: '40+',
              ),
              _MetricChip(
                icon: Icons.school_rounded,
                label: 'Eğitim / Workshop',
                value: '25+',
              ),
              _MetricChip(
                icon: Icons.public_rounded,
                label: 'İş Birliği',
                value: '8+',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _MetricChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  static const Color gold = Color(0xFFFFB300);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.10)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: gold, size: 16),
          const SizedBox(width: 8),
          Text(
            '$label • $value',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
