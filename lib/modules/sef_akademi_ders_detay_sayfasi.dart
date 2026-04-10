import 'package:flutter/material.dart';
import 'package:sofrasofra_arena_v2/modules/sef_akademi_video_listesi.dart';

class SefAkademiDersDetaySayfasi extends StatelessWidget {
  final String dersId; // 🔥 EN KRİTİK
  final String baslik;
  final String aciklama;
  final String sure;
  final bool ucretsiz;
  final int videoSayisi;
  final String chefName;

  const SefAkademiDersDetaySayfasi({
    super.key,
    required this.dersId, // 🔥 BURASI ZORUNLU
    required this.baslik,
    required this.aciklama,
    required this.sure,
    required this.ucretsiz,
    required this.videoSayisi,
    required this.chefName,
  });

  static const Color gold = Color(0xFFFFB300);
  static const Color bg = Color(0xFF050505);
  static const Color card = Color(0xFF121212);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: gold),
        title: const Text(
          'DERS DETAYI',
          style: TextStyle(
            color: gold,
            fontSize: 13,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.1,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: card,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0x22FFB300)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  baslik.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: ucretsiz
                            ? Colors.green.withAlpha(24)
                            : Colors.white.withAlpha(10),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        ucretsiz ? 'ÜCRETSİZ' : 'PREMIUM',
                        style: TextStyle(
                          color: ucretsiz ? Colors.greenAccent : Colors.white70,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Icon(Icons.schedule, color: gold, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      sure,
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  aciklama,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: card,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0x22FFB300)),
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: gold.withAlpha(22),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child:
                      const Icon(Icons.ondemand_video, color: gold, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'DERS İÇERİĞİ',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '$videoSayisi video • $chefName',
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                // 🔥 KRİTİK FIX
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SefAkademiVideoListesi(
                      dersId: dersId, // ✅ DOĞRU OLAN
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: gold,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.play_arrow),
              label: Text(
                ucretsiz ? 'Dersi Aç' : 'İçeriği Gör',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
