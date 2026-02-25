import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../main.dart';

class VitrinMerkeziSayfasi extends StatefulWidget {
  const VitrinMerkeziSayfasi({super.key});

  @override
  State<VitrinMerkeziSayfasi> createState() => _VitrinMerkeziSayfasiState();
}

class _VitrinMerkeziSayfasiState extends State<VitrinMerkeziSayfasi> {
  String dukkanAdi = "SOFRASOFRA.COM";
  String seciliKategori = "RESTORANLAR";

  final List<Map<String, dynamic>> _onSekizUrun = List.generate(
      18,
      (index) => {
            "ad": "",
            "tarif": "",
            "gelAlFiyat": "",
            "goturFiyat": "",
            "resimYolu": "",
            "teslimat": true
          });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: Text(dukkanAdi,
            style: const TextStyle(
                color: Color(0xFFFFB300),
                fontWeight: FontWeight.bold,
                fontSize: 18)),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _kategoriSeciciWidget(),
            _hizliErisimBari(context),
            const SizedBox(height: 10),
            _urunGridiWidget(),
            const SizedBox(height: 100),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFFFFB300),
        onPressed: _vitriniMuhurle,
        icon: const Icon(Icons.send, color: Colors.black),
        label: const Text("ARENA'YA GÖNDER",
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
    );
  }

  // 🧭 Kategori Seçici (ASCII Uyumlu)
  Widget _kategoriSeciciWidget() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: ["EV LEZZETLERİ", "RESTORANLAR", "USTA ŞEFLER"].map((k) {
        bool secili = seciliKategori == k;
        return GestureDetector(
          onTap: () => setState(() => seciliKategori = k),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
            decoration: BoxDecoration(
              color: secili ? const Color(0xFFFFB300) : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: secili ? const Color(0xFFFFB300) : Colors.white10),
            ),
            child: Text(k,
                style: TextStyle(
                    color: secili ? Colors.black : Colors.white38,
                    fontSize: 10,
                    fontWeight: FontWeight.bold)),
          ),
        );
      }).toList(),
    );
  }

  // 💳 Hızlı Erişim Barı
  Widget _hizliErisimBari(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _barButonWidget(
              Icons.location_on, "ADRES", () => _adresGirisPenceresi(context)),
          _barButonWidget(
              Icons.credit_card, "ODEME", () => _odemePenceresiGoster(context)),
        ],
      ),
    );
  }

  Widget _barButonWidget(IconData ikon, String metin, VoidCallback aksiyon) {
    return ActionChip(
      backgroundColor: Colors.white10,
      avatar: Icon(ikon, color: const Color(0xFFFFB300), size: 16),
      label: Text(metin,
          style: const TextStyle(color: Colors.white, fontSize: 10)),
      onPressed: aksiyon,
    );
  }

  // 🖼️ Ürün Izgarası
  Widget _urunGridiWidget() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 20,
          mainAxisSpacing: 25,
          childAspectRatio: 0.82),
      itemCount: 18,
      itemBuilder: (context, index) => _urunKaresiWidget(index),
    );
  }

  // 🍱 Ürün Karesi (Genişletilmiş Bilgi Alanı + Silme Butonu)
  Widget _urunKaresiWidget(int i) {
    bool dolu = _onSekizUrun[i]["ad"].toString().isNotEmpty;
    return GestureDetector(
      onTap: () => _urunDetayFormuAc(i),
      child: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                        color: const Color(0xFFFFB300),
                        width: 5), // ✨ Kalın Altın Çerçeve
                    boxShadow: dolu
                        ? [
                            BoxShadow(
                                color: const Color(0xFFFFB300).withAlpha(40),
                                blurRadius: 15)
                          ]
                        : null,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: _onSekizUrun[i]["resimYolu"] == ""
                        ? const Center(
                            child: Icon(Icons.add_a_photo,
                                color: Colors.white10, size: 30))
                        : kIsWeb
                            ? Image.network(_onSekizUrun[i]["resimYolu"],
                                fit: BoxFit.cover, width: double.infinity)
                            : Image.file(File(_onSekizUrun[i]["resimYolu"]),
                                fit: BoxFit.cover, width: double.infinity),
                  ),
                ),
                if (dolu)
                  Positioned(
                    top: 5,
                    right: 5,
                    child: GestureDetector(
                      onTap: () => setState(() => _onSekizUrun[i] = {
                            "ad": "",
                            "tarif": "",
                            "gelAlFiyat": "",
                            "goturFiyat": "",
                            "resimYolu": "",
                            "teslimat": true
                          }),
                      child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                              color: Colors.redAccent, shape: BoxShape.circle),
                          child: const Icon(Icons.close,
                              color: Colors.white, size: 14)),
                    ),
                  ),
                if (dolu)
                  const Positioned(
                      bottom: 8,
                      right: 8,
                      child:
                          Icon(Icons.edit, color: Color(0xFFFFB300), size: 14)),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // 🚀 Genişletilmiş ve Görünen Bilgi Alanı
          Text(dolu ? _onSekizUrun[i]["ad"].toUpperCase() : "BOS KUTU",
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold),
              maxLines: 1),
          Text(dolu ? "${_onSekizUrun[i]["gelAlFiyat"]} TL" : "-",
              style: const TextStyle(
                  color: Color(0xFFFFB300),
                  fontSize: 10,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  // 📝 Ürün Giriş Formu
  void _urunDetayFormuAc(int i) {
    TextEditingController ad =
        TextEditingController(text: _onSekizUrun[i]["ad"]);
    TextEditingController tarif =
        TextEditingController(text: _onSekizUrun[i]["tarif"]);
    TextEditingController gelAl =
        TextEditingController(text: _onSekizUrun[i]["gelAlFiyat"]);
    TextEditingController gotur =
        TextEditingController(text: _onSekizUrun[i]["goturFiyat"]);
    bool teslim = _onSekizUrun[i]["teslimat"];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0D0D0D),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      builder: (c) => StatefulBuilder(
          builder: (context, setModal) => Padding(
                padding: EdgeInsets.only(
                    bottom: MediaQuery.of(c).viewInsets.bottom,
                    left: 25,
                    right: 25,
                    top: 25),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text("URUNU MUHURLE",
                        style: TextStyle(
                            color: Color(0xFFFFB300),
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),
                    _inputWidget(ad, "Yemek Adi", Icons.restaurant),
                    _inputWidget(tarif, "Tarif / Icerik", Icons.menu_book),
                    Row(children: [
                      Expanded(
                          child:
                              _inputWidget(gelAl, "Gel-Al", Icons.storefront)),
                      const SizedBox(width: 15),
                      Expanded(
                          child: _inputWidget(
                              gotur, "Gotur", Icons.delivery_dining)),
                    ]),
                    SwitchListTile(
                      title: const Text("Teslimat Var mi?",
                          style:
                              TextStyle(color: Colors.white70, fontSize: 12)),
                      value: teslim,
                      activeColor: const Color(0xFFFFB300),
                      onChanged: (v) => setModal(() => teslim = v),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () async {
                        final r = await ImagePicker()
                            .pickImage(source: ImageSource.gallery);
                        if (r != null) {
                          setState(() => _onSekizUrun[i] = {
                                "ad": ad.text,
                                "tarif": tarif.text,
                                "gelAlFiyat": gelAl.text,
                                "goturFiyat": gotur.text,
                                "resimYolu": r.path,
                                "teslimat": teslim
                              });
                          Navigator.pop(c);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFB300),
                          minimumSize: const Size(double.infinity, 50)),
                      child: const Text("RESIM SEC VE KAYDET",
                          style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              )),
    );
  }

  Widget _inputWidget(TextEditingController c, String h, IconData ikon) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextField(
          controller: c,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            prefixIcon: Icon(ikon, color: const Color(0xFFFFB300), size: 18),
            hintText: h,
            hintStyle: const TextStyle(color: Colors.white24),
            filled: true,
            fillColor: Colors.white10,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none),
          ),
        ),
      );

  // 💳 Ödeme Penceresi
  void _odemePenceresiGoster(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF111111),
      builder: (c) => Container(
          padding: const EdgeInsets.all(30),
          child: const Text("ODEME SISTEMI AKTIF",
              style: TextStyle(color: Color(0xFFFFB300)))),
    );
  }

  // 📍 Adres Penceresi
  void _adresGirisPenceresi(BuildContext context) {
    showDialog(
        context: context,
        builder: (c) => AlertDialog(
                backgroundColor: const Color(0xFF111111),
                title: const Text("ADRES"),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(c),
                      child: const Text("KAYDET"))
                ]));
  }

  void _vitriniMuhurle() {
    arenaUrunHavuzu.add({
      "dukkan": dukkanAdi,
      "kategori": seciliKategori,
      "urunler": _onSekizUrun.where((u) => u["ad"] != "").toList()
    });
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text("VİTRİN ARENA'DA CANLI!")));
  }
}
