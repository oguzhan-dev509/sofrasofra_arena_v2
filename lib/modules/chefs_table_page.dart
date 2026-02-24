import 'package:flutter/material.dart';

class ChefsTablePage extends StatelessWidget {
  const ChefsTablePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text("ŞEFİN MASASI",
            style: TextStyle(
                color: Color(0xFFFFB300),
                letterSpacing: 3,
                fontSize: 13,
                fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Color(0xFFFFB300)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildExperienceHeader(),
            const SizedBox(height: 30),
            _buildExperienceCard(
              "7 AŞAMALI TADIM MENÜSÜ",
              "Şefin mevsimsel imza tabakları ve hikayeleri.",
              "3.500 ₺ / Kişi",
              "https://images.unsplash.com/photo-1559339352-11d035aa65de",
            ),
            _buildExperienceCard(
              "ŞEFLE MUTFAKTA BİR GECE",
              "Mutfak operasyonunu izleyerek yemek deneyimi.",
              "5.000 ₺ / Kişi",
              "https://images.unsplash.com/photo-1577106263724-2c8e03bfe9cf",
            ),
            const SizedBox(height: 30),
            _buildReservationAction(),
          ],
        ),
      ),
    );
  }

  Widget _buildExperienceHeader() {
    return const Column(
      children: [
        Text("SIRADIŞI BİR GASTRONOMİ YOLCULUĞU",
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w200,
                letterSpacing: 2)),
        SizedBox(height: 15),
        Divider(color: Color(0xFFFFB300), indent: 80, endIndent: 80),
      ],
    );
  }

  Widget _buildExperienceCard(
      String title, String desc, String price, String img) {
    return Container(
      margin: const EdgeInsets.only(bottom: 25),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0A),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          Image.network(img,
              height: 200, width: double.infinity, fit: BoxFit.cover),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                Text(title,
                    style: const TextStyle(
                        color: Color(0xFFFFB300),
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5)),
                const SizedBox(height: 10),
                Text(desc,
                    textAlign: TextAlign.center,
                    style:
                        const TextStyle(color: Colors.white38, fontSize: 11)),
                const SizedBox(height: 15),
                Text(price,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w900)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReservationAction() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(color: const Color(0xFFFFB300)),
      child: const Center(
        child: Text("REZERVASYON TALEBİ GÖNDER",
            style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                letterSpacing: 2)),
      ),
    );
  }
}
