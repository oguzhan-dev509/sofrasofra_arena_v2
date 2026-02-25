import 'package:flutter/material.dart';
import 'dukkan_detay_sayfasi.dart';

class RestoranlarVitrini extends StatefulWidget {
  const RestoranlarVitrini({super.key});

  @override
  State<RestoranlarVitrini> createState() => _RestoranlarVitriniState();
}

class _RestoranlarVitriniState extends State<RestoranlarVitrini> {
  // 🍽️ RESTORAN VERİ SETİ
  final List<Map<String, dynamic>> restoranlar = [
    {
      "ad": "Steakhouse Arena",
      "puan": "4.9",
      "sure": "30-40 dk",
      "img": "https://images.unsplash.com/photo-1514356665931-1582855ed26c"
    },
    {
      "ad": "Sushi Zen",
      "puan": "4.7",
      "sure": "45-55 dk",
      "img": "https://images.unsplash.com/photo-1579871494447-9811cf80d66c"
    },
    {
      "ad": "Bella Italia",
      "puan": "4.8",
      "sure": "25-35 dk",
      "img": "https://images.unsplash.com/photo-1537047902294-62a40c20a6ae"
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Color(0xFFFFB300)),
        title: const Text("ARENA RESTORANLARI",
            style: TextStyle(
                color: Color(0xFFFFB300),
                fontSize: 13,
                fontWeight: FontWeight.bold,
                letterSpacing: 2)),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(15),
        itemCount: restoranlar.length,
        itemBuilder: (context, index) {
          final res = restoranlar[index];
          return _restoranKarti(context, res);
        },
      ),
    );
  }

  Widget _restoranKarti(BuildContext context, Map<String, dynamic> res) {
    return GestureDetector(
      onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => DukkanDetaySayfasi(dukkanAdi: res["ad"]))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: const Color(0xFF0A0A0A),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withAlpha(15)),
        ),
        child: Column(
          children: [
            // 📸 RESTORAN GÖRSELİ
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
              child: Image.network(
                res["img"],
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (c, e, s) => Container(
                    height: 180,
                    color: Colors.white10,
                    child: const Icon(Icons.restaurant, color: Colors.white24)),
              ),
            ),
            // 📝 RESTORAN BİLGİLERİ
            Padding(
              padding: const EdgeInsets.all(15),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(res["ad"],
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15)),
                      const SizedBox(height: 5),
                      Text(res["sure"],
                          style: const TextStyle(
                              color: Colors.white38, fontSize: 11)),
                    ],
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                        color: const Color(0xFFFFB300),
                        borderRadius: BorderRadius.circular(10)),
                    child: Row(
                      children: [
                        const Icon(Icons.star, size: 14, color: Colors.black),
                        const SizedBox(width: 4),
                        Text(res["puan"],
                            style: const TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
