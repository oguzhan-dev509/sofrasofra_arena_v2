// lib/modules/ev_lezzetleri_vitrini.dart
import 'package:flutter/material.dart';

class EvLezzetleriVitrini extends StatelessWidget {
  const EvLezzetleriVitrini({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF5E6), // Sıcak fildişi tonu
      appBar: AppBar(
        title: const Text("MAHALLE MUTFAĞI",
            style: TextStyle(color: Colors.brown, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.brown),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(15),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.7,
            crossAxisSpacing: 15,
            mainAxisSpacing: 15),
        itemBuilder: (context, index) => _evLezzetiKarti(),
      ),
    );
  }

  Widget _evLezzetiKarti() {
    return Container(
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)
          ]),
      child: Column(
        children: [
          Expanded(
              child: ClipRRect(
                  borderRadius: BorderRadius.circular(25),
                  child: Image.network(
                      "https://images.unsplash.com/photo-1543339308-43e59d6b73a6",
                      fit: BoxFit.cover))), // Temsili ev yemeği
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Ayşe Teyze'nin Mantısı",
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const Text("Taze, günlük ve katkısız.",
                    style: TextStyle(fontSize: 10, color: Colors.grey)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("150 TL",
                        style: TextStyle(
                            color: Colors.orange, fontWeight: FontWeight.bold)),
                    Icon(Icons.favorite_border, color: Colors.red[300]),
                  ],
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
