import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SefAkademiDersleri extends StatelessWidget {
  final String chefId;

  const SefAkademiDersleri({
    super.key,
    required this.chefId,
  });

  static const Color gold = Color(0xFFFFB300);

  String _safe(dynamic value, {String fallback = ''}) {
    if (value == null) return fallback;
    final text = value.toString().trim();
    return text.isEmpty ? fallback : text;
  }

  List<Map<String, dynamic>> _fallbackLessons() {
    switch (chefId) {
      case 'chef_mehmet_usta':
        return [
          {
            'baslik': 'İtalyan Sos Teknikleri',
            'sure': '120 dk',
            'kategori': 'İtalyan Mutfağı',
            'seviye': 'Orta',
            'ucret': '399 TL',
            'kilitliMi': false,
          },
          {
            'baslik': 'Genel Türk Mutfağı',
            'sure': '180 dk',
            'kategori': 'Türk Mutfağı',
            'seviye': 'Başlangıç',
            'ucret': '299 TL',
            'kilitliMi': false,
          },
        ];

      case 'chef_ayse_hanim':
        return [
          {
            'baslik': 'Fine Dining Sunum Teknikleri',
            'sure': '90 dk',
            'kategori': 'Fine Dining',
            'seviye': 'Orta',
            'ucret': '449 TL',
            'kilitliMi': false,
          },
          {
            'baslik': 'İmza Menü Kurgusu',
            'sure': '110 dk',
            'kategori': 'İmza Menü',
            'seviye': 'İleri',
            'ucret': '549 TL',
            'kilitliMi': true,
          },
        ];

      case 'chef_elif_nur':
        return [
          {
            'baslik': 'Modern Pastacılık Temelleri',
            'sure': '100 dk',
            'kategori': 'Pastacılık',
            'seviye': 'Başlangıç',
            'ucret': '329 TL',
            'kilitliMi': false,
          },
          {
            'baslik': 'Profesyonel Tatlı Tabaklama',
            'sure': '95 dk',
            'kategori': 'Dessert Plating',
            'seviye': 'Orta',
            'ucret': '389 TL',
            'kilitliMi': true,
          },
        ];

      default:
        return [
          {
            'baslik': 'Şef Akademi Giriş Dersi',
            'sure': '60 dk',
            'kategori': 'Akademi',
            'seviye': 'Genel',
            'ucret': 'Bilgi yakında',
            'kilitliMi': false,
          },
        ];
    }
  }

  Widget _lessonCard(Map<String, dynamic> m) {
    final baslik = _safe(
      m['baslik'] ?? m['title'],
      fallback: 'İsimsiz Eğitim',
    );

    final sure = _safe(
      m['sure'] ?? m['duration'],
      fallback: 'Süre belirtilmedi',
    );

    final kategori = _safe(
      m['kategori'] ?? m['category'],
      fallback: 'Akademi',
    );

    final seviye = _safe(
      m['seviye'] ?? m['level'],
      fallback: 'Genel',
    );

    final ucret = _safe(
      m['ucret'] ?? m['price'],
      fallback: 'Bilgi yakında',
    );

    final kilitliMi = (m['kilitliMi'] ?? m['isLocked'] ?? true) == true;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: gold.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: gold.withOpacity(0.35)),
            ),
            child: const Icon(
              Icons.play_circle_fill,
              color: gold,
              size: 30,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  baslik,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _miniTag(kategori),
                    _miniTag(seviye),
                    _miniTag(sure),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  ucret,
                  style: const TextStyle(
                    color: gold,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            kilitliMi ? Icons.lock_outline : Icons.lock_open,
            color: kilitliMi ? Colors.white24 : Colors.greenAccent,
            size: 18,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fallbackLessons = _fallbackLessons();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: gold),
        title: const Text(
          "AKADEMİ DERS PROGRAMI",
          style: TextStyle(
            color: gold,
            fontSize: 13,
            fontWeight: FontWeight.bold,
            letterSpacing: .6,
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('dersler')
            .where('chefId', isEqualTo: chefId)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return ListView(
              padding: const EdgeInsets.all(15),
              children: [
                Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: const Text(
                    'Canlı ders verisi okunamadı. Yedek içerik gösteriliyor.',
                    style: TextStyle(
                      color: Colors.white70,
                      height: 1.5,
                    ),
                  ),
                ),
                ...fallbackLessons.map(_lessonCard),
              ],
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: gold),
            );
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return ListView(
              padding: const EdgeInsets.all(15),
              children: [
                Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: const Text(
                    'Canlı ders kaydı bulunamadı. Yedek içerik gösteriliyor.',
                    style: TextStyle(
                      color: Colors.white70,
                      height: 1.5,
                    ),
                  ),
                ),
                ...fallbackLessons.map(_lessonCard),
              ],
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(15),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final m = docs[index].data();
              return _lessonCard(m);
            },
          );
        },
      ),
    );
  }

  Widget _miniTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white60,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
