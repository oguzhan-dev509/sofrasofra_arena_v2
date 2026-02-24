import 'package:flutter/material.dart';
import 'dukkan_detay_sayfasi.dart';
import '../main.dart'; // Hafızaya ulaşım

class EvLezzetleriVitrini extends StatefulWidget {
  const EvLezzetleriVitrini({super.key});

  @override
  State<EvLezzetleriVitrini> createState() => _EvLezzetleriVitriniState();
}

class _EvLezzetleriVitriniState extends State<EvLezzetleriVitrini> {
  // 🧭 PASAJ NAVİGASYON BAŞLIĞI (Satıcı paneliyle uyumlu hale getirildi)
  String seciliKategori = "EV YEMEKLERİ";

  // 🧠 STATİK VERİ HAVUZU (Silinenler geri geldi!)
  final List<Map<String, dynamic>> dukkanListesi = [
    {
      "ad": "Ayşe Hanım Mutfağı",
      "kat": "EV YEMEKLERİ",
      "tarif": "Ev yapımı mantı ve sarmalar.",
      "img": "https://images.unsplash.com/photo-1543339308-43e59d6b73a6"
    },
    {
      "ad": "Zeynep Ev Tatlısı",
      "kat": "EV YAPIMI TATLI",
      "tarif": "Gerçek ev yapımı lezzetler.",
      "img": "https://images.unsplash.com/photo-1589119908995-c6837fa14848"
    },
    {
      "ad": "Sütçü Fatma Abla",
      "kat": "SÜT ÜRÜNLERİ",
      "tarif": "Günlük taze köy sütü.",
      "img": "https://images.unsplash.com/photo-1550583724-125581f77833"
    },
    {
      "ad": "Emine Teyze Turşuları",
      "kat": "TURŞULAR",
      "tarif": "Kütür kütür ev turşusu.",
      "img": "https://images.unsplash.com/photo-1589119908995-c6837fa14848"
    },
  ];

  @override
  Widget build(BuildContext context) {
    // 🔍 1. Statik dükkanları Pasaj kategorisine göre süz
    var filtreliStatikDukkanlar =
        dukkanListesi.where((d) => d["kat"] == seciliKategori).toList();

    // 🔍 2. Satıcıdan gelenleri süz
    var saticiUrunleri =
        arenaUrunHavuzu.where((u) => u['tip'] == "Ev Lezzetleri").toList();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("EV LEZZETLER PASAJI",
            style: TextStyle(
                color: Color(0xFFFFB300),
                fontWeight: FontWeight.bold,
                fontSize: 16)),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Color(0xFFFFB300)),
      ),
      body: Column(
        children: [
          _kategoriNavigasyonu(), // 🛠️ Butonlar artık çalışıyor
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                // 🔥 SATICI ÜRÜNLERİ (Sadece Ev Yemeği kategorisinde gösterelim)
                if (saticiUrunleri.isNotEmpty &&
                    seciliKategori == "EV YEMEKLERİ") ...[
                  const Text("PASAJDA YENİ EKLENENLER",
                      style: TextStyle(
                          color: Color(0xFFFFB300),
                          fontSize: 10,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  ...saticiUrunleri
                      .map((urun) => _yeniSaticiKarti(urun))
                      .toList(),
                  const Divider(
                      color: Colors.white10, thickness: 1, height: 30),
                ],

                // 🏠 STATİK DÜKKANLAR GRIDİ
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.65,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12),
                  itemCount: filtreliStatikDukkanlar.length,
                  itemBuilder: (context, index) {
                    var dukkan = filtreliStatikDukkanlar[index];
                    return _arenaDukkanKarti(
                        context, dukkan["ad"], dukkan["tarif"], dukkan["img"]);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _kategoriNavigasyonu() {
    final List<Map<String, dynamic>> kategoriler = [
      {"ad": "EV YEMEKLERİ", "ikon": Icons.restaurant_menu},
      {"ad": "EV YAPIMI TATLI", "ikon": Icons.cake},
      {"ad": "SÜT ÜRÜNLERİ", "ikon": Icons.local_drink},
      {"ad": "TURŞULAR", "ikon": Icons.egg_alt_outlined},
    ];

    return SizedBox(
      height: 110,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: kategoriler.length,
        itemBuilder: (context, index) {
          bool seciliMi = seciliKategori == kategoriler[index]["ad"];
          return GestureDetector(
            onTap: () => setState(() => seciliKategori =
                kategoriler[index]["ad"]), // 🚀 Tıklayınca filtre değişir!
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: seciliMi
                                ? const Color(0xFFFFB300)
                                : Colors.white12,
                            width: 2)),
                    child: Icon(kategoriler[index]["ikon"],
                        color:
                            seciliMi ? const Color(0xFFFFB300) : Colors.white38,
                        size: 24),
                  ),
                  const SizedBox(height: 6),
                  Text(kategoriler[index]["ad"],
                      style: TextStyle(
                          color: seciliMi ? Colors.white : Colors.white38,
                          fontSize: 7,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _yeniSaticiKarti(Map<String, dynamic> urun) {
    return Card(
      color: const Color(0xFF111111),
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: Color(0xFFFFB300), width: 0.5)),
      child: ListTile(
        leading: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(urun['img'],
                width: 60,
                height: 60,
                fit: BoxFit.cover,
                errorBuilder: (c, e, s) =>
                    const Icon(Icons.restaurant, color: Color(0xFFFFB300)))),
        title: Text(urun['ad'],
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14)),
        subtitle: Text(urun['dukkan'],
            style: const TextStyle(color: Colors.white38, fontSize: 11)),
        trailing: Text("${urun['fiyat']} ₺",
            style: const TextStyle(
                color: Color(0xFFFFB300), fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _arenaDukkanKarti(
      BuildContext context, String ad, String tarif, String img) {
    return GestureDetector(
      onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => DukkanDetaySayfasi(dukkanAdi: ad))),
      child: Container(
        decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(15),
            border:
                Border.all(color: const Color(0xFFFFB300).withOpacity(0.2))),
        child: Column(
          children: [
            Expanded(
                child: ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(15)),
                    child: Image.network(img,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        errorBuilder: (c, e, s) => const Icon(Icons.store)))),
            Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(ad,
                          style: const TextStyle(
                              color: Color(0xFFFFB300),
                              fontWeight: FontWeight.bold,
                              fontSize: 11)),
                      const SizedBox(height: 4),
                      Text(tarif,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: Colors.white60, fontSize: 8))
                    ])),
          ],
        ),
      ),
    );
  }
}
