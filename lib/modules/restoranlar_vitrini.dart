import 'package:flutter/material.dart';
import '../main.dart'; // Merkezi havuz için

class RestoranlarVitrini extends StatelessWidget {
  const RestoranlarVitrini({super.key});

  @override
  Widget build(BuildContext context) {
    // 🚀 ÖNEMLİ: Satıcı panelindeki "Restoranlar" etiketiyle tam eşleşme sağlıyoruz
    var yeniRestoranUrunleri =
        arenaUrunHavuzu.where((u) => u['tip'] == "Restoranlar").toList();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Color(0xFFFFB300)),
        title: const Text("ARENA RESTORANLARI",
            style: TextStyle(
                color: Color(0xFFFFB300), fontSize: 12, letterSpacing: 2)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(15),
        children: [
          // 🌟 1. KATMAN: Satıcıdan Gelen Canlı Veriler
          if (yeniRestoranUrunleri.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20, horizontal: 5),
              child: Text("ÇARŞIDA YENİ EKLENENLER",
                  style: TextStyle(
                      color: Color(0xFFFFB300),
                      fontWeight: FontWeight.bold,
                      fontSize: 12)),
            ),
            ...yeniRestoranUrunleri
                .map((urun) => _restoranUrunKarti(urun))
                .toList(),
            const SizedBox(height: 20),
            const Divider(color: Colors.white10, thickness: 1),
            const SizedBox(height: 20),
          ],

          // 🏠 2. KATMAN: Sabit Restoranlar (Artık Tıklanabilir!)
          _buildRestoranCard(
              context,
              "Boğazın İncisi",
              "Deniz Ürünleri & Modern Mutfak",
              "4.9",
              "https://images.unsplash.com/photo-1517248135467-4c7ed9d42c77"),
          _buildRestoranCard(
              context,
              "Anadolu Ateşi",
              "Geleneksel Kebap Kültürü",
              "4.7",
              "https://images.unsplash.com/photo-1555396273-367ea4eb4db5"),
        ],
      ),
    );
  }

  // Restoran Kartı Çizici
  Widget _buildRestoranCard(
      BuildContext context, String ad, String desc, String puan, String img) {
    return InkWell(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("$ad Menüsü Hazırlanıyor..."),
            backgroundColor: const Color(0xFF1A1A1A)));
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
            color: const Color(0xFF0A0A0A),
            border: Border.all(color: Colors.white10),
            borderRadius: BorderRadius.circular(10)),
        child: Column(children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
            child: Image.network(
              img,
              height: 180,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                height: 180,
                color: Colors.white10,
                child: const Icon(Icons.restaurant_menu,
                    color: Color(0xFFFFB300), size: 50),
              ),
            ),
          ),
          ListTile(
            title: Text(ad,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
            subtitle: Text(desc,
                style: const TextStyle(color: Colors.white38, fontSize: 11)),
            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.star, color: Color(0xFFFFB300), size: 16),
              const SizedBox(width: 4),
              Text(puan, style: const TextStyle(color: Colors.white))
            ]),
          )
        ]),
      ),
    );
  }

  // Satıcıdan Gelen Ürün Kartı
  Widget _restoranUrunKarti(Map<String, dynamic> urun) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
          color: const Color(0xFF0A0A0A),
          border: Border.all(color: const Color(0xFFFFB300), width: 0.5),
          borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(10),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            urun['img'] ?? '',
            width: 60,
            height: 60,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
                width: 60,
                height: 60,
                color: Colors.white10,
                child: const Icon(Icons.restaurant, color: Color(0xFFFFB300))),
          ),
        ),
        title: Text(urun['ad'] ?? 'Yeni Ürün',
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14)),
        subtitle: Text(urun['dukkan'] ?? 'Restoran',
            style: const TextStyle(color: Colors.white38, fontSize: 11)),
        trailing: Text("${urun['fiyat']} ₺",
            style: const TextStyle(
                color: Color(0xFFFFB300), fontWeight: FontWeight.bold)),
      ),
    );
  }
}
