import 'package:flutter/material.dart';

class KitchenConsultancyPage extends StatelessWidget {
  const KitchenConsultancyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text("MUTFAK DANIŞMANLIĞI",
            style: TextStyle(
                color: Color(0xFFFFB300),
                letterSpacing: 2,
                fontSize: 13,
                fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Color(0xFFFFB300)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildIntro(),
            const SizedBox(height: 30),

            // 🛠️ ETKİLEŞİMLİ PANELLER (ExpansionTile)
            _buildInteractiveService(
              "MENÜ & REÇETE TASARIMI",
              "İmza tabaklardan maliyet hesaplamalarına kadar tam destek.",
              Icons.menu_book,
              "Detaylar: Reçete standardizasyonu, tabak maliyeti analizi ve mevsimsel menü güncellemeleri dahil.",
            ),
            _buildInteractiveService(
              "ENDÜSTRİYEL MUTFAK KURULUMU",
              "Mutfak iş akışı ve ekipman optimizasyonu.",
              Icons.precision_manufacturing,
              "Detaylar: Mutfak mimari yerleşimi, HACCP standartlarına uygunluk ve enerji verimliliği odaklı ekipman seçimi.",
            ),
            _buildInteractiveService(
              "PERSONEL & EKİP EĞİTİMİ",
              "Mutfak disiplini ve servis standartlarının oluşturulması.",
              Icons.groups,
              "Detaylar: Mutfak hiyerarşisi, teknik beceri geliştirme ve lüks servis protokolleri eğitimi.",
            ),

            const SizedBox(height: 40),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildIntro() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("STRATEJİK GASTRONOMİ",
            style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w100,
                letterSpacing: 2)),
        SizedBox(height: 8),
        Text("Fikirleri kazançlı işletmelere dönüştüren profesyonel mentorluk.",
            style: TextStyle(
                color: Colors.white38,
                fontSize: 11,
                fontStyle: FontStyle.italic)),
      ],
    );
  }

  Widget _buildInteractiveService(
      String title, String subtitle, IconData icon, String detail) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0A),
        border: Border.all(color: Colors.white10),
      ),
      child: Theme(
        data: ThemeData.dark().copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: Icon(icon, color: const Color(0xFFFFB300), size: 24),
          title: Text(title,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold)),
          subtitle: Text(subtitle,
              style: const TextStyle(color: Colors.white38, fontSize: 10)),
          trailing: const Icon(Icons.add, color: Color(0xFFFFB300), size: 18),
          children: [
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Text(detail,
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 11, height: 1.5)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          height: 50,
          decoration:
              BoxDecoration(border: Border.all(color: const Color(0xFFFFB300))),
          child: const Center(
            child: Text("PROFESYONEL TEKLİF ALIN",
                style: TextStyle(
                    color: Color(0xFFFFB300),
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                    letterSpacing: 1.5)),
          ),
        ),
        const SizedBox(height: 15),
        const Center(
          child: Text("WhatsApp ile Hızlı İletişim",
              style: TextStyle(
                  color: Colors.white24,
                  fontSize: 10,
                  decoration: TextDecoration.underline)),
        )
      ],
    );
  }
}
