import 'package:flutter/material.dart';
import 'sef_yonetim_paneli.dart'; // 👈 Bu dosyanın ismiyle tam uyuşmalı!
import 'restoran_yonetim_paneli.dart';
import 'vitrin_merkezi.dart';

class MerchantDashboard extends StatelessWidget {
  const MerchantDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("ARENA YÖNETİM MERKEZİ",
            style: TextStyle(
                color: Color(0xFFFFB300),
                fontSize: 12,
                fontWeight: FontWeight.bold)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            _buildCard(context, "USTA ŞEF PANELİ", Icons.stars_rounded,
                const SefYonetimPaneli()),
            _buildCard(context, "RESTORAN PANELİ",
                Icons.restaurant_menu_rounded, const RestoranYonetimPaneli()),
            _buildCard(context, "EV LEZZETLERİ", Icons.home_work_rounded,
                const VitrinMerkeziSayfasi()),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(
      BuildContext context, String title, IconData icon, Widget target) {
    return GestureDetector(
      onTap: () => Navigator.push(
          context, MaterialPageRoute(builder: (context) => target)),
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            color: const Color(0xFF111111),
            borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFFFFB300)),
            const SizedBox(width: 20),
            Text(title,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
