import 'package:flutter/material.dart';
import 'package:sofrasofra_arena_v2/lokasyon_merkezi.dart'; // V1'den getirdiğimiz atlas

class DukkanKurSayfasi extends StatefulWidget {
  const DukkanKurSayfasi({super.key});

  @override
  State<DukkanKurSayfasi> createState() => _DukkanKurSayfasiState();
}

class _DukkanKurSayfasiState extends State<DukkanKurSayfasi> {
  final TextEditingController _adController = TextEditingController();
  final TextEditingController _dukkanController = TextEditingController();
  final TextEditingController _uzmanlikController = TextEditingController();

  // ✨ YENİ: Dünkü 3'lü Segment Seçimi
  String _secilenTur = "Ev Lezzetleri";
  final List<String> _magazaTurleri = [
    "Ev Lezzetleri",
    "Restoran Menüleri",
    "Usta Şefler"
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Color(0xFFFFB300)),
        title: const Text("DÜKKANIMI MÜHÜRLE",
            style: TextStyle(
                color: Color(0xFFFFB300), fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.add_business, color: Color(0xFFFFB300), size: 60),
            const SizedBox(height: 20),
            const Text("ARENA'YA HOŞ GELDİN ŞEF!",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            const Text(
                "Dükkanını kur ve m_id kimliğini alarak Elite ağa katıl.",
                style: TextStyle(color: Colors.grey, fontSize: 14)),
            const SizedBox(height: 30),

            // ✍️ AD SOYAD
            _buildGirisAlani(
                "Adınız Soyadınız (u_id sahibi)", Icons.person, _adController),
            const SizedBox(height: 20),

            // 🏛️ DÜKKAN ADI
            _buildGirisAlani("Dükkanınızın Tabela Adı (m_ad)", Icons.store,
                _dukkanController),
            const SizedBox(height: 20),

            // 🎯 MAĞAZA TÜRÜ SEÇİMİ (3 ANA KAPI)
            const Text("Mağaza Kategorisi",
                style: TextStyle(color: Color(0xFFFFB300), fontSize: 12)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(15),
                border:
                    Border.all(color: const Color(0xFFFFB300).withOpacity(0.3)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _secilenTur,
                  dropdownColor: const Color(0xFF1A1A1A),
                  style: const TextStyle(color: Colors.white),
                  isExpanded: true,
                  items: _magazaTurleri.map((String tur) {
                    return DropdownMenuItem<String>(
                        value: tur, child: Text(tur));
                  }).toList(),
                  onChanged: (yeni) => setState(() => _secilenTur = yeni!),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 👨‍🍳 UZMANLIK
            _buildGirisAlani("Uzmanlık (Tarif Bilgisi İçin)",
                Icons.restaurant_menu, _uzmanlikController),
            const SizedBox(height: 40),

            // 🚀 KAYDI TAMAMLA
            ElevatedButton(
              onPressed: () => _kaydiTamamla(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFB300),
                minimumSize: const Size(double.infinity, 60),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15)),
              ),
              child: const Text("DÜKKANIMI AÇ VE MÜHÜRLE",
                  style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGirisAlani(
      String etiket, IconData ikon, TextEditingController controller) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: etiket,
        labelStyle: const TextStyle(color: Colors.grey),
        prefixIcon: Icon(ikon, color: const Color(0xFFFFB300)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide:
              BorderSide(color: const Color(0xFFFFB300).withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Color(0xFFFFB300)),
        ),
        filled: true,
        fillColor: const Color(0xFF1A1A1A),
      ),
    );
  }

  void _kaydiTamamla(BuildContext context) {
    // 💡 BURASI KRİTİK: Dün konuştuğumuz m_acilis_tarihi burada mühürlenir
    DateTime acilisTarihi = DateTime.now();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Icon(Icons.verified, color: Color(0xFFFFB300), size: 50),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("${_dukkanController.text}",
                style: const TextStyle(
                    color: Color(0xFFFFB300),
                    fontWeight: FontWeight.bold,
                    fontSize: 20)),
            const SizedBox(height: 10),
            Text("Kategori: $_secilenTur",
                style: const TextStyle(color: Colors.white70)),
            Text(
                "Açılış: ${acilisTarihi.day}/${acilisTarihi.month}/${acilisTarihi.year}",
                style: const TextStyle(color: Colors.white54, fontSize: 12)),
            const Divider(color: Colors.white10, height: 30),
            const Text("Dükkanın m_id ile sisteme mühürlendi!",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text("ARENA'YA GİR",
                style: TextStyle(
                    color: Color(0xFFFFB300), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
