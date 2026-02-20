import 'package:flutter/material.dart';

class UrunDetay extends StatefulWidget {
  final String urunAdi;
  final String urunFiyat;
  final String urunGorsel;

  const UrunDetay(
      {super.key,
      required this.urunAdi,
      required this.urunFiyat,
      required this.urunGorsel});

  @override
  State<UrunDetay> createState() => _UrunDetayState();
}

class _UrunDetayState extends State<UrunDetay> {
  int adet = 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: CustomScrollView(
        slivers: [
          // 🖼️ Üst Esnek Görsel Alanı
          SliverAppBar(
            expandedHeight: 400,
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Color(0xFFFFB300)),
            flexibleSpace: FlexibleSpaceBar(
              background: Image.network(
                widget.urunGorsel,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const Center(
                    child: Icon(Icons.restaurant,
                        color: Colors.white24, size: 100)),
              ),
            ),
          ),

          // 📜 Ürün Bilgileri Alanı
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.all(25),
              decoration: const BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(widget.urunAdi,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold)),
                      ),
                      Text(widget.urunFiyat,
                          style: const TextStyle(
                              color: Color(0xFFFFB300),
                              fontSize: 24,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Row(
                    children: [
                      Icon(Icons.star, color: Color(0xFFFFB300), size: 18),
                      Text(" 4.9 (120+ Değerlendirme)",
                          style:
                              TextStyle(color: Colors.white54, fontSize: 14)),
                    ],
                  ),
                  const SizedBox(height: 30),
                  const Text("ÜRÜN AÇIKLAMASI",
                      style: TextStyle(
                          color: Color(0xFFFFB300),
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2)),
                  const SizedBox(height: 10),
                  const Text(
                    "Şef Arda Türkmen'in özel tarifiyle hazırlanan, taze mantar ve trüf yağı ile harmanlanmış, damaklarda unutulmaz bir iz bırakan imza lezzet.",
                    style: TextStyle(
                        color: Colors.white70, fontSize: 16, height: 1.5),
                  ),
                  const SizedBox(height: 40),
                  _buildMiktarSecici(),
                  const SizedBox(height: 100), // Buton için boşluk
                ],
              ),
            ),
          ),
        ],
      ),
      bottomSheet: _buildSiparisBar(),
    );
  }

  Widget _buildMiktarSecici() {
    return Row(
      children: [
        const Text("ADET:",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        const SizedBox(width: 20),
        _miktarButonu(Icons.remove, () {
          if (adet > 1) setState(() => adet--);
        }),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(adet.toString(),
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold)),
        ),
        _miktarButonu(Icons.add, () => setState(() => adet++)),
      ],
    );
  }

  Widget _miktarButonu(IconData ikon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFFFB300)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(ikon, color: const Color(0xFFFFB300), size: 20),
      ),
    );
  }

  Widget _buildSiparisBar() {
    return Container(
      padding: const EdgeInsets.all(20),
      color: const Color(0xFF1A1A1A),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFFB300),
          minimumSize: const Size(double.infinity, 60),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        ),
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: const Color(0xFFFFB300),
              content: Text("${widget.urunAdi} Sepete Eklendi!",
                  style: const TextStyle(
                      color: Colors.black, fontWeight: FontWeight.bold)),
            ),
          );
        },
        child: const Text("SEPETE EKLE",
            style: TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5)),
      ),
    );
  }
}
