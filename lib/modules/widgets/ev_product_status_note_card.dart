import 'package:flutter/material.dart';

class EvProductStatusNoteCard extends StatelessWidget {
  final bool bugunHazirlandi;
  final bool sinirliAdet;
  final String? kalanAdet;
  final String? chefNote;

  const EvProductStatusNoteCard({
    super.key,
    required this.bugunHazirlandi,
    required this.sinirliAdet,
    this.kalanAdet,
    this.chefNote,
  });

  static const Color _gold = Color(0xFFFFB300);
  static const Color _card = Color(0xFF111111);
  static const Color _border = Color(0x26FFB300);

  @override
  Widget build(BuildContext context) {
    final bool hasAnyData =
        bugunHazirlandi || sinirliAdet || (chefNote?.trim().isNotEmpty == true);

    if (!hasAnyData) {
      return const SizedBox.shrink(); // boşsa hiç render etme
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.verified_outlined, color: _gold, size: 18),
              SizedBox(width: 8),
              Text(
                'GÜNLÜK DURUM',
                style: TextStyle(
                  color: _gold,
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // 🔥 CHIP’LER
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (bugunHazirlandi) _buildChip('🔥 Bugün hazırlandı'),
              if (sinirliAdet)
                _buildChip(
                  (kalanAdet != null && kalanAdet!.isNotEmpty)
                      ? '⚡ Son $kalanAdet adet'
                      : '⚡ Sınırlı adet',
                ),
            ],
          ),

          // 📝 ÜRETİCİ NOTU
          if (chefNote != null && chefNote!.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Üreticiden Not',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              chefNote!,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _gold.withValues(alpha: 0.4)),
        color: Colors.transparent,
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: _gold,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
