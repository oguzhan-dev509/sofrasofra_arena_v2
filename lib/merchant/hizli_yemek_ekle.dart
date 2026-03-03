import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HizliYemekEkle extends StatelessWidget {
  HizliYemekEkle({super.key});
  final TextEditingController _ad = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Hızlı Ekle")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
                controller: _ad,
                decoration: const InputDecoration(labelText: "Yemek Adı")),
            ElevatedButton(
              onPressed: () async {
                if (_ad.text.isNotEmpty) {
                  await FirebaseFirestore.instance.collection('urunler').add({
                    "ad": _ad.text,
                    "dukkanAdi": "Hızlı Mutfak",
                    "kayitTarihi": FieldValue.serverTimestamp(),
                  });
                  if (context.mounted) Navigator.pop(context);
                }
              },
              child: const Text("Kaydet"),
            ),
          ],
        ),
      ),
    );
  }
}
