import 'package:flutter/material.dart';
import 'kategori_sayfasi.dart';
import 'dukkan_vitrini.dart';

class PazarYeri extends StatelessWidget {
  final String secilenSehir;
  const PazarYeri({super.key, required this.secilenSehir});

  final List<Map<String, dynamic>> kategoriler = const [
    {"ad": "Ev Yemekleri", "ikon": Icons.soup_kitchen},
    {"ad": "Ev Yapımı Çikolata & Tatlı", "ikon": Icons.cake},
    {"ad": "Ev Yapımı Süt Ürünleri", "ikon": Icons.water_drop},
    {"ad": "Ev Yapımı Turşu & Konserve", "ikon": Icons.inventory_2},
    {"ad": "Ev Yapımı Baharat & Sos", "ikon": Icons.grass},
    {"ad": "Mahalle Kasabı", "ikon": Icons.restaurant},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: Text("$secilenSehir ARENA PAZARI",
            style: const TextStyle(
                color: Color(0xFFFFB300), fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          _buildAramaCubugu(),

          // 🏮 KATEGORİ MODÜLÜ
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              itemCount: kategoriler.length,
              itemBuilder: (context, index) {
                return _kategoriItem(context, kategoriler[index]['ikon'],
                    kategoriler[index]['ad']);
              },
            ),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text("GASTRONOMİ DÜKKANLARI",
                  style: TextStyle(
                      color: Color(0xFFFFB300),
                      fontSize: 14,
                      fontWeight: FontWeight.bold)),
            ),
          ),

          // 🏪 MODERN VİTRİN LİSTESİ (SİHİRLİ GEÇİŞLER BURADA)
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 0),
              children: [
                _arenaVitrini(
                    context,
                    "KADIKÖY MANTI EVİ",
                    "Geleneksel El Mantısı ve Soslar",
                    "https://images.unsplash.com/photo-1534422298391-e4f8c170db76"),
                _arenaVitrini(
                    context,
                    "HASAN USTA TURŞULARI",
                    "40 Yıllık Sirke ve Emekle",
                    "https://images.unsplash.com/photo-1589135410995-c60303e30252"),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _kategoriItem(BuildContext context, IconData ikon, String ad) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => KategoriSayfasi(kategoriAdi: ad),
          ),
        );
      },
      child: Container(
        width: 110,
        padding: const EdgeInsets.symmetric(horizontal: 5),
        child: Column(
          children: [
            CircleAvatar(
              backgroundColor: const Color(0xFF1A1A1A),
              radius: 30,
              child: Icon(ikon, color: const Color(0xFFFFB300), size: 28),
            ),
            const SizedBox(height: 8),
            Text(
              ad,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAramaCubugu() {
    return Padding(
      padding: const EdgeInsets.all(15),
      child: TextField(
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: "Ürün veya dükkan ara...",
          hintStyle: const TextStyle(color: Colors.white24),
          prefixIcon: const Icon(Icons.search, color: Color(0xFFFFB300)),
          filled: true,
          fillColor: const Color(0xFF1A1A1A),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide.none),
        ),
      ),
    );
  }

  // ✨ FINAL TASARIM: NAVİGASYON VE "GEÇİŞ OKU" EKLENMİŞ VİTRİN
  Widget _arenaVitrini(
      BuildContext context, String baslik, String altBaslik, String gorselUrl) {
    return GestureDetector(
      // 🚀 MUTFAK VE ŞEFLERİN OLDUĞU SAYFAYA GEÇİŞ KAPISI
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DukkanVitrini(dukkanAdi: baslik),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        height: 180,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.4),
                blurRadius: 10,
                offset: const Offset(0, 5))
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              Positioned.fill(
                child: Image.network(
                  gorselUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (c, e, s) => Container(color: Colors.white10),
                ),
              ),
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.8)
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 20,
                left: 20,
                right: 20,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(baslik,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold)),
                        Text(altBaslik,
                            style: const TextStyle(
                                color: Color(0xFFFFB300),
                                fontSize: 13,
                                fontWeight: FontWeight.w500)),
                      ],
                    ),
                    // ➡️ İŞTE O ŞIK GEÇİŞ SİMGESİ (ARROW)
                    const Icon(Icons.arrow_forward_ios,
                        color: Color(0xFFFFB300), size: 18),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
