import 'package:flutter/material.dart';
import 'sepetim.dart'; // Eğer dosya adı sepetim.dart ise

class DukkanVitrini extends StatelessWidget {
  final String dukkanAdi;
  const DukkanVitrini({super.key, required this.dukkanAdi});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title:
            Text(dukkanAdi, style: const TextStyle(color: Color(0xFFFFB300))),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart, color: Color(0xFFFFB300)),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (context) => const Sepetim())),
          )
        ],
      ),
      body: const Center(
          child: Text("Dükkan İçeriği Yükleniyor...",
              style: TextStyle(color: Colors.white24))),
    );
  }
}
