import 'package:flutter/material.dart';

class Sepetim extends StatelessWidget {
  // ✨ constructor'ı const olarak tanımladık, hatayı önler
  const Sepetim({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Color(0xFFFFB300)),
        title: const Text("SEPETİM",
            style: TextStyle(
                color: Color(0xFFFFB300), fontWeight: FontWeight.bold)),
      ),
      body: const Center(
        child: Text("Sepetiniz Boş", style: TextStyle(color: Colors.white24)),
      ),
    );
  }
}
