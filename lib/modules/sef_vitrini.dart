import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'sef_itibar_sayfasi.dart'; // 🚀 İtibar sayfasına geçiş için şart

class SefVitrini extends StatelessWidget {
  const SefVitrini({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFFFFB300)),
        title: const Text(
          "GASTRONOMİ AKADEMİSİ",
          style: TextStyle(
            color: Color(0xFFFFB300),
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
      ),
      // 🛰️ Firestore'dan Şefleri Canlı Çekiyoruz
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('urunler')
            .where('tip', isEqualTo: 'Usta Sefler')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError)
            return Center(child: Text("Hata: ${snapshot.error}"));
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: Color(0xFFFFB300)));
          }

          final sefler = snapshot.data?.docs ?? [];

          if (sefler.isEmpty) {
            return const Center(
                child: Text("Arena'da henüz şef yok.",
                    style: TextStyle(color: Colors.white38)));
          }

          return ListView.builder(
            itemCount: sefler.length,
            itemBuilder: (context, index) {
              final data = sefler[index].data() as Map<String, dynamic>;
              return _sefKart(context, data);
            },
          );
        },
      ),
    );
  }

  Widget _sefKart(BuildContext context, Map<String, dynamic> data) {
    final String ad = data['dukkan'] ?? "Usta Şef";
    final String uzmanlik = data['kategori'] ?? "Gastronomi Uzmanı";
    final String profilResmi = data['img'] ??
        "https://images.unsplash.com/photo-1583394838336-acd977736f90";

    return Padding(
      padding: const EdgeInsets.all(25.0),
      child: Column(
        children: [
          GestureDetector(
            // 🚀 Şefin İtibar Sayfasına (Detaya) Git
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => SefItibarSayfasi(sefAdi: ad)),
              );
            },
            child: CircleAvatar(
              radius: 52,
              backgroundColor: const Color(0xFFFFB300),
              child: CircleAvatar(
                radius: 50,
                backgroundImage: NetworkImage(profilResmi),
              ),
            ),
          ),
          const SizedBox(height: 15),
          Text(
            ad,
            style: const TextStyle(
                fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          Text(
            uzmanlik,
            style: const TextStyle(color: Colors.white38, fontSize: 13),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Divider(color: Colors.white10),
          ),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              "ŞEFİN İMZA TABAKLARI",
              style: TextStyle(
                color: Color(0xFFFFB300),
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
          ),
          const SizedBox(height: 15),
          // İmza tabaklar şimdilik statik kalabilir veya Firestore'dan dizi olarak çekilebilir
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _ozelTabak("İmzalı Risotto",
                    "https://images.unsplash.com/photo-1473093226795-af9932fe5856"),
                _ozelTabak("Özel Sunum",
                    "https://images.unsplash.com/photo-1546069901-ba9599a7e63c"),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _ozelTabak(String isim, String url) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child:
                Image.network(url, height: 100, width: 160, fit: BoxFit.cover),
          ),
          const SizedBox(height: 8),
          Text(
            isim,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white70),
          ),
        ],
      ),
    );
  }
}
