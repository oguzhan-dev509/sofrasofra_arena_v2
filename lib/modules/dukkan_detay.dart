import 'package:flutter/material.dart';

// ignore_for_file: deprecated_member_use

class DukkanDetay extends StatelessWidget {
  final String dukkanAdi;
  final String kategori;

  const DukkanDetay(
      {super.key, required this.dukkanAdi, required this.kategori});

  // 📝 Dükkana Özel Ürün Listesi
  final List<Map<String, dynamic>> urunler = const [
    {
      "ad": "Saray Mantısı",
      "fiyat": 320,
      "ozellik": "El Açması, Dana Etli",
      "ikon": Icons.restaurant
    },
    {
      "ad": "Trüf Yağı",
      "fiyat": 850,
      "ozellik": "Siyah Trüf Özlü",
      "ikon": Icons.opacity
    },
    {
      "ad": "Özel Sos",
      "fiyat": 120,
      "ozellik": "Acı ve Tatlı Dengesi",
      "ikon": Icons.local_drink
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: Text(dukkanAdi.toUpperCase(),
            style: const TextStyle(
                color: Color(0xFFFFB300),
                fontWeight: FontWeight.bold,
                fontSize: 14)),
        iconTheme: const IconThemeData(color: Color(0xFFFFB300)),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart),
            onPressed: () {
              // 🚀 Sepetim sayfası henüz hazır değilse hata vermemesi için Snackveya geçici bir uyarı
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text("Sepet Modülü Hazırlanıyor..."),
                  backgroundColor: Colors.white12));
            },
          )
        ],
      ),
      body: Column(
        children: [
          // 🏮 DÜKKAN BANNER
          _buildDukkanBanner(),

          const Padding(
            padding: EdgeInsets.all(20.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text("RAFTAKİ LEZZETLER",
                  style: TextStyle(
                      color: Colors.white38,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                      fontSize: 10)),
            ),
          ),

          // 📦 ÜRÜN LİSTESİ
          Expanded(
            child: ListView.builder(
              itemCount: urunler.length,
              padding: const EdgeInsets.symmetric(horizontal: 15),
              itemBuilder: (context, index) =>
                  _urunSatiri(context, urunler[index]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDukkanBanner() {
    return Container(
      width: double.infinity,
      height: 150,
      decoration: BoxDecoration(
        gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [const Color(0xFFFFB300).withAlpha(50), Colors.black]),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.store, color: Color(0xFFFFB300), size: 50),
            const SizedBox(height: 10),
            Text("Arena'ya Hoş Geldiniz",
                style: TextStyle(
                    color: Colors.white.withAlpha(100), fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _urunSatiri(BuildContext context, Map<String, dynamic> urun) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Icon(urun['ikon'], color: const Color(0xFFFFB300), size: 30),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(urun['ad'],
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15)),
                Text(urun['ozellik'],
                    style:
                        const TextStyle(color: Colors.white38, fontSize: 11)),
              ],
            ),
          ),
          Column(
            children: [
              Text("${urun['fiyat']} TL",
                  style: const TextStyle(
                      color: Color(0xFFFFB300), fontWeight: FontWeight.bold)),
              const SizedBox(height: 5),
              // 🛒 SEPETE EKLE BUTONU
              InkWell(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text("${urun['ad']} Sepete Uçtu!"),
                        backgroundColor: const Color(0xFFFFB300),
                        duration: const Duration(seconds: 1)),
                  );
                },
                child: const Icon(Icons.add_circle,
                    color: Color(0xFFFFB300), size: 30),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
