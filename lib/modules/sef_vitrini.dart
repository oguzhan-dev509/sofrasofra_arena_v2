import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sofrasofra_arena_v2/modules/sef_itibar_sayfasi.dart';

class SefVitrini extends StatelessWidget {
  const SefVitrini({super.key});

  static const gold = Color(0xFFFFB300);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: gold),
        title: const Text(
          "GASTRONOMİ AKADEMİSİ",
          style: TextStyle(
            color: gold,
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('urunler')
            .where('tip', isEqualTo: 'Usta Sefler')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
                child: Text("Hata: ${snapshot.error}",
                    style: const TextStyle(color: Colors.white70)));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: gold));
          }

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(
              child: Text("Arena'da henüz şef yok.",
                  style: TextStyle(color: Colors.white38)),
            );
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              return _sefKart(context, data, docs[index].id);
            },
          );
        },
      ),
    );
  }

  Widget _sefKart(
      BuildContext context, Map<String, dynamic> data, String docId) {
    // 🏷️ Veri Hazırlama
    final String ad =
        (data['dukkan'] ?? data['dukkanAdi'] ?? "Usta Şef").toString();
    final String uzmanlik =
        (data['uzmanlik'] ?? data['kategori'] ?? "Gastronomi Uzmanı")
            .toString();
    final String profilResmi =
        (data['img'] ?? "https://picsum.photos/200").toString();

    // 🔑 AKILLI ANAHTAR
    final String dukkanId = (data['dukkanId'] ?? docId).toString();

    return Padding(
      padding: const EdgeInsets.all(25.0),
      child: Column(
        children: [
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SefItibarSayfasi(dukkanId: dukkanId),
                ),
              );
            },
            child: CircleAvatar(
              radius: 52,
              backgroundColor: gold,
              child: CircleAvatar(
                radius: 50,
                // OnBackgroundImageError eklendi
                backgroundImage: NetworkImage(_cacheBust(profilResmi, docId)),
                onBackgroundImageError: (exception, stackTrace) {
                  debugPrint("Resim yüklenemedi: $exception");
                },
              ),
            ),
          ),
          const SizedBox(height: 15),
          Text(ad,
              style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
          Text(uzmanlik,
              style: const TextStyle(color: Colors.white38, fontSize: 13)),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Divider(color: Colors.white10),
          ),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              "ŞEFİN İMZA TABAKLARI",
              style: TextStyle(
                  color: gold,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2),
            ),
          ),
          const SizedBox(height: 15),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              // Const kaldırıldı çünkü liste dinamikleşmeye hazır olmalı
              children: const [
                _OzelTabak(
                  isim: "İmzalı Risotto",
                  url:
                      "https://images.unsplash.com/photo-1473093226795-af9932fe5856?auto=format&fit=crop&w=400&q=60",
                ),
                _OzelTabak(
                  isim: "Özel Sunum",
                  url:
                      "https://images.unsplash.com/photo-1546069901-ba9599a7e63c?auto=format&fit=crop&w=400&q=60",
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _cacheBust(String url, String v) {
    if (url.isEmpty || !url.startsWith("http")) return url;
    return url.contains('?') ? "$url&v=$v" : "$url?v=$v";
  }
}

class _OzelTabak extends StatelessWidget {
  final String isim;
  final String url;
  const _OzelTabak({required this.isim, required this.url});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: Image.network(
              url,
              height: 100,
              width: 160,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 100,
                  width: 160,
                  color: Colors.white10,
                  child: const Icon(Icons.broken_image, color: Colors.white24),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Text(isim,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white70)),
        ],
      ),
    );
  }
}
