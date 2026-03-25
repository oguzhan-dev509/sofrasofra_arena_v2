import 'package:flutter/material.dart';

// ignore_for_file: deprecated_member_use

class SpecialEventsArchivePage extends StatelessWidget {
  const SpecialEventsArchivePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFFFFB300)),
        title: const Text(
          "ÖZEL DAVET ARŞİVİ",
          style: TextStyle(
            color: Color(0xFFFFB300),
            letterSpacing: 2,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Color(0xFFFFB300), size: 20),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined,
                color: Color(0xFFFFB300), size: 20),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderInfo(),
            const SizedBox(height: 25),
            _buildSectionTitle(
                "GEÇMİŞ DAVETLER", Icons.edit_note), // Başlık düzeltildi
            _buildCompactEventCard(
              "DİPLOMATİK GALA YEMEĞİ",
              "Çırağan Sarayı - 2025",
              "Akdeniz Esintili Modern Füzyon",
              "https://images.unsplash.com/photo-1519167758481-83f550bb49b3",
            ),
            _buildCompactEventCard(
              "ART & GASTRONOMY CONCEPT",
              "Bodrum Marina - 2024",
              "Moleküler Sunum Deneyimi",
              "https://images.unsplash.com/photo-1551218372-a246b2779244",
            ),
            const SizedBox(height: 30),
            _buildSectionTitle(
                "VİDEO KAYITLARI (FULL HD)", Icons.play_circle_fill),
            _buildVideoNetworkCard(
              "ROYAL NETWORK - HIGHLIGHTS",
              "2:45 min",
              "https://images.unsplash.com/photo-1469334031218-e382a71b716b",
            ),
            _buildVideoNetworkCard(
              "ROYAL WEDDING - SUMMARY",
              "5:10 min",
              "https://images.unsplash.com/photo-1511795409834-ef04bbd61622",
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderInfo() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "UNUTULMAZ ANLARIN MİMARİSİ",
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w100,
            letterSpacing: 2,
          ),
        ),
        SizedBox(height: 5),
        Divider(color: Color(0xFFFFB300), thickness: 0.5),
        Text(
          "Her davet bir hikaye, her menü bir hatıradır.",
          style: TextStyle(
            color: Colors.white38,
            fontSize: 11,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 15),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFFFB300), size: 18),
          const SizedBox(width: 10),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactEventCard(
      String title, String loc, String desc, String img) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFFFFB300),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  loc,
                  style: const TextStyle(color: Colors.white70, fontSize: 10),
                ),
                const SizedBox(height: 8),
                Text(
                  desc,
                  style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 9,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Image.network(
              img,
              width: 80,
              height: 60,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                width: 80,
                height: 60,
                color: Colors.white10,
                child: const Icon(Icons.image_not_supported,
                    color: Colors.white24, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoNetworkCard(String title, String time, String img) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFFFB300)),
                ),
                child: Text(
                  time,
                  style: const TextStyle(color: Color(0xFFFFB300), fontSize: 9),
                ),
              )
            ],
          ),
          const SizedBox(height: 10),
          Stack(
            alignment: Alignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  img,
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 150,
                    width: double.infinity,
                    color: Colors.white10,
                    child:
                        const Icon(Icons.videocam_off, color: Colors.white24),
                  ),
                ),
              ),
              const Icon(Icons.play_circle_fill,
                  color: Color(0xFFFFB300), size: 50),
            ],
          ),
        ],
      ),
    );
  }
}
