import 'package:flutter/material.dart';
import 'vitrin_merkezi.dart';
import 'akademi_merkezi.dart';
import 'sepetim.dart';
import 'urun_detay.dart';

class KategoriSayfasi extends StatefulWidget {
  final String kategoriAdi;
  const KategoriSayfasi({super.key, required this.kategoriAdi});

  @override
  State<KategoriSayfasi> createState() => _KategoriSayfasiState();
}

class _KategoriSayfasiState extends State<KategoriSayfasi> {
  // 📜 DİNAMİK ÜRÜN LİSTESİ
  List<Map<String, String>> urunler = [
    {
      "ad": "El Açması Mantı",
      "tarif": "Geleneksel ev usulü, ince hamur",
      "fiyat": "320 TL",
      "gorsel": "https://images.unsplash.com/photo-1534422298391-e4f8c170db76"
    },
    {
      "ad": "Köy Tereyağı",
      "tarif": "Taze, yayık ve tamamen katkısız",
      "fiyat": "450 TL",
      "gorsel": "https://images.unsplash.com/photo-1589927986089-35812388d1f4"
    },
    {
      "ad": "Ev Yapımı Turşu",
      "tarif": "Hasan Usta özel tarifi",
      "fiyat": "120 TL",
      "gorsel": ""
    },
    {
      "ad": "Süzme Yoğurt",
      "tarif": "Taş gibi, doğal ve yoğun",
      "fiyat": "150 TL",
      "gorsel": ""
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFFFFB300)),
        title: Text(widget.kategoriAdi.toUpperCase(),
            style: const TextStyle(
                color: Color(0xFFFFB300), fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          _modulKopruleri(context),
          const SizedBox(height: 10),
          _bolumBasligi("USTA ÜRETİCİLERİMİZ"),
          _ureticiYatayListe(),
          const SizedBox(height: 10),
          _bolumBasligi("EV YAPIMI ÖZEL SEÇKİ"),
          Expanded(
            child: urunler.isEmpty
                ? const Center(
                    child: Text("Ürün listesi boş.",
                        style: TextStyle(color: Colors.white54)))
                : GridView.builder(
                    padding: const EdgeInsets.all(15),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.58,
                      crossAxisSpacing: 15,
                      mainAxisSpacing: 15,
                    ),
                    itemCount: urunler.length,
                    itemBuilder: (context, index) => _urunKarti(context, index),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _urunKarti(BuildContext context, int index) {
    final urun = urunler[index];
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          Expanded(
            flex: 3,
            child: Stack(
              children: [
                GestureDetector(
                  onTap: () {
                    _bilgiGoster(context, "Premium Vitrin'e Geçiliyor...");
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const VitrinMerkezi()));
                  },
                  child: ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(25)),
                    child: urun['gorsel']!.isNotEmpty
                        ? Image.network(urun['gorsel']!,
                            height: double.infinity,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (c, e, s) => _tabelaIkonu())
                        : _tabelaIkonu(),
                  ),
                ),
                Positioned(
                  top: 10,
                  left: 10,
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        urunler.removeAt(index);
                      });
                      _bilgiGoster(context, "Ürün listeden kaldırıldı.");
                    },
                    child: CircleAvatar(
                        radius: 14,
                        backgroundColor: Colors.black.withOpacity(0.7),
                        child: const Icon(Icons.close,
                            color: Colors.red, size: 16)),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(urun['ad']!,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13)),
                  const SizedBox(height: 5),
                  Text(urun['tarif']!,
                      style:
                          const TextStyle(color: Colors.white54, fontSize: 10),
                      maxLines: 2),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(urun['fiyat']!,
                          style: const TextStyle(
                              color: Color(0xFFFFB300),
                              fontWeight: FontWeight.bold)),
                      InkWell(
                        onTap: () => _bilgiGoster(
                            context, "${urun['ad']} sepete eklendi!"),
                        child: const Icon(Icons.add_circle,
                            color: Color(0xFFFFB300), size: 30),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ✨ ASİL TABELA: "FontWeight.black" HATASI BURADA DÜZELTİLDİ (w900 YAPILDI)
  Widget _tabelaIkonu() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: const Color(0xFF2A2A2A),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.auto_awesome, color: Color(0xFFFFB300), size: 24),
            SizedBox(height: 8),
            Text("ÜRÜNLERİ\nİNCELE",
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Color(0xFFFFB300),
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5)),
          ],
        ),
      ),
    );
  }

  void _bilgiGoster(BuildContext context, String mesaj) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(mesaj),
        backgroundColor: const Color(0xFFFFB300),
        duration: const Duration(seconds: 1)));
  }

  Widget _modulKopruleri(BuildContext context) {
    return Container(
        padding: const EdgeInsets.symmetric(vertical: 15),
        color: const Color(0xFF1A1A1A),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          _kopruButonu(
              context, Icons.auto_awesome, "VİTRİNİM", const VitrinMerkezi()),
          _kopruButonu(
              context, Icons.school, "AKADEMİM", const AkademiMerkezi()),
          _kopruButonu(
              context, Icons.shopping_cart, "SEPETİM", const Sepetim()),
        ]));
  }

  Widget _kopruButonu(
      BuildContext context, IconData ikon, String etiket, Widget sayfa) {
    return InkWell(
        onTap: () => Navigator.push(
            context, MaterialPageRoute(builder: (context) => sayfa)),
        child: Column(children: [
          Icon(ikon, color: const Color(0xFFFFB300), size: 24),
          const SizedBox(height: 5),
          Text(etiket,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold))
        ]));
  }

  Widget _bolumBasligi(String baslik) {
    return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Align(
            alignment: Alignment.centerLeft,
            child: Text(baslik,
                style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 11,
                    fontWeight: FontWeight.bold))));
  }

  Widget _ureticiYatayListe() {
    return SizedBox(
        height: 85,
        child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 15),
            itemCount: 6,
            itemBuilder: (context, index) => Padding(
                padding: const EdgeInsets.only(right: 15),
                child: Column(children: [
                  const CircleAvatar(
                      radius: 25,
                      backgroundColor: Color(0xFF1A1A1A),
                      child: Icon(Icons.person,
                          color: Color(0xFFFFB300), size: 28)),
                  const SizedBox(height: 4),
                  Text("Şef ${index + 1}",
                      style:
                          const TextStyle(color: Colors.white38, fontSize: 8))
                ]))));
  }
}
