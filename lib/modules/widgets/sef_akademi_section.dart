import 'package:flutter/material.dart';
import 'package:sofrasofra_arena_v2/modules/sef_akademi_ders_detay_sayfasi.dart';

class SefAkademiSection extends StatefulWidget {
  const SefAkademiSection({super.key});

  @override
  State<SefAkademiSection> createState() => _SefAkademiSectionState();
}

class _SefAkademiSectionState extends State<SefAkademiSection> {
  String selectedCategory = 'Osmanlı';

  final List<String> categories = [
    'Osmanlı',
    'Tabak Tasarım',
    'Dünya Mutfağı',
    'Maliyet',
  ];

  final Map<String, List<Map<String, dynamic>>> lessons = {
    'Osmanlı': [
      {
        'dersId': 'ders_001',
        'title': 'Osmanlı Mutfağına Giriş',
        'desc': 'Saray mutfağının temel yapısı',
        'sure': '12 dk',
        'ucretsiz': true,
        'videoSayisi': 3,
        'chefName': 'Usta Şef',
      },
      {
        'dersId': 'ders_002',
        'title': 'Et ve Baharat Kullanımı',
        'desc': 'Klasik tariflerde denge',
        'sure': '12 dk',
        'ucretsiz': true,
        'videoSayisi': 3,
        'chefName': 'Usta Şef',
      },
      {
        'dersId': 'ders_003',
        'title': 'Saray Sunum Teknikleri',
        'desc': 'Sunum ve servis estetiği',
        'sure': '12 dk',
        'ucretsiz': true,
        'videoSayisi': 3,
        'chefName': 'Usta Şef',
      },
    ],
    'Tabak Tasarım': [
      {
        'dersId': 'tabak-001', // <- Firestore gerçek doc ID ile değiştir
        'title': 'Modern Tabak Dizaynı',
        'desc': 'Minimalist sunum',
        'sure': '12 dk',
        'ucretsiz': true,
        'videoSayisi': 3,
        'chefName': 'Şef Akademisi',
      },
      {
        'dersId': 'tabak-002', // <- Firestore gerçek doc ID ile değiştir
        'title': 'Renk ve Doku Kullanımı',
        'desc': 'Görsel denge kurma',
        'sure': '12 dk',
        'ucretsiz': true,
        'videoSayisi': 3,
        'chefName': 'Şef Akademisi',
      },
      {
        'dersId': 'tabak-003', // <- Firestore gerçek doc ID ile değiştir
        'title': 'Fine Dining Sunum',
        'desc': 'Premium plating teknikleri',
        'sure': '12 dk',
        'ucretsiz': true,
        'videoSayisi': 3,
        'chefName': 'Şef Akademisi',
      },
    ],
    'Dünya Mutfağı': [
      {
        'dersId': 'dunya-001', // <- Firestore gerçek doc ID ile değiştir
        'title': 'Fransız Mutfağı Temelleri',
        'desc': 'Klasik teknikler',
        'sure': '12 dk',
        'ucretsiz': true,
        'videoSayisi': 3,
        'chefName': 'Şef Akademisi',
      },
      {
        'dersId': 'dunya-002', // <- Firestore gerçek doc ID ile değiştir
        'title': 'İtalyan Lezzet Dengesi',
        'desc': 'Malzeme uyumu',
        'sure': '12 dk',
        'ucretsiz': true,
        'videoSayisi': 3,
        'chefName': 'Şef Akademisi',
      },
      {
        'dersId': 'dunya-003', // <- Firestore gerçek doc ID ile değiştir
        'title': 'Asya Mutfağı Giriş',
        'desc': 'Aroma ve teknik',
        'sure': '12 dk',
        'ucretsiz': true,
        'videoSayisi': 3,
        'chefName': 'Şef Akademisi',
      },
    ],
    'Maliyet': [
      {
        'dersId': 'maliyet-001', // <- Firestore gerçek doc ID ile değiştir
        'title': 'Food Cost Hesaplama',
        'desc': 'Maliyet kontrolü',
        'sure': '12 dk',
        'ucretsiz': true,
        'videoSayisi': 3,
        'chefName': 'Şef Akademisi',
      },
      {
        'dersId': 'maliyet-002', // <- Firestore gerçek doc ID ile değiştir
        'title': 'Menü Fiyatlandırma',
        'desc': 'Karlılık stratejisi',
        'sure': '12 dk',
        'ucretsiz': true,
        'videoSayisi': 3,
        'chefName': 'Şef Akademisi',
      },
      {
        'dersId': 'maliyet-003', // <- Firestore gerçek doc ID ile değiştir
        'title': 'İşletme Giderleri',
        'desc': 'Operasyon yönetimi',
        'sure': '12 dk',
        'ucretsiz': true,
        'videoSayisi': 3,
        'chefName': 'Şef Akademisi',
      },
    ],
  };

  @override
  Widget build(BuildContext context) {
    final selectedLessons =
        lessons[selectedCategory] ?? <Map<String, dynamic>>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: categories.map((cat) {
            final isSelected = cat == selectedCategory;

            return ChoiceChip(
              label: Text(cat),
              selected: isSelected,
              onSelected: (_) {
                setState(() {
                  selectedCategory = cat;
                });
              },
              selectedColor: const Color(0xFFFFB300),
              backgroundColor: const Color(0xFF1E1E1E),
              labelStyle: TextStyle(
                color: isSelected ? Colors.black : Colors.white,
                fontWeight: FontWeight.w600,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
                side: BorderSide(
                  color: isSelected
                      ? const Color(0xFFFFB300)
                      : Colors.white.withOpacity(0.08),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        Column(
          children: selectedLessons.map((lesson) {
            final dersId = (lesson['dersId'] ?? '').toString();
            final title = (lesson['title'] ?? '').toString();
            final desc = (lesson['desc'] ?? '').toString();
            final sure = (lesson['sure'] ?? '12 dk').toString();
            final ucretsiz = lesson['ucretsiz'] == true;

            final videoSayisi = (lesson['videoSayisi'] is int)
                ? lesson['videoSayisi'] as int
                : int.tryParse(lesson['videoSayisi']?.toString() ?? '0') ?? 0;

            final chefName = (lesson['chefName'] ?? 'Şef Akademisi').toString();

            if (dersId.isEmpty) {
              debugPrint('⚠️ dersId boş geldi!');
            }
            return InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SefAkademiDersDetaySayfasi(
                      dersId: dersId,
                      baslik: title,
                      aciklama: desc,
                      sure: sure,
                      ucretsiz: ucretsiz,
                      videoSayisi: videoSayisi,
                      chefName: chefName,
                    ),
                  ),
                );
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF121212),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.05),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.play_circle_outline,
                      color: Color(0xFFFFB300),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            desc,
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: Colors.white38,
                      size: 14,
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
