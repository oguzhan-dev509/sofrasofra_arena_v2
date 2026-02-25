import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart'; // Eğitim videoları için

class AkademiMerkeziSayfasi extends StatelessWidget {
  const AkademiMerkeziSayfasi({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Color(0xFFFFB300)),
        title: const Text("ARENA SATICI AKADEMİSİ",
            style: TextStyle(
                color: Color(0xFFFFB300),
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _akademiKarti(
            context,
            "18 KARE VİTRİN NASIL YÖNETİLİR?",
            "Müşteriyi büyüleyen fotoğraf çekim teknikleri.",
            Icons.camera_enhance,
            "https://youtube.com", // 🚀 Buraya eğitim linkini koyabilirsin
          ),
          _akademiKarti(
            context,
            "YOUTUBE MOTORU ENTEGRASYONU",
            "Dükkanına canlılık katacak video rehberi.",
            Icons.ondemand_video,
            "https://youtube.com",
          ),
          _akademiKarti(
            context,
            "ŞEFİN NOTLARININ GÜCÜ",
            "Müşteri sadakatini artırma stratejileri.",
            Icons.menu_book,
            "https://youtube.com",
          ),
        ],
      ),
    );
  }

  Widget _akademiKarti(BuildContext context, String baslik, String alt,
      IconData ikon, String link) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0A),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white10),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(15),
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFFFB300).withAlpha(30),
          child: Icon(ikon, color: const Color(0xFFFFB300)),
        ),
        title: Text(baslik,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13)),
        subtitle: Text(alt,
            style: const TextStyle(color: Colors.white38, fontSize: 10)),
        trailing:
            const Icon(Icons.play_circle_outline, color: Color(0xFFFFB300)),
        onTap: () async {
          final Uri url = Uri.parse(link);
          if (!await launchUrl(url)) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Eğitim Videosu Açılamadı!")));
            }
          }
        },
      ),
    );
  }
}
