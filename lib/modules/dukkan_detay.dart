import 'package:flutter/material.dart';

import 'package:sofrasofra_arena_v2/modules/sepetim.dart';

class DukkanDetay extends StatelessWidget {
  final String dukkanAdi;
  final String kategori;

  const DukkanDetay(
      {super.key, required this.dukkanAdi, required this.kategori});

  // 📝 Dükkana Özel Ürün Listesi - TAMİR EDİLDİ
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
    }, // ✨ Liquor yerine local_drink
  ];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(dukkanAdi.toUpperCase(),
            style: const TextStyle(
                color: Color(0xFFFFB300), fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Color(0xFFFFB300)),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (context) => const Sepetim())),
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
                      letterSpacing: 1.5)),
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
            colors: [const Color(0xFFFFB300).withOpacity(0.2), Colors.black]),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.store, color: Color(0xFFFFB300), size: 50),
            const SizedBox(height: 10),
            Text("Hoş Geldiniz",
                style: TextStyle(color: Colors.white.withOpacity(0.5))),
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
                        fontSize: 16)),
                Text(urun['ozellik'],
                    style:
                        const TextStyle(color: Colors.white38, fontSize: 12)),
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
                        backgroundColor: const Color(0xFFFFB300)),
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
