import 'package:flutter/material.dart';

class SepetKontrol {
  // 💎 SINGLETON YAPISI: Tüm sayfalardan aynı kasaya erişim sağlar
  static final SepetKontrol _nesne = SepetKontrol._dahili();
  factory SepetKontrol() => _nesne;
  SepetKontrol._dahili();

  // 📦 SEPET LİSTESİ
  final List<Map<String, dynamic>> sepetim = [];

  // ➕ ÜRÜN EKLEME FONKSİYONU
  void sepeteEkle(String ad, int fiyat, IconData ikon) {
    sepetim.add({
      "ad": ad,
      "fiyat": fiyat,
      "ikon": ikon,
    });
    debugPrint("Arena Kasası: $ad eklendi. Toplam: ${sepetim.length} ürün.");
  }

  // 💰 TOPLAM TUTAR HESAPLAMA
  int get toplamTutar {
    int toplam = 0;
    for (var urun in sepetim) {
      toplam += urun['fiyat'] as int;
    }
    return toplam;
  }

  // 🗑️ SEPETİ SIFIRLAMA
  void sepetiBosalt() {
    sepetim.clear();
  }
}
