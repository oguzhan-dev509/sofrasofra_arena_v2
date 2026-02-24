import 'package:flutter/material.dart';
import 'odeme_sayfasi.dart';

class DukkanDetaySayfasi extends StatefulWidget {
  final String dukkanAdi;
  const DukkanDetaySayfasi({super.key, required this.dukkanAdi});

  @override
  State<DukkanDetaySayfasi> createState() => _DukkanDetaySayfasiState();
}

class _DukkanDetaySayfasiState extends State<DukkanDetaySayfasi> {
  String seciliYontem = "GEL AL";

  // 🍽️ SABİT MENÜ
  final List<Map<String, dynamic>> yemekler = [
    {
      "ad": "Ev Yapımı Kıymalı Mantı",
      "tarif": "40 yıllık reçete, süzme yoğurt ve özel tereyağlı sos ile.",
      "fiyat": 150.0,
      "img": "https://images.unsplash.com/photo-1543339308-43e59d6b73a6"
    },
    {
      "ad": "Zeytinyağlı Yaprak Sarma",
      "tarif": "İncecik kalem gibi sarılmış, bol limonlu ve taze nane aromalı.",
      "fiyat": 120.0,
      "img": "https://images.unsplash.com/photo-1601063411135-2623090fb585"
    },
    {
      "ad": "Ev Baklavası",
      "tarif": "70 kat ince hamur, bol cevizli ve tam kıvamında şerbetli.",
      "fiyat": 200.0,
      "img": "https://images.unsplash.com/photo-1519676867240-f031ee04a113"
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(widget.dukkanAdi,
            style: const TextStyle(
                color: Color(0xFFFFB300),
                fontWeight: FontWeight.bold,
                fontSize: 16)),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Color(0xFFFFB300)),
      ),
      body: Column(
        children: [
          _yontemSeciciPanel(), // Sabit Panel

          Expanded(
            child: SingleChildScrollView(
              // 🚀 Tüm sayfayı kaydırılabilir yapar
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 🖼️ SİLİKON VADİSİ 18'Lİ GALERİ
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: Text("DÜKKAN VİTRİNİ (18 KARE)",
                        style: TextStyle(
                            color: Color(0xFFFFB300),
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                            letterSpacing: 1.5)),
                  ),
                  _galeriBolumu(),

                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Divider(color: Colors.white10, thickness: 1),
                  ),

                  // 🍽️ LEZZET MENÜSÜ
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Text("GÜNLÜK TAZE MENÜ",
                        style: TextStyle(
                            color: Color(0xFFFFB300),
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                            letterSpacing: 1.5)),
                  ),
                  const SizedBox(height: 15),

                  // Yemek Kartlarını Buraya Diziyoruz
                  ...yemekler
                      .asMap()
                      .entries
                      .map((entry) => _musteriUrunKarti(entry.key))
                      .toList(),

                  const SizedBox(
                      height: 100), // Alt barın altında kalmaması için boşluk
                ],
              ),
            ),
          ),
        ],
      ),
      bottomSheet: _altSatinAlmaBari(), // Alt barı buraya sabitledik
    );
  }

  // 🖼️ 18 FOTOĞRAFLIK EFSANE GALERİ
  Widget _galeriBolumu() {
    return GridView.builder(
      shrinkWrap: true, // 🚀 Hata önleyici: İçeriğe göre boyunu ayarlar
      physics:
          const NeverScrollableScrollPhysics(), // Kaydırmayı ana sayfaya bırakır
      padding: const EdgeInsets.symmetric(horizontal: 20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, // 🚀 Senin istediğin 3'lü dizilim
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: 18, // 🚀 Tam 18 Fotoğraf Alanı
      itemBuilder: (context, index) => Container(
        decoration: BoxDecoration(
          color: const Color(0xFF111111),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white10),
        ),
        child: const Icon(Icons.add_a_photo_outlined,
            color: Colors.white12, size: 20),
      ),
    );
  }

  Widget _yontemSeciciPanel() {
    return Padding(
      padding: const EdgeInsets.all(15.0),
      child: Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(15)),
        child: Row(
          children: [
            _yontemButonu("GEL AL", Icons.storefront),
            _yontemButonu("GÖTÜR", Icons.delivery_dining),
          ],
        ),
      ),
    );
  }

  Widget _yontemButonu(String anaBaslik, IconData ikon) {
    bool aktif = seciliYontem == anaBaslik;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => seciliYontem = anaBaslik),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: aktif ? const Color(0xFFFFB300) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(ikon,
                  color: aktif ? Colors.black : Colors.white38, size: 18),
              const SizedBox(width: 8),
              Text(anaBaslik,
                  style: TextStyle(
                      color: aktif ? Colors.black : Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _musteriUrunKarti(int index) {
    var yemek = yemekler[index];
    double fiyat =
        (seciliYontem == "GEL AL") ? yemek["fiyat"] : yemek["fiyat"] + 40;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: const Color(0xFF0A0A0A),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.white10)),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(yemek["img"],
                width: 70, height: 70, fit: BoxFit.cover),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(yemek["ad"],
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14)),
                const SizedBox(height: 4),
                Text("${fiyat.toStringAsFixed(0)} TL",
                    style: const TextStyle(
                        color: Color(0xFFFFB300), fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const Icon(Icons.add_circle_outline,
              color: Color(0xFFFFB300), size: 28),
        ],
      ),
    );
  }

  Widget _altSatinAlmaBari() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
          color: Color(0xFF1A1A1A),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      child: ElevatedButton(
        onPressed: () => Navigator.push(context,
            MaterialPageRoute(builder: (context) => const OdemeSayfasi())),
        style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFFB300),
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10))),
        child: Text("ÖDEMEYE GEÇ (${seciliYontem})",
            style: const TextStyle(
                color: Colors.black, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
