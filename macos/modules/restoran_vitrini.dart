// lib/modules/restoran_vitrini.dart
import 'package:flutter/material.dart';

class RestoranVitrini extends StatelessWidget {
  const RestoranVitrini({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
          backgroundColor: Colors.black,
          title: const Text("ELITE RESTORANLAR",
              style: TextStyle(color: Color(0xFFFFB300)))),
      body: ListView.builder(
        padding: const EdgeInsets.all(10),
        itemBuilder: (context, index) => _restoranKarti(),
      ),
    );
  }

  Widget _restoranKarti() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      height: 120,
      decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(15)),
      child: Row(
        children: [
          Container(
              width: 120,
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  image: const DecorationImage(
                      image: NetworkImage(
                          "https://images.unsplash.com/photo-1514362545857-3bc16c4c7d1b"),
                      fit: BoxFit.cover))),
          const Expanded(
            child: Padding(
              padding: EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Hacıoğlu Kebap",
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18)),
                  Text("Elite Teslimat • 20-30 dk",
                      style: TextStyle(color: Colors.grey, fontSize: 12)),
                  Spacer(),
                  Text("4.9 ★ (500+ Yorum)",
                      style: TextStyle(color: Color(0xFFFFB300), fontSize: 12)),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
