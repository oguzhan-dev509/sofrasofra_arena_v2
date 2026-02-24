import 'package:flutter/material.dart';
// 🚀 Tüm yolları standart hale getirdik:
import 'signature_atelier_page.dart';
import 'chef_academy_page.dart';
import 'special_events_archive_page.dart';
import 'kitchen_consultancy_page.dart';
import 'chefs_table_page.dart';

class SefItibarSayfasi extends StatelessWidget {
  final String sefAdi;
  const SefItibarSayfasi({super.key, required this.sefAdi});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(sefAdi.toUpperCase(),
            style: const TextStyle(
                color: Color(0xFFFFB300),
                letterSpacing: 4,
                fontSize: 14,
                fontWeight: FontWeight.w900)),
        backgroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildSefHeroSection(),
            const SizedBox(height: 30),

            // 🍴 01. İMZA MUTFAĞI
            _buildEliteCategory(
                context,
                "01",
                "SEFIN IMZA MUTFAGI",
                "Sadece en seckin receteler.",
                Icons.auto_awesome_outlined, onTap: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const SignatureAtelierPage()));
            }),

            // 🎓 02. ŞEF AKADEMİSİ
            _buildEliteCategory(
                context,
                "02",
                "SEF AKADEMISI",
                "Gastronomi teknik egitimleri.",
                Icons.school_outlined, onTap: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const ChefAcademyPage()));
            }),

            // 📜 03. ÖZEL DAVET ARŞİVİ
            _buildEliteCategory(
                context,
                "03",
                "OZEL DAVET ARSIVI",
                "Seckin etkinlik portfolyosu.",
                Icons.history_edu_outlined, onTap: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const SpecialEventsArchivePage()));
            }),

            // 💼 04. MUTFAK DANIŞMANLIĞI
            _buildEliteCategory(
                context,
                "04",
                "MUTFAK DANISMANLIGI",
                "Profesyonel mentorluk.",
                Icons.business_center_outlined, onTap: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const KitchenConsultancyPage()));
            }),

            _buildEliteCategory(context, "05", "SEFIN MASASI",
                "Size ozel rezervasyon.", Icons.event_seat_outlined, onTap: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const ChefsTablePage()));
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildSefHeroSection() {
    return Container(
      height: 250,
      width: double.infinity,
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: NetworkImage(
              "https://images.unsplash.com/photo-1583394293214-28dea15ee548"),
          fit: BoxFit.cover,
          opacity: 0.6,
        ),
      ),
      child: const Center(
        child: Text("MASTERY & EXCELLENCE",
            style: TextStyle(
                color: Color(0xFFFFB300),
                letterSpacing: 5,
                fontSize: 10,
                fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildEliteCategory(BuildContext context, String index, String baslik,
      String altYazi, IconData ikon,
      {VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0A0A0A),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: ListTile(
          onTap: onTap,
          leading: Text(index,
              style: const TextStyle(
                  color: Color(0xFFFFB300),
                  fontSize: 18,
                  fontWeight: FontWeight.w100)),
          title: Text(baslik,
              style: const TextStyle(
                  color: Colors.white,
                  letterSpacing: 2,
                  fontSize: 12,
                  fontWeight: FontWeight.bold)),
          subtitle: Text(altYazi,
              style: const TextStyle(
                  color: Colors.white38,
                  fontSize: 10,
                  fontStyle: FontStyle.italic)),
          trailing: Icon(ikon, color: const Color(0xFFFFB300), size: 18),
        ),
      ),
    );
  }
}
