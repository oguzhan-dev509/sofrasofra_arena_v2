import 'package:flutter/material.dart';
import 'vitrin_merkezi.dart';
import 'akademi_merkezi.dart';

class MenuYoneticisi extends StatelessWidget {
  const MenuYoneticisi({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFFFFB300)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "ARENA MERKEZİ",
          style: TextStyle(
            color: Color(0xFFFFB300),
            letterSpacing: 3,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 20,
          mainAxisSpacing: 20,
          children: [
            _buildMenuCard(context, "VİTRİNİM", "Şefin Masterpiece Serisi",
                Icons.stars, const Color(0xFFFFB300)),
            _buildMenuCard(context, "AKADEMİM", "Gastronomi Eğitimleri",
                Icons.school, Colors.blueAccent),
            _buildMenuCard(context, "SİPARİŞLER", "Aktif Lojistik Takibi",
                Icons.delivery_dining, Colors.greenAccent),
            _buildMenuCard(context, "KURUMSAL", "Arena Kimlik Kartı",
                Icons.business_center, Colors.redAccent),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard(BuildContext context, String baslik, String altBaslik,
      IconData ikon, Color renk) {
    return InkWell(
      onTap: () {
        if (baslik == "VİTRİNİM") {
          Navigator.push(context,
              MaterialPageRoute(builder: (context) => const VitrinMerkezi()));
        } else if (baslik == "AKADEMİM") {
          Navigator.push(context,
              MaterialPageRoute(builder: (context) => const AkademiMerkezi()));
        }
      },
      borderRadius: BorderRadius.circular(25),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: renk.withOpacity(0.3), width: 1.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(ikon, color: renk, size: 45),
            const SizedBox(height: 12),
            Text(baslik,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14)),
            const SizedBox(height: 4),
            Text(altBaslik,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.white.withOpacity(0.5), fontSize: 9)),
          ],
        ),
      ),
    );
  }
}
