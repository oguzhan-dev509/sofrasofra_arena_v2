import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AkademiMerkezi extends StatelessWidget {
  const AkademiMerkezi({super.key});

  // 📺 Eğitim Videosunu YouTube'da Açma Fonksiyonu (Mühürlendi)
  Future<void> _egitimBaslat(String link) async {
    final Uri url = Uri.parse(link);
    try {
      // Modern launchUrl kullanımı
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint("Bağlantı Hatası: $e");
    }
  }

  // ✨ Link ekleme kutucuğu (Dialog)
  void _linkEkle(BuildContext context, String egitimAdi) {
    final TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: Text("$egitimAdi Linki Ekle",
            style: const TextStyle(color: Color(0xFFFFB300))),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
              hintText: "YouTube Linkini Buraya Yapıştır",
              hintStyle: TextStyle(color: Colors.white24)),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("İptal", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFB300)),
              onPressed: () {
                debugPrint("$egitimAdi için yeni link: ${controller.text}");
                Navigator.pop(context);
              },
              child:
                  const Text("Kaydet", style: TextStyle(color: Colors.black))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFFFFB300)),
        title: const Text("ARENA AKADEMİ",
            style: TextStyle(
                color: Color(0xFFFFB300),
                fontWeight: FontWeight.bold,
                letterSpacing: 2)),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildAkademiHeader(),
            const SizedBox(height: 20),
            _buildEgitimKarti(
                context,
                "MANTI VE HAMUR SANATI",
                "Şef Arda Türkmen • 45 Dakika",
                Icons.restaurant_menu,
                "92% Tamamlandı",
                "https://www.youtube.com/watch?v=dQw4w9WgXcQ"),
            _buildEgitimKarti(
                context,
                "TABAKLAMA VE ESTETİK",
                "Görsel Sunum Teknikleri",
                Icons.auto_awesome,
                "Yeni Modül",
                "https://www.youtube.com"),
            _buildEgitimKarti(
                context,
                "MUTFAKTA AI YÖNETİMİ",
                "Geleceğin Restoran Teknolojileri",
                Icons.psychology,
                "Trend",
                "https://www.youtube.com"),
            _buildSertifikaBolumu(context),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  Widget _buildAkademiHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        border: Border(
            bottom: BorderSide(
                color: const Color(0xFFFFB300).withValues(alpha: 0.4))),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("HOŞ GELDİN, ŞEF",
              style: TextStyle(color: Colors.white, fontSize: 14)),
          SizedBox(height: 5),
          Text("Bilgi, En Keskin Bıçağındır.",
              style: TextStyle(
                  color: Color(0xFFFFB300),
                  fontSize: 22,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildEgitimKarti(BuildContext context, String baslik, String alt,
      IconData ikon, String durum, String videoLink) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(15),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
              color: Colors.black, borderRadius: BorderRadius.circular(10)),
          child: Icon(ikon, color: const Color(0xFFFFB300), size: 30),
        ),
        title: Text(baslik,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
        subtitle:
            Text(alt, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.white24, size: 20),
              onPressed: () => _linkEkle(context, baslik),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.play_circle_fill, color: Color(0xFFFFB300)),
                const SizedBox(height: 4),
                Text(durum,
                    style: const TextStyle(
                        color: Colors.green,
                        fontSize: 8,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
        onTap: () => _egitimBaslat(videoLink),
      ),
    );
  }

  Widget _buildSertifikaBolumu(BuildContext context) {
    return InkWell(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color(0xFFFFB300),
            content: Text("Sertifikalarınız Hazırlanıyor... Yakında Buradayız!",
                style: TextStyle(
                    color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.all(15),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
              colors: [const Color(0xFFFFB300).withOpacity(0.1), Colors.black]),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: const Color(0xFFFFB300).withOpacity(0.5)),
        ),
        child: const Row(
          children: [
            Icon(Icons.workspace_premium, color: Color(0xFFFFB300), size: 40),
            SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("SERTİFİKALARIM",
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                  Text("Şu an aktif 2 sertifikanız var.",
                      style: TextStyle(color: Colors.grey, fontSize: 11)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 16),
          ],
        ),
      ),
    );
  }
}
