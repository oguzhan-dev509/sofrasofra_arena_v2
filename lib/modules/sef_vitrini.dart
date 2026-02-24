// lib/modules/sef_vitrini.dart
import 'package:flutter/material.dart';

class SefVitrini extends StatelessWidget {
  const SefVitrini({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: const Text("GASTRONOMİ AKADEMİSİ",
              style: TextStyle(color: Colors.black))),
      body: ListView.builder(
        itemCount: 5,
        itemBuilder: (context, index) => _sefKart(index),
      ),
    );
  }

  Widget _sefKart(int index) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          CircleAvatar(
              radius: 50,
              backgroundImage: NetworkImage(
                  "https://images.unsplash.com/photo-1583394838336-acd977736f90")), // Şef fotosu
          const SizedBox(height: 10),
          const Text("Şef Arda Türkmen",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const Text("İtalyan Mutfağı Uzmanı",
              style: TextStyle(color: Colors.grey)),
          const Divider(height: 30),
          SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: [_ozelTabak(), _ozelTabak(), _ozelTabak()])),
        ],
      ),
    );
  }

  Widget _ozelTabak() {
    return Container(
        width: 150,
        margin: const EdgeInsets.only(right: 15),
        child: Column(children: [
          ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Image.network(
                  "https://images.unsplash.com/photo-1473093226795-af9932fe5856")),
          const Text("İmzalı Risotto",
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        ]));
  }
}
