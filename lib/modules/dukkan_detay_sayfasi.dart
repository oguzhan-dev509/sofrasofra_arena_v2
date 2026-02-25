import 'package:flutter/material.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../main.dart';

class DukkanDetaySayfasi extends StatelessWidget {
  final String dukkanAdi;
  const DukkanDetaySayfasi({super.key, required this.dukkanAdi});

  @override
  Widget build(BuildContext context) {
    // 🔍 Havuzdan en güncel veriyi çekiyoruz
    final dukkanVerisi = arenaUrunHavuzu.lastWhere(
      (element) => element["dukkan"] == dukkanAdi,
      orElse: () => {"urunler": [], "kategori": ""},
    );
    final List urunler = dukkanVerisi["urunler"];

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFFFFB300)),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(dukkanAdi.toUpperCase(),
                style: const TextStyle(
                    color: Color(0xFFFFB300),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    letterSpacing: 2)),
            Text(dukkanVerisi["kategori"].toString().toUpperCase(),
                style: const TextStyle(color: Colors.white24, fontSize: 9)),
          ],
        ),
      ),
      body: urunler.isEmpty
          ? const Center(
              child: Text("Lezzetler hazırlanıyor...",
                  style: TextStyle(color: Colors.white10)))
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
              itemCount: urunler.length,
              itemBuilder: (context, index) =>
                  _premiumYemekKarti(context, urunler[index]),
            ),
    );
  }

  Widget _premiumYemekKarti(BuildContext context, Map urun) {
    return Container(
      margin: const EdgeInsets.only(bottom: 30),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 📸 ALTIN ÇERÇEVELİ GÖRSEL
          Container(
            width: 130, // 🚀 Görseli biraz daha büyüttük
            height: 130,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFFFB300), width: 2),
              boxShadow: [
                BoxShadow(
                    color: const Color(0xFFFFB300).withAlpha(40),
                    blurRadius: 15)
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: urun["resimYolu"] != ""
                  ? (kIsWeb
                      ? Image.network(urun["resimYolu"], fit: BoxFit.cover)
                      : Image.file(File(urun["resimYolu"]), fit: BoxFit.cover))
                  : const Icon(Icons.restaurant, color: Colors.white10),
            ),
          ),
          const SizedBox(width: 20),

          // 📝 DETAYLAR VE FİYATLAR (TAM SENİN İSTEDİĞİN GİBİ)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(urun["ad"].toString().toUpperCase(),
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        letterSpacing: 1)),
                const SizedBox(height: 8),
                Text(urun["tarif"],
                    maxLines: 3,
                    style: const TextStyle(
                        color: Colors.white54, fontSize: 11, height: 1.4)),
                const SizedBox(height: 15),
                Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Gel-Al: ${urun["gelAlFiyat"]} ₺",
                            style: const TextStyle(
                                color: Color(0xFFFFB300),
                                fontWeight: FontWeight.bold,
                                fontSize: 13)),
                        const SizedBox(height: 4),
                        Text("Götür: ${urun["goturFiyat"]} ₺",
                            style: const TextStyle(
                                color: Colors.white38, fontSize: 11)),
                      ],
                    ),
                    const Spacer(),
                    // ➕ O MEŞHUR ARTI BUTONU
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: const Color(0xFFFFB300), width: 1.5),
                      ),
                      child: const Icon(Icons.add,
                          color: Color(0xFFFFB300), size: 24),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
