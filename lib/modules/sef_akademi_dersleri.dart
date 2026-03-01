import 'package:flutter/material.dart';

class SefAkademiDersleri extends StatelessWidget {
  final String sefAdi;
  final List<dynamic> dersler; // Firestore'dan gelen akadem_mufredat listesi

  const SefAkademiDersleri(
      {super.key, required this.sefAdi, required this.dersler});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Color(0xFFFFB300)),
        title: Text("$sefAdi AKADEMİSİ",
            style: const TextStyle(
                color: Color(0xFFFFB300),
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5)),
      ),
      body: dersler.isEmpty
          ? _bosDersUyari()
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: dersler.length,
              itemBuilder: (context, index) {
                return _dersKarti(index + 1, dersler[index].toString());
              },
            ),
    );
  }

  Widget _bosDersUyari() {
    return const Center(
      child: Text("Şef henüz eğitim müfredatını güncellemedi.",
          style: TextStyle(color: Colors.white24, fontSize: 13)),
    );
  }

  Widget _dersKarti(int sira, String dersAdi) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0A),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFFFB300).withOpacity(0.1),
          child: Text(sira.toString(),
              style: const TextStyle(
                  color: Color(0xFFFFB300), fontWeight: FontWeight.bold)),
        ),
        title: Text(dersAdi.toUpperCase(),
            style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1)),
        subtitle: const Text("Eğitimi İzlemek İçin Tıklayın",
            style: TextStyle(color: Colors.white24, fontSize: 9)),
        trailing: const Icon(Icons.play_circle_outline,
            color: Color(0xFFFFB300), size: 20),
        onTap: () {
          // Burada şefin genel akademi videosuna veya derse özel videoya yönlendirme yapılabilir
        },
      ),
    );
  }
}
