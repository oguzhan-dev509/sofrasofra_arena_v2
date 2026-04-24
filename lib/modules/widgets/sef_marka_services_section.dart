import 'package:flutter/material.dart';
import 'package:sofrasofra_arena_v2/modules/consulting_requests_page.dart';

class SefMarkaServicesSection extends StatelessWidget {
  final String chefId;
  final String chefName;
  final String consultingText;
  final String privateDiningText;
  final String workshopText;
  final String cateringText;
  final String speakingText;

  const SefMarkaServicesSection({
    super.key,
    required this.chefId,
    required this.chefName,
    required this.consultingText,
    required this.privateDiningText,
    required this.workshopText,
    required this.cateringText,
    required this.speakingText,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'PREMIUM HİZMETLER',
      icon: Icons.local_fire_department_rounded,
      child: Column(
        children: [
          _ServiceRow(
            title: 'Danışmanlık',
            subtitle: consultingText,
            icon: Icons.support_agent_rounded,
            actionLabel: 'Talep Oluştur',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ConsultingRequestsPage(
                    chefId: chefId,
                    chefName: chefName,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          _ServiceRow(
            title: 'Private Dining',
            subtitle: privateDiningText,
            icon: Icons.dinner_dining_rounded,
          ),
          const SizedBox(height: 12),
          _ServiceRow(
            title: 'Workshop & Eğitim',
            subtitle: workshopText,
            icon: Icons.school_rounded,
          ),
          const SizedBox(height: 12),
          _ServiceRow(
            title: 'Kurumsal Davet & Catering',
            subtitle: cateringText,
            icon: Icons.corporate_fare_rounded,
          ),
          const SizedBox(height: 12),
          _ServiceRow(
            title: 'Konuşmacılık / Sahne',
            subtitle: speakingText,
            icon: Icons.mic_rounded,
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  static const Color gold = Color(0xFFFFB300);
  static const Color card = Color(0xFF121212);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: gold, size: 18),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: gold,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _ServiceRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onTap;

  const _ServiceRow({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.actionLabel,
    this.onTap,
  });

  static const Color gold = Color(0xFFFFB300);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: gold.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: gold, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 12,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (actionLabel != null && onTap != null) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: onTap,
                style: TextButton.styleFrom(
                  foregroundColor: gold,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: gold.withOpacity(0.35)),
                  ),
                ),
                icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                label: Text(
                  actionLabel!,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
