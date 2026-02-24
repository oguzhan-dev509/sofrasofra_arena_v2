import 'package:flutter/material.dart';
import 'urun_ekleme_sayfasi.dart';
import 'vitrin_merkezi.dart'; // 🔥 Yeni eklediğimiz efsane dosya

class MerchantDashboard extends StatelessWidget {
  const MerchantDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(
            color: Color(0xFFFFB300)), // Geri dönüş ikonu sarı
        title: const Text("SATICI YÖNETİM PANELİ",
            style: TextStyle(
                color: Color(0xFFFFB300),
                letterSpacing: 2,
                fontSize: 12,
                fontWeight: FontWeight.bold)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("HIZLI İŞLEMLER",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),

            // 🚀 1. İŞLEM: YENİ ÜRÜN EKLE
            _buildActionCard(
              context,
              "YENİ ÜRÜN EKLE",
              "Arena vitrinine yeni bir lezzet katın.",
              Icons.add_box_outlined,
              () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const UrunEklemeSayfasi())),
            ),

            // 🏛️ 2. İŞLEM: PREMİUM VİTRİN YÖNETİMİ (443 Satırlık Güç!)
            _buildActionCard(
              context,
              "VİTRİN VE PORTFOLYO YÖNETİMİ",
              "18 Kare Galeri, YouTube Linki ve Şef Notları.",
              Icons.auto_awesome_motion_outlined,
              () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const VitrinMerkeziSayfasi())),
            ),

            const SizedBox(height: 10),
            const Divider(color: Colors.white10),
            const SizedBox(height: 10),

            const Text("DÜKKAN İSTATİSTİKLERİ",
                style: TextStyle(
                    color: Colors.white38,
                    fontSize: 11,
                    fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(BuildContext context, String title, String sub,
      IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            color: const Color(0xFF111111),
            borderRadius: BorderRadius.circular(5),
            border: Border.all(
                color: Colors.white
                    .withOpacity(0.05))), // Hafif bir çerçeve şıklık katar
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFFFFB300), size: 28),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold)),
                  Text(sub,
                      style:
                          const TextStyle(color: Colors.white38, fontSize: 10)),
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
