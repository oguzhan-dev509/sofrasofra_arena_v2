import 'package:flutter/material.dart';
import 'package:sofrasofra_arena_v2/modules/sef_itibar_sayfasi.dart';

class SefCateringSection extends StatelessWidget {
  const SefCateringSection({super.key});

  static const Color gold = Color(0xFFFFB300);

  Widget _title(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: gold,
        fontSize: 12,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.6,
      ),
    );
  }

  Widget _chip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(8),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white10),
      ),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF121212),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0x22FFB300)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _title('KURUMSAL DAVETLER / CATERING'),
          const SizedBox(height: 10),
          const Text(
            'Özel davetler, marka etkinlikleri ve butik organizasyonlar için '
            'şef imzası taşıyan gastronomi deneyimleri sunulur.',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13,
              height: 1.55,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _chip('Kurumsal Etkinlik'),
              _chip('Özel Davet'),
              _chip('Butik Catering'),
              _chip('Chef’s Table'),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            '• Marka lansmanları ve VIP davetler\n'
            '• Kişiye özel menü planlama\n'
            '• Lokasyon bağımsız servis organizasyonu\n'
            '• Profesyonel ekip ve sunum standardı',
            style: TextStyle(
              color: Colors.white60,
              fontSize: 12,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
