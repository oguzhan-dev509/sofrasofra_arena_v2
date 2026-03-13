import 'package:flutter/material.dart';

import 'sef_yonetim_paneli.dart';
import 'restoran_yonetim_paneli.dart';
import 'teslimat_ayarlar_sayfasi.dart';
import '../modules/vitrinler/ev_lezzetleri_vitrini.dart';
import '../courier/kurye_paneli.dart';

class MerchantDashboard extends StatelessWidget {
  const MerchantDashboard({super.key});

  static const Color gold = Color(0xFFFFB300);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: gold),
        title: const Text(
          "ARENA YÖNETİM MERKEZİ",
          style: TextStyle(
            color: gold,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildCard(
            context,
            "USTA ŞEF PANELİ",
            Icons.stars_rounded,
            const SefYonetimPaneli(),
          ),
          _buildCard(
            context,
            "RESTORAN PANELİ",
            Icons.restaurant_menu_rounded,
            const RestoranYonetimPaneli(),
          ),
          _buildCard(
            context,
            "EV LEZZETLERİ",
            Icons.home_work_rounded,
            const EvLezzetleriVitrini(),
          ),
          _buildCard(
            context,
            "TESLİMAT AYARLARI",
            Icons.local_shipping_rounded,
            const TeslimatAyarlariSayfasi(),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(
    BuildContext context,
    String title,
    IconData icon,
    Widget target,
  ) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => target),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF111111),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: gold.withAlpha(60)),
        ),
        child: Row(
          children: [
            Icon(icon, color: gold),
            const SizedBox(width: 20),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white24),
          ],
        ),
      ),
    );
  }
}
