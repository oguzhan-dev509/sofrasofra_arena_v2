import 'package:flutter/material.dart';
import 'dukkan_vitrini.dart';

class PazarYeri extends StatefulWidget {
  final String secilenSehir;
  const PazarYeri({super.key, required this.secilenSehir});

  @override
  State<PazarYeri> createState() => _PazarYeriState();
}

class _PazarYeriState extends State<PazarYeri> {
  // 🏪 DÜKKAN LİSTESİ (Hafif ve Net)
  final List<Map<String, String>> dukkanListesi = [
    {
      "ad": "KADIKÖY MANTI EVİ",
      "alt": "Geleneksel El Mantısı ve Soslar",
      "img": "https://images.unsplash.com/photo-1534422298391-e4f8c170db76",
    },
    {
      "ad": "HASAN USTA TURŞULARI",
      "alt": "40 Yıllık Sirke ve Emekle",
      "img": "https://images.unsplash.com/photo-1589135410995-c60303e30252",
    },
    {
      "ad": "SÜTÇÜ ANA",
      "alt": "Doğal Yayık Tereyağı ve Peynir",
      "img": "https://images.unsplash.com/photo-1528498033053-35608b21ca07",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
        title: Text("TÜRKİYE ARENA PAZARI", // İsim güncellendi
            style: const TextStyle(
                color: Color(0xFFFFB300), fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          _buildAramaCubugu(),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text("GASTRONOMİ DÜKKANLARI",
                  style: TextStyle(
                      color: Color(0xFFFFB300),
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2)),
            ),
          ),

          // 🏪 VİTRİN LİSTESİ
          Expanded(
            child: ListView.builder(
              itemCount: dukkanListesi.length,
              padding: const EdgeInsets.only(bottom: 20),
              itemBuilder: (context, index) {
                final dukkan = dukkanListesi[index];
                return _arenaVitrini(
                    context, dukkan['ad']!, dukkan['alt']!, dukkan['img']!);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAramaCubugu() {
    return Padding(
      padding: const EdgeInsets.all(15),
      child: TextField(
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: "Dükkan veya ürün ara...",
          hintStyle: const TextStyle(color: Colors.white24),
          prefixIcon: const Icon(Icons.search, color: Color(0xFFFFB300)),
          filled: true,
          fillColor: const Color(0xFF1A1A1A),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide.none),
        ),
      ),
    );
  }

  Widget _arenaVitrini(
      BuildContext context, String baslik, String altBaslik, String gorselUrl) {
    return GestureDetector(
      onTap: () {
        // Hata veren dukkan_detay yerine direkt dukkan_vitrini'ne yönlendirdik
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DukkanVitrini(dukkanAdi: baslik),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        height: 180,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 15,
                offset: const Offset(0, 8))
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(25),
          child: Stack(
            children: [
              Positioned.fill(
                child: Image.network(
                  gorselUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (c, e, s) => Container(color: Colors.white10),
                ),
              ),
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.9)
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 20,
                left: 20,
                right: 20,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(baslik,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold)),
                          Text(altBaslik,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: Color(0xFFFFB300),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400)),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios,
                        color: Color(0xFFFFB300), size: 16),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
