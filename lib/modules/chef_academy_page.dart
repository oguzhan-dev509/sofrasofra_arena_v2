import 'package:flutter/material.dart';

class ChefAcademyPage extends StatelessWidget {
  const ChefAcademyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text("GASTRONOMİ AKADEMİSİ",
            style: TextStyle(
                color: Color(0xFFFFB300),
                letterSpacing: 2,
                fontSize: 13,
                fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Color(0xFFFFB300)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAcademyHeader(),
            const SizedBox(height: 40),
            _buildSectionTitle("AŞÇILIK EĞİTİMİ", Icons.restaurant),
            _buildEducationList([
              "Genel Türk Mutfağı",
              "Yöresel Mutfaklar",
              "Osmanlı Saray Mutfağı",
              "Dünya Mutfaklarından Örnekler",
              "Pişirme Teknikleri",
              "Hijyen & Sağlık",
              "Tabak Dizayn & Sunum",
              "Müşteri Servisi",
            ]),
            const SizedBox(height: 40),
            _buildSectionTitle("PASTACILIK EĞİTİMİ", Icons.cake),
            _buildEducationList([
              "Pasta Yapım Teknikleri",
              "Çikolata Yapımı",
              "Kek & Kurabiyeler",
              "Sütlü Tatlılar",
              "Börek Çeşitleri",
              "İleri Seviye Dekorasyon",
            ]),
            const SizedBox(height: 40),
            _buildSectionTitle("KAFE İŞLETME MENTORLUĞU", Icons.coffee),
            _buildEducationList([
              "İşletme Maliyeti Hesaplama",
              "Endüstriyel Ekipmanlar",
              "Menü & Reçete Tasarımı",
              "Satış & İş Akışı Takibi",
              "Personel Yönetimi",
            ]),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  Widget _buildAcademyHeader() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("BİLGİ, EN DEĞERLİ BAHARATTIR.",
            style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w100,
                fontStyle: FontStyle.italic)),
        SizedBox(height: 12),
        Text("Hızlandırılmış eğitim modülleriyle profesyonelliğe adım atın.",
            style: TextStyle(color: Colors.white38, fontSize: 12)),
      ],
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFFFFB300), size: 20),
        const SizedBox(width: 12),
        Text(title,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5)),
      ],
    );
  }

  Widget _buildEducationList(List<String> items) {
    return Container(
      margin: const EdgeInsets.only(top: 15),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0A),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        children: items
            .map((item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_outline,
                          color: Color(0xFFFFB300), size: 14),
                      const SizedBox(width: 12),
                      Expanded(
                          child: Text(item,
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 12))),
                      const Icon(Icons.arrow_forward_ios,
                          color: Colors.white12, size: 10),
                    ],
                  ),
                ))
            .toList(),
      ),
    );
  }
}
