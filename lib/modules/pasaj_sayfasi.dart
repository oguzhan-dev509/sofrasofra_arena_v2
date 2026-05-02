import 'package:flutter/material.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'dukkan_detay_sayfasi.dart';
import 'package:sofrasofra_arena_v2/data/arena_dummy_data.dart';

class PasajSayfasi extends StatelessWidget {
  final String kategori; // EV LEZZETLERİ, RESTORANLAR vs.
  const PasajSayfasi({super.key, required this.kategori});

  @override
  Widget build(BuildContext context) {
    // 🔍 HAVUZ FİLTRESİ: Sadece bu kategoriye ait dükkanları getir
    final dukkanlar = arenaUrunHavuzu.where((d) {
      return d["kategori"].toString().trim().toUpperCase() ==
          kategori.trim().toUpperCase();
    }).toList();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(kategori,
            style: const TextStyle(
                color: Color(0xFFFFB300),
                fontWeight: FontWeight.bold,
                fontSize: 16)),
        iconTheme: const IconThemeData(color: Color(0xFFFFB300)),
      ),
      body: dukkanlar.isEmpty
          ? _bosPasajUyari()
          : ListView.builder(
              padding: const EdgeInsets.all(15),
              itemCount: dukkanlar.length,
              itemBuilder: (context, index) {
                final d = dukkanlar[index];
                // 🚀 GÜVENLİK: Eğer ürün listesi boşsa hata vermemesi için kontrol
                final List urunler = d["urunler"] ?? [];
                final Map<String, dynamic> ilkUrun = urunler.isNotEmpty
                    ? urunler[0]
                    : {"resimYolu": "", "ad": "Henüz Ürün Yok"};

                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DukkanDetaySayfasi(
                              dukkanAdi: d["dukkan"] ?? "İsimsiz"),
                        ));
                  },
                  child: _dukkanKarti(d, ilkUrun),
                );
              },
            ),
    );
  }

  Widget _dukkanKarti(Map d, Map urun) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFFB300).withAlpha(50)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 📸 DÜKKANIN VİTRİN GÖRSELİ (İLK ÜRÜNÜN RESMİ)
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(19)),
            child: SizedBox(
              height: 160,
              width: double.infinity,
              child: urun["resimYolu"] != "" && urun["resimYolu"] != null
                  ? (kIsWeb
                      ? Image.network(urun["resimYolu"], fit: BoxFit.cover)
                      : Image.file(File(urun["resimYolu"]), fit: BoxFit.cover))
                  : const Center(
                      child:
                          Icon(Icons.store, color: Colors.white10, size: 50)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(15),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(d["dukkan"] ?? "İSİMSİZ DÜKKAN",
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18)),
                    const SizedBox(height: 5),
                    Text(d["altKategori"] ?? "Genel Lezzetler",
                        style: const TextStyle(
                            color: Colors.white38, fontSize: 12)),
                  ],
                ),
                const Icon(Icons.arrow_forward_ios,
                    color: Color(0xFFFFB300), size: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bosPasajUyari() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.restaurant_menu,
              color: Colors.white.withAlpha(20), size: 80),
          const SizedBox(height: 20),
          const Text("Bu pasajda henüz dükkan açılmadı.",
              style: TextStyle(color: Colors.white38, fontSize: 14)),
          const SizedBox(height: 10),
          const Text("Dükkanınızı açmak için Satıcı Girişi yapın!",
              style: TextStyle(color: Colors.white12, fontSize: 12)),
        ],
      ),
    );
  }
}
