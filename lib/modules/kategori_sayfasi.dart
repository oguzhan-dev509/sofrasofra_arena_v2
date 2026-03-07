import 'package:flutter/material.dart';

import 'vitrinler/ev_lezzetleri_vitrini.dart';
import 'vitrinler/sef_vitrini.dart';
import 'vitrinler/restoranlar_vitrini.dart';

class KategoriSayfasi extends StatelessWidget {
  const KategoriSayfasi({super.key});

  static const Color gold = Color(0xFFFFB300);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: gold),
        title: const Text(
          "ARENA KATEGORİLERİ",
          style: TextStyle(
            color: gold,
            letterSpacing: 2,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
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
            const Divider(color: gold, thickness: 0.5),
            const SizedBox(height: 25),
            _kategoriButonu(
              context: context,
              baslik: "EV LEZZETLERİ",
              altBaslik: "Anne eli değmiş taze ürünler",
              ikon: Icons.restaurant_menu,
              hedef: const EvLezzetleriVitrini(),
            ),
            _kategoriButonu(
              context: context,
              baslik: "RESTORANLAR",
              altBaslik: "Arena'nın seçkin işletmeleri",
              ikon: Icons.storefront,
              hedef: const RestoranlarVitrini(),
            ),
            _kategoriButonu(
              context: context,
              baslik: "USTA ŞEFLER",
              altBaslik: "Profesyonel gastronomi deneyimi",
              ikon: Icons.star_border_purple500,
              hedef: const SefVitrini(),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _kategoriButonu({
    required BuildContext context,
    required String baslik,
    required String altBaslik,
    required IconData ikon,
    required Widget hedef,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => hedef),
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
                color: gold.withAlpha(30),
                shape: BoxShape.circle,
              ),
              child: Icon(ikon, color: gold, size: 24),
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
            const Icon(
              Icons.arrow_forward_ios,
              color: Colors.white10,
              size: 14,
            ),
          ],
        ),
      ),
    );
  }
}
