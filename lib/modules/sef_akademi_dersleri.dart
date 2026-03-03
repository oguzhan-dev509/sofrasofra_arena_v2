import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SefAkademiDersleri extends StatelessWidget {
  const SefAkademiDersleri({super.key});

  @override
  Widget build(BuildContext context) {
    const Color gold = Color(0xFFFFB300);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: gold),
        title: const Text("AKADEMİ DERS PROGRAMI",
            style: TextStyle(
                color: gold, fontSize: 13, fontWeight: FontWeight.bold)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        // 📡 Dersler koleksiyonunu dinliyoruz
        stream: FirebaseFirestore.instance.collection('dersler').snapshots(),
        builder: (context, snapshot) {
          // ⏳ Yüklenme durumu kontrolü
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: gold));
          }

          // ❌ Veri yoksa veya hata varsa
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text("Henüz ders içeriği eklenmedi.",
                  style: TextStyle(color: Colors.white38)),
            );
          }

          // ✅ Veri varsa listele
          return ListView.builder(
            padding: const EdgeInsets.all(15),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final m =
                  snapshot.data!.docs[index].data() as Map<String, dynamic>;

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white10),
                ),
                child: ListTile(
                  leading:
                      const Icon(Icons.play_circle_fill, color: gold, size: 30),
                  title: Text(
                    (m['baslik'] ?? "İsimsiz Eğitim").toString().toUpperCase(),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    m['sure'] ?? "Süre Belirtilmedi",
                    style: const TextStyle(color: Colors.white38, fontSize: 11),
                  ),
                  trailing: const Icon(Icons.lock_outline,
                      color: Colors.white24, size: 16),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
