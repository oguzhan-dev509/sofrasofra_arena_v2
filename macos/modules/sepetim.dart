import 'package:flutter/material.dart';
import 'odeme_sayfasi.dart';

class Sepetim extends StatelessWidget {
  const Sepetim({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("SEPETİM",
            style: TextStyle(
                color: Color(0xFFFFB300), fontWeight: FontWeight.bold)),
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFFFFB300)),
      ),
      body: Column(
        children: [
          // 🛒 SEPET LİSTESİ
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(15),
              itemCount: 2, // Örnek ürün sayısı
              itemBuilder: (context, index) {
                return _sepetKarti("Ev Yapımı Mantı", 150.0);
              },
            ),
          ),

          // 💰 TOPLAM VE ÖDEME ALANI
          _sepetAltPanel(context),
        ],
      ),
    );
  }

  Widget _sepetKarti(String urunAd, double fiyat) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFFFB300).withOpacity(0.1)),
      ),
      child: Row(
        children: [
          const Icon(Icons.restaurant, color: Color(0xFFFFB300), size: 30),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(urunAd,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
                Text("${fiyat.toStringAsFixed(0)} TL",
                    style:
                        const TextStyle(color: Colors.white54, fontSize: 12)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _sepetAltPanel(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Toplam",
                  style: TextStyle(color: Colors.white54, fontSize: 16)),
              Text("300 TL",
                  style: TextStyle(
                      color: Color(0xFFFFB300),
                      fontSize: 24,
                      fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const OdemeSayfasi()));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFB300),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15)),
              ),
              child: const Text("ÖDEMEYE GEÇ",
                  style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }
}
