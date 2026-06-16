import 'package:flutter/material.dart';

class EvBelgeKontrolKategoriKutusu extends StatelessWidget {
  const EvBelgeKontrolKategoriKutusu({
    super.key,
    required this.seciliKategori,
    required this.onKategoriSecildi,
    this.enabled = true,
  });

  final String seciliKategori;
  final ValueChanged<String> onKategoriSecildi;
  final bool enabled;

  static const Color gold = Color(0xFFFFB300);

  static const List<String> belgeKontrolKategorileri = [
    'Erişte & Mantı',
    'Tarhana',
    'Ev Yapımı Kuru Gıda',
    'Reçel & Marmelat',
    'Turşu',
    'Kuru Bakliyat Hazırlıkları',
    'Hamur Ürünleri / Dondurulmuş Mantı',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF12100A),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: gold.withValues(alpha: 0.38)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.verified_user_outlined, color: gold, size: 22),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Belge ve Uygunluk Kontrolü Gerektiren Ev Ürünleri',
                  style: TextStyle(
                    color: gold,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Tarhana, erişte, mantı gibi bazı ev yapımı ürünler için satış öncesinde belge ve mevzuat uygunluğu kontrol edilir.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.78),
              fontSize: 12,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: belgeKontrolKategorileri.map((kategori) {
              final bool selected = seciliKategori == kategori;

              return ChoiceChip(
                label: Text(kategori),
                selected: selected,
                onSelected: enabled
                    ? (_) {
                        onKategoriSecildi(kategori);
                      }
                    : null,
                selectedColor: gold,
                backgroundColor: const Color(0xFF1D1D1D),
                disabledColor: const Color(0xFF1D1D1D),
                labelStyle: TextStyle(
                  color: selected ? Colors.black : Colors.white,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  fontSize: 12,
                ),
                side: BorderSide(
                  color: selected ? gold : Colors.white24,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
