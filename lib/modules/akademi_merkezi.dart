import 'package:flutter/material.dart';

class AkademiMerkeziSayfasi extends StatelessWidget {
  const AkademiMerkeziSayfasi({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text("ŞEF AKADEMİ MERKEZİ",
            style: TextStyle(
                color: Color(0xFFFFB300),
                fontSize: 13,
                fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Color(0xFFFFB300)),
      ),
      body: const Center(
        child: Text("Akademi Modülleri Yükleniyor...",
            style: TextStyle(color: Colors.white38, fontSize: 12)),
      ),
    );
  }
}
