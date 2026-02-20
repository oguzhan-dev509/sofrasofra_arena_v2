import 'package:flutter/material.dart';
import 'vitrin_merkezi.dart';
import 'akademi_merkezi.dart';
import 'sepetim.dart';
import 'urun_detay.dart';

class KategoriSayfasi extends StatelessWidget {
  final String kategoriAdi;

  // 🛡️ Constructor - Hatasız Yapı
  const KategoriSayfasi({super.key, required this.kategoriAdi});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFFFFB300)),
        title: Text(
          kategoriAdi.toUpperCase(),
          style: const TextStyle(
              color: Color(0xFFFFB300), fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          // 🌉 ARENA KÖPRÜLERİ (ÇALIŞAN MODÜLLER)
          _modulKopruleri(context),

          const SizedBox(height: 10),
          _bolumBasligi("USTA ÜRETİCİLERİMİZ"),
          _ureticiYatayListe(),

          const SizedBox(height: 10),
          _bolumBasligi("EV YAPIMI LEZZETLER"),

          // 🏮 ÜRÜN GRİDİ
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(15),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.65,
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
              ),
              itemCount: 4,
              itemBuilder: (context, index) =>
                  _evYapimiUrunKarti(context, index),
            ),
          ),
        ],
      ),
    );
  }

  Widget _modulKopruleri(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 15),
      color: const Color(0xFF1A1A1A),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _kopruButonu(
              context, Icons.auto_awesome, "VİTRİNİM", const VitrinMerkezi()),
          _kopruButonu(
              context, Icons.school, "AKADEMİM", const AkademiMerkezi()),
          _kopruButonu(
              context, Icons.shopping_cart, "SEPETİM", const Sepetim()),
        ],
      ),
    );
  }

  Widget _kopruButonu(
      BuildContext context, IconData ikon, String etiket, Widget sayfa) {
    return InkWell(
      onTap: () => Navigator.push(
          context, MaterialPageRoute(builder: (context) => sayfa)),
      child: Column(
        children: [
          Icon(ikon, color: const Color(0xFFFFB300), size: 24),
          const SizedBox(height: 5),
          Text(etiket,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _bolumBasligi(String baslik) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(baslik,
            style: const TextStyle(
                color: Colors.white38,
                fontSize: 12,
                fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _ureticiYatayListe() {
    return SizedBox(
      height: 90,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 15),
        itemCount: 6,
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.only(right: 15),
          child: Column(
            children: [
              const CircleAvatar(
                radius: 28,
                backgroundColor: Color(0xFF1A1A1A),
                child: Icon(Icons.person, color: Color(0xFFFFB300), size: 30),
              ),
              const SizedBox(height: 5),
              Text("Üretici ${index + 1}",
                  style: const TextStyle(color: Colors.white54, fontSize: 9)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _evYapimiUrunKarti(BuildContext context, int index) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: const Center(
                  child:
                      Icon(Icons.restaurant, color: Colors.white10, size: 40)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Ev Yapımı Lezzet",
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                const Text("Geleneksel Tarif",
                    style: TextStyle(color: Colors.white54, fontSize: 10)),
                const SizedBox(height: 10),
                const Text("150 TL",
                    style: TextStyle(
                        color: Color(0xFFFFB300), fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
