import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SefProfili extends StatelessWidget {
  final String dukkanAdi;
  const SefProfili({super.key, required this.dukkanAdi});

  @override
  Widget build(BuildContext context) {
    const gold = Color(0xFFFFB300);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: gold),
        title: Text(dukkanAdi.toUpperCase(),
            style: const TextStyle(color: gold, fontSize: 13)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('urunler').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: gold));
          }

          // 🛡️ Hata ayıklama: snapshot.data null kontrolü eklendi
          final docs = snapshot.data?.docs ?? [];

          final filteredDocs = docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final dbName = (data['dukkanAdi'] ?? data['dukkan'] ?? "")
                .toString()
                .toLowerCase()
                .trim();
            return dbName == dukkanAdi.toLowerCase().trim();
          }).toList();

          if (filteredDocs.isEmpty) {
            return const Center(
                child: Text("Veri bulunamadı.",
                    style: TextStyle(color: Colors.white38)));
          }

          final mainData = filteredDocs.first.data() as Map<String, dynamic>;

          return ListView(
            padding: const EdgeInsets.all(25),
            children: [
              _buildHeader(mainData, gold),
              const SizedBox(height: 30),
              _infoBox("👨‍🍳 UZMANLIK", mainData['uzmanlik'], gold),
              _infoBox("🎓 AKADEMİ", mainData['akadem_mufredat'], gold),
              const SizedBox(height: 30),
              const Text("ŞEFİN VİTRİNİ",
                  style: TextStyle(
                      color: gold, fontSize: 10, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              _buildGrid(filteredDocs, gold),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(Map<String, dynamic> data, Color gold) {
    String img = (data['img'] ?? data['profil_resmi'] ?? "").toString();
    return Column(children: [
      CircleAvatar(
          radius: 50,
          backgroundColor: Colors.white10, // 🛡️ Arkaplan rengi eklendi
          backgroundImage: img.isNotEmpty ? NetworkImage(img) : null,
          child:
              img.isEmpty ? Icon(Icons.person, color: gold, size: 40) : null),
      const SizedBox(height: 15),
      Text(dukkanAdi.toUpperCase(),
          style: const TextStyle(
              color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
    ]);
  }

  Widget _infoBox(String t, dynamic v, Color g) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(10)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(t,
            style:
                TextStyle(color: g, fontSize: 9, fontWeight: FontWeight.bold)),
        const SizedBox(height: 5),
        Text(v?.toString() ?? "Girilmemiş",
            style: const TextStyle(color: Colors.white70, fontSize: 13)),
      ]),
    );
  }

  Widget _buildGrid(List<DocumentSnapshot> docs, Color gold) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: docs.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3, crossAxisSpacing: 8, mainAxisSpacing: 8),
      itemBuilder: (context, i) {
        final data = docs[i].data() as Map<String, dynamic>;
        String url = (data['img'] ?? "").toString();
        return Container(
          decoration: BoxDecoration(
              color: Colors.white10, borderRadius: BorderRadius.circular(8)),
          child: url.isNotEmpty
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(url, fit: BoxFit.cover))
              : const Icon(Icons.restaurant, color: Colors.white10),
        );
      },
    );
  }
}
