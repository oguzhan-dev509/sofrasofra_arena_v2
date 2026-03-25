import 'package:flutter/material.dart';

class TestDetay extends StatelessWidget {
  final String ad;

  const TestDetay({super.key, required this.ad});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(ad)),
      body: Center(
        child: Text(
          "Detay sayfası açıldı: $ad",
          style: const TextStyle(fontSize: 22),
        ),
      ),
    );
  }
}
