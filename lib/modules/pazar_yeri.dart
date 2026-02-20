import 'package:flutter/material.dart';
import 'kategori_sayfasi.dart'; // ✨ Köprü için gerekli ilk anahtar
import 'dukkan_vitrini.dart';

class PazarYeri extends StatelessWidget {
  final String secilenSehir;
  const PazarYeri({super.key, required this.secilenSehir});

  // ✨ "EV YAPIMI" MÜHÜRLÜ ASİL LİSTE
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

          // 🏮 ÇALIŞAN KATEGORİ BUTONLARI
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

          // 🏪 DÜKKAN LİSTESİ
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              children: [
                _buildDukkanKarti(
                    context,
                    "KADIKÖY MANTI EVİ",
                    "Ev Yemekleri",
                    "Ev Hanımı Lezzeti",
                    "https://images.unsplash.com/photo-1534422298391-e4f8c170db76"),
                _buildDukkanKarti(
                    context,
                    "TURŞUCU HASAN USTA",
                    "Ev Yapımı Turşu & Konserve",
                    "Usta Şef Tarifi",
                    "https://images.unsplash.com/photo-1589135410995-c60303e30252"),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 🏥 İŞTE O SİHİRLİ "BEYİN" KODU BURAYA MONTE EDİLDİ:
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

  Widget _buildDukkanKarti(BuildContext context, String ad, String tur,
      String etiket, String gorsel) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => DukkanVitrini(dukkanAdi: ad)));
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Column(
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(20)),
                  child: Image.network(gorsel,
                      height: 160,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (c, e, s) => Container(
                          height: 160,
                          color: Colors.white10,
                          child: const Icon(Icons.store,
                              color: Color(0xFFFFB300)))),
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                        color: const Color(0xFFFFB300),
                        borderRadius: BorderRadius.circular(8)),
                    child: Text(etiket,
                        style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 10)),
                  ),
                ),
              ],
            ),
            ListTile(
              title: Text(ad,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
              subtitle: Text(tur,
                  style: const TextStyle(color: Colors.white54, fontSize: 12)),
              trailing:
                  const Icon(Icons.chevron_right, color: Color(0xFFFFB300)),
            ),
          ],
        ),
      ),
    );
  }
}
