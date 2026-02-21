import 'package:flutter/material.dart';

class Sepetim extends StatefulWidget {
  const Sepetim({super.key});

  @override
  State<Sepetim> createState() => _SepetimState();
}

class _SepetimState extends State<Sepetim> {
  // 📜 Dinamik Liste Veri Tipleri Sabitlendi
  final List<Map<String, dynamic>> sepetUrunleri = [
    {
      "ad": "TRÜF MANTARLI RİZOTTO",
      "fiyat": 450.0, // Double yapıldı
      "adet": 1,
      "gorsel": "https://images.unsplash.com/photo-1476124369491-e7addf5db371"
    },
    {
      "ad": "ÖZEL SOSLU MANTI",
      "fiyat": 280.0, // Double yapıldı
      "adet": 2,
      "gorsel": "https://images.unsplash.com/photo-1534422298391-e4f8c170db76"
    },
  ];

  // 💰 Hesaplama Fonksiyonu Tip Hataları Giderildi
  double get toplamTutar {
    return sepetUrunleri.fold(
        0.0,
        (sum, item) =>
            sum + ((item['fiyat'] as double) * (item['adet'] as int)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFFFFB300)),
        title: const Text("ARENA SEPETİM",
            style: TextStyle(
                color: Color(0xFFFFB300),
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5)),
      ),
      body: sepetUrunleri.isEmpty
          ? _bosSepetGorunumu()
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: sepetUrunleri.length,
                    padding: const EdgeInsets.all(15),
                    itemBuilder: (context, index) => _sepetKarti(index),
                  ),
                ),
                _toplamOzeti(),
              ],
            ),
    );
  }

  Widget _sepetKarti(int index) {
    final urun = sepetUrunleri[index];
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(
              urun['gorsel'],
              width: 80,
              height: 80,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 80,
                  height: 80,
                  color: Colors.white10,
                  child: const Icon(Icons.restaurant,
                      color: Color(0xFFFFB300), size: 30),
                );
              },
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(urun['ad'],
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
                const SizedBox(height: 5),
                Text("${urun['fiyat']} TL",
                    style: const TextStyle(color: Color(0xFFFFB300))),
              ],
            ),
          ),
          _adetKontrol(index),
        ],
      ),
    );
  }

  Widget _adetKontrol(int index) {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.remove_circle_outline,
              color: Colors.white54, size: 20),
          onPressed: () => setState(() {
            if (sepetUrunleri[index]['adet'] > 1) {
              sepetUrunleri[index]['adet']--;
            } else {
              sepetUrunleri.removeAt(index); // 🗑️ 1'den azsa ürünü silsin
            }
          }),
        ),
        Text("${sepetUrunleri[index]['adet']}",
            style: const TextStyle(color: Colors.white)),
        IconButton(
          icon: const Icon(Icons.add_circle_outline,
              color: Color(0xFFFFB300), size: 20),
          onPressed: () => setState(() => sepetUrunleri[index]['adet']++),
        ),
      ],
    );
  }

  Widget _toplamOzeti() {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("TOPLAM TUTAR",
                  style: TextStyle(color: Colors.white54, fontSize: 16)),
              Text("${toplamTutar.toStringAsFixed(0)} TL",
                  style: const TextStyle(
                      color: Color(0xFFFFB300),
                      fontSize: 24,
                      fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFB300),
              minimumSize: const Size(double.infinity, 60),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15)),
            ),
            onPressed: () => _siparisOnaylandiDialog(),
            child: const Text("SİPARİŞİ MÜHÜRLE",
                style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 18)),
          ),
        ],
      ),
    );
  }

  void _siparisOnaylandiDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 80),
            const SizedBox(height: 20),
            const Text("SİPARİŞ MÜHÜRLENDİ!",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            const Text(
              "Şefler lezzetleri hazırlamaya başladı.",
              style: TextStyle(color: Colors.white54),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("TAMAM",
                  style: TextStyle(color: Color(0xFFFFB300))),
            )
          ],
        ),
      ),
    );
  }

  Widget _bosSepetGorunumu() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_basket_outlined,
              color: Colors.white10, size: 100),
          SizedBox(height: 20),
          Text("SEPETİNİZ ŞU AN BOŞ",
              style: TextStyle(color: Colors.white54, fontSize: 18)),
        ],
      ),
    );
  }
}
