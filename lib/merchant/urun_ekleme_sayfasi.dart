import 'package:flutter/material.dart';
import '../main.dart';

class UrunEklemeSayfasi extends StatefulWidget {
  const UrunEklemeSayfasi({super.key});

  @override
  State<UrunEklemeSayfasi> createState() => _UrunEklemeSayfasiState();
}

class _UrunEklemeSayfasiState extends State<UrunEklemeSayfasi> {
  final TextEditingController _adController = TextEditingController();
  final TextEditingController _dukkanController = TextEditingController();
  final TextEditingController _fiyatController = TextEditingController();
  final TextEditingController _videoController = TextEditingController();

  // 📸 Satıcının seçtiği (temsili) 18 fotoğraf yuvası
  List<String> secilenFotograflar = [];

  void _dosyaGezgininiAc() {
    // 🚀 Masaüstü dosya seçici simülasyonu
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content:
            Text("Masaüstü Klasör Erişimi Sağlanıyor... (Max 18 Fotoğraf)")));
    setState(() {
      // Test amaçlı 3 örnek fotoğraf ekleyelim
      secilenFotograflar = [
        "https://images.unsplash.com/photo-1543339308-43e59d6b73a6",
        "https://images.unsplash.com/photo-1601063411135-2623090fb585",
        "https://images.unsplash.com/photo-1519676867240-f031ee04a113"
      ];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
          backgroundColor: Colors.black,
          title: const Text("PROFESYONEL VİTRİN YÖNETİMİ",
              style: TextStyle(color: Color(0xFFFFB300), fontSize: 13))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25),
        child: Column(
          children: [
            // 📸 MEDYA MERKEZİ
            Row(
              children: [
                _medyaKutusu("FOTOĞRAF EKLE (0/18)", Icons.add_photo_alternate,
                    Colors.blue, _dosyaGezgininiAc),
                const SizedBox(width: 15),
                _medyaKutusu("YOUTUBE LİNKİ", Icons.play_circle_fill,
                    Colors.red, _videoLinkGir),
              ],
            ),
            const SizedBox(height: 30),
            _input("DÜKKAN KİMLİĞİ", _dukkanController),
            _input("ÜRÜN / BAŞLIK", _adController),
            _input("FİYAT", _fiyatController),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _pazaraSur,
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFB300)),
                child: const Text("ARENA'DA CANLI YAYINA AL",
                    style: TextStyle(
                        color: Colors.black, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _videoLinkGir() {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: const Color(0xFF111111),
        title: const Text("YouTube Video URL",
            style: TextStyle(color: Colors.white, fontSize: 14)),
        content: TextField(
            controller: _videoController,
            style: const TextStyle(color: Colors.white)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c), child: const Text("KAYDET"))
        ],
      ),
    );
  }

  void _pazaraSur() {
    arenaUrunHavuzu.add({
      "ad": _adController.text,
      "dukkan": _dukkanController.text,
      "fiyat": _fiyatController.text,
      "img": secilenFotograflar.isNotEmpty
          ? secilenFotograflar[0]
          : "https://images.unsplash.com/photo-1546069901-ba9599a7e63c",
      "videoUrl": _videoController.text,
      "galeri": secilenFotograflar,
      "tip": "Ev Lezzetleri"
    });
    Navigator.pop(context);
  }

  Widget _medyaKutusu(String t, IconData i, Color c, VoidCallback o) {
    return Expanded(
      child: InkWell(
        onTap: o,
        child: Container(
          height: 100,
          decoration: BoxDecoration(
              color: const Color(0xFF0A0A0A),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: c.withOpacity(0.3))),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(i, color: c, size: 32),
            const SizedBox(height: 8),
            Text(t,
                style: TextStyle(
                    color: c, fontSize: 9, fontWeight: FontWeight.bold))
          ]),
        ),
      ),
    );
  }

  Widget _input(String l, TextEditingController c) {
    return TextField(
        controller: c,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
            labelText: l,
            labelStyle: const TextStyle(color: Colors.white24, fontSize: 11)));
  }
}
