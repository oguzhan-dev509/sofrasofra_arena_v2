import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SefItibarSayfasi extends StatelessWidget {
  final String dukkanId;
  const SefItibarSayfasi({super.key, required this.dukkanId});

  static const gold = Color(0xFFFFB300);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: gold),
        title: const Text("ŞEF İTİBAR PROFİLİ",
            style: TextStyle(color: gold, fontSize: 13)),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('urunler')
            .doc(dukkanId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return const Center(child: CircularProgressIndicator(color: gold));

          final data = snapshot.data?.data() as Map<String, dynamic>? ?? {};
          final String ad =
              (data['dukkan'] ?? data['dukkanAdi'] ?? "Usta Şef").toString();
          final String uzman =
              (data['uzmanlik'] ?? "Gastronomi Uzmanı").toString();
          final String resim =
              (data['img'] ?? "https://picsum.photos/200").toString();

          // 🎓 Müfredat Listesi
          final List<String> mufredat = [
            "Osmanlı",
            "Tabak Tasarım",
            "Dünya Mutf.",
            "Maliyet"
          ];

          return SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 30),
                _ustProfil(ad, uzman, resim),
                const SizedBox(height: 30),
                _itibarMetrikleri(data), // 📊 Dinamik Metrikler
                const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                    child: Divider(color: Colors.white10)),

                const Text("🎓 AKADEMİ MÜFREDATI",
                    style: TextStyle(
                        color: gold,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5)),
                const SizedBox(height: 20),

                _mufredatCiz(mufredat),

                const SizedBox(height: 40),
                _sefHikayesi(ad, uzman), // 🛡️ HATAYI DÜZELTEN FONKSİYON BURADA
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _mufredatCiz(List<String> liste) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      alignment: WrapAlignment.center,
      children: liste
          .map((e) => Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF111111),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white10),
                ),
                child: Text(e,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold)),
              ))
          .toList(),
    );
  }

  Widget _ustProfil(String ad, String uzman, String resim) {
    return Column(children: [
      CircleAvatar(
          radius: 62,
          backgroundColor: gold,
          child:
              CircleAvatar(radius: 60, backgroundImage: NetworkImage(resim))),
      const SizedBox(height: 15),
      Text(ad,
          style: const TextStyle(
              color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
      Text(uzman, style: const TextStyle(color: Colors.white38, fontSize: 13)),
    ]);
  }

  Widget _itibarMetrikleri(Map<String, dynamic> data) {
    final String puan =
        (data['itibar_puani'] ?? data['puan'] ?? "4.9").toString();
    final String mezun =
        (data['mezun_sayisi'] ?? data['mezun'] ?? "12").toString();
    final String muhur =
        (data['muhur_sayisi'] ?? data['muhur'] ?? "24").toString();

    return Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
      _metrik("İTİBAR", puan, Icons.star),
      _metrik("MEZUN", mezun, Icons.school),
      _metrik("MÜHÜR", muhur, Icons.workspace_premium),
    ]);
  }

  Widget _metrik(String l, String v, IconData i) {
    return Column(children: [
      Icon(i, color: gold, size: 20),
      const SizedBox(height: 5),
      Text(v,
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold)),
      Text(l, style: const TextStyle(color: Colors.white38, fontSize: 9)),
    ]);
  }

  // 🛡️ İŞTE KAYIP OLAN VE HATAYI GİDEREN FONKSİYON:
  Widget _sefHikayesi(String ad, String uzman) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Text(
          "$ad, Arena standartlarında $uzman mühürlü bir şeftir. Akademi bünyesinde yeni nesil şefler yetiştirmektedir.",
          textAlign: TextAlign.center,
          style: const TextStyle(
              color: Colors.white70, fontSize: 13, height: 1.5)),
    );
  }
}
