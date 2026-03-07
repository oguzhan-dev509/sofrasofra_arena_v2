import 'package:flutter/material.dart';

class UrunDetaySayfasi extends StatefulWidget {
  final String urunAdi;
  final String urunFiyat;
  final String urunGorsel;
  final String aciklama;
  final String dukkanAdi;
  final String konum;

  const UrunDetaySayfasi({
    super.key,
    required this.urunAdi,
    required this.urunFiyat,
    required this.urunGorsel,
    required this.aciklama,
    required this.dukkanAdi,
    required this.konum,
  });

  @override
  State<UrunDetaySayfasi> createState() => _UrunDetaySayfasiState();
}

class _UrunDetaySayfasiState extends State<UrunDetaySayfasi> {
  int adet = 1;

  bool _isHttp(String s) {
    return s.startsWith('http://') || s.startsWith('https://');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 360,
            pinned: true,
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Color(0xFFFFB300)),
            flexibleSpace: FlexibleSpaceBar(
              background: _isHttp(widget.urunGorsel)
                  ? Image.network(
                      widget.urunGorsel,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.black12,
                          child: const Center(
                            child: Icon(
                              Icons.restaurant,
                              color: Colors.white24,
                              size: 100,
                            ),
                          ),
                        );
                      },
                    )
                  : Container(
                      color: Colors.black12,
                      child: const Center(
                        child: Icon(
                          Icons.restaurant,
                          color: Colors.white24,
                          size: 100,
                        ),
                      ),
                    ),
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          widget.urunAdi,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        widget.urunFiyat.isEmpty
                            ? "Fiyat yok"
                            : widget.urunFiyat,
                        style: const TextStyle(
                          color: Color(0xFFFFB300),
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (widget.dukkanAdi.isNotEmpty)
                    Row(
                      children: [
                        const Icon(
                          Icons.storefront_outlined,
                          color: Color(0xFFFFB300),
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.dukkanAdi,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  if (widget.konum.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          color: Color(0xFFFFB300),
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.konum,
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 14),
                  const Row(
                    children: [
                      Icon(Icons.star, color: Color(0xFFFFB300), size: 18),
                      SizedBox(width: 6),
                      Text(
                        "4.9 (120+ değerlendirme)",
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  const Text(
                    "ÜRÜN AÇIKLAMASI",
                    style: TextStyle(
                      color: Color(0xFFFFB300),
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    widget.aciklama.isEmpty
                        ? "Bu ürün için henüz açıklama girilmedi."
                        : widget.aciklama,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 36),
                  _buildMiktarSecici(),
                  const SizedBox(height: 110),
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
        const Text(
          "ADET:",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 20),
        _miktarButonu(Icons.remove, () {
          if (adet > 1) {
            setState(() => adet--);
          }
        }),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            adet.toString(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        _miktarButonu(Icons.add, () {
          setState(() => adet++);
        }),
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
        child: Icon(
          ikon,
          color: const Color(0xFFFFB300),
          size: 20,
        ),
      ),
    );
  }

  Widget _buildSiparisBar() {
    final String fiyat = widget.urunFiyat.trim();
    final String toplamText =
        fiyat.isEmpty ? "$adet adet" : "$adet adet • $fiyat";

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      color: const Color(0xFF1A1A1A),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              toplamText,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFB300),
              minimumSize: const Size(double.infinity, 60),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: const Color(0xFFFFB300),
                  content: Text(
                    "${widget.urunAdi} sepete eklendi!",
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            },
            child: const Text(
              "SEPETE EKLE",
              style: TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
