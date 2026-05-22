import 'package:flutter/material.dart';

class RestoranStatusBadge extends StatelessWidget {
  const RestoranStatusBadge({
    super.key,
    required this.label,
    required this.icon,
    this.isGold = false,
  });

  final String label;
  final IconData icon;
  final bool isGold;

  static const Color _gold = Color(0xFFFFB300);

  @override
  Widget build(BuildContext context) {
    final Color baseColor = isGold ? _gold : Colors.white;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: baseColor.withValues(alpha: isGold ? 0.16 : 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: baseColor.withValues(alpha: isGold ? 0.45 : 0.16),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: isGold ? _gold : Colors.white70,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: isGold ? _gold : Colors.white70,
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
