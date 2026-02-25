import 'package:flutter/material.dart';
import 'ev_lezzetleri_vitrini.dart';
import 'sef_vitrini.dart';
import 'restoranlar_vitrini.dart';

class KategoriSayfasi extends StatelessWidget {
  const KategoriSayfasi({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFFFFB300)),
        title: const Text(
          "ARENA KATEGORİLERİ",
          style: TextStyle(
            color: Color(0xFFFFB300),
            letterSpacing: 2,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "NEREYE GİDİYORUZ KAPTAN?",
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w100,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 5),
            const Divider(color: Color(0xFFFFB300), thickness: 0.5),
            const SizedBox(height: 25),

            // 🚀 KATEGORİ BUTONLARI
            _kategoriButonu(
              context,
              "EV LEZZETLERİ",
              "Anne eli değmiş taze ürünler",
              Icons.restaurant_menu,
              const EvLezzetleriVitrini(),
            ),
            _kategoriButonu(
              context,
              "USTA ŞEFLER",
              "Profesyonel gastronomi deneyimi",
              Icons.star_border_purple500,
              const SefVitrini(),
            ),
            _kategoriButonu(
              context,
              "RESTORANLAR",
              "Arena'nın seçkin işletmeleri",
              Icons.storefront,
              const RestoranlarVitrini(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _kategoriButonu(BuildContext context, String baslik, String altBaslik,
      IconData ikon, Widget hedef) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => hedef),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF111111),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFB300).withAlpha(30),
                shape: BoxShape.circle,
              ),
              child: Icon(ikon, color: const Color(0xFFFFB300), size: 24),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    baslik,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    altBaslik,
                    style: const TextStyle(
                      color: Colors.white38,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios,
                color: Colors.white10, size: 14),
          ],
        ),
      ),
    );
  }
}
