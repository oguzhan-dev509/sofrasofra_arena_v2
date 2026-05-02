import 'package:flutter/material.dart';

import 'package:sofrasofra_arena_v2/data/arena_dummy_data.dart';

class DukkanKurSayfasi extends StatefulWidget {
  const DukkanKurSayfasi({super.key});

  @override
  State<DukkanKurSayfasi> createState() => _DukkanKurSayfasiState();
}

class _DukkanKurSayfasiState extends State<DukkanKurSayfasi> {
  final TextEditingController _adController = TextEditingController();
  final TextEditingController _dukkanController = TextEditingController();
  final TextEditingController _fiyatController = TextEditingController();
  String secilenKategori = "Ev Lezzetleri";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Color(0xFFFFB300)),
        title: const Text("DÜKKANINI ARENA'DA KUR",
            style: TextStyle(
                color: Color(0xFFFFB300),
                fontSize: 13,
                fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("DÜKKAN BİLGİLERİ",
                style: TextStyle(
                    color: Color(0xFFFFB300),
                    fontSize: 11,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),

            _inputAlan(
                "DÜKKAN İSMİ", _dukkanController, "Örn: Hatice Ana Mutfağı"),
            _inputAlan("İSTATİSTİK / BAŞLIK", _adController,
                "Örn: 25 Yıllık Lezzet Çınarı"),

            const SizedBox(height: 10),
            const Text("KATEGORİ SEÇİN",
                style: TextStyle(color: Colors.white38, fontSize: 10)),
            DropdownButton<String>(
              value: secilenKategori,
              isExpanded: true,
              dropdownColor: Colors.black,
              style: const TextStyle(color: Colors.white),
              items: ["Ev Lezzetleri", "Restoranlar", "Usta Şefler"]
                  .map((String value) => DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      ))
                  .toList(),
              onChanged: (String? newValue) {
                setState(() {
                  secilenKategori = newValue!;
                });
              },
            ),

            const SizedBox(height: 20),
            _inputAlan("BAŞLANGIÇ FİYATI (₺)", _fiyatController, "0.00"),

            const SizedBox(height: 40),

            // 🚀 DÜKKANI OLUŞTUR BUTONU
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: () => _dukkaniKaydet(context),
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFB300),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10))),
                child: const Text("DÜKKANI ARENA'YA AÇ",
                    style: TextStyle(
                        color: Colors.black, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _inputAlan(String label, TextEditingController ctrl, String hint) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: TextField(
        controller: ctrl,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Color(0xFFFFB300), fontSize: 11),
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white10, fontSize: 11),
          enabledBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white10)),
          focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFFFFB300))),
        ),
      ),
    );
  }

  void _dukkaniKaydet(BuildContext context) {
    if (_dukkanController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Lütfen Dükkan İsmini Giriniz!")));
      return;
    }

    setState(() {
      arenaUrunHavuzu.add({
        "ad": _adController.text,
        "dukkan": _dukkanController.text,
        "fiyat": _fiyatController.text,
        "tip": secilenKategori,
        "img":
            "https://images.unsplash.com/photo-1555396273-367ea4eb4db5", // Varsayılan
        "videoUrl": "",
        "galeri": []
      });
    });

    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Dükkanınız Başarıyla Kuruldu!")));
    Navigator.pop(context);
  }
}
