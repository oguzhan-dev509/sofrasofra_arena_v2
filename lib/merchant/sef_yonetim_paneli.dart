import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'hizli_yemek_ekle.dart';

class SefYonetimPaneli extends StatefulWidget {
  const SefYonetimPaneli({super.key});

  @override
  State<SefYonetimPaneli> createState() => _SefYonetimPaneliState();
}

class _SefYonetimPaneliState extends State<SefYonetimPaneli> {
  // 📝 PRESTİJ KONTROLCÜLERİ (5 Madde İçin)
  final _adController = TextEditingController();
  final _uzmanlikController = TextEditingController();
  final _bioController = TextEditingController(); // 01. Madde
  final _youtubeController = TextEditingController(); // 02. Madde
  final _danismanlikController = TextEditingController(); // 04. Madde
  final _rezervasyonLinkController = TextEditingController(); // 05. Madde
  final _saatUcretiController = TextEditingController();

  List<String> _secilenDersler = [];
  bool _isSaving = false;

  // 🔥 ARENA'YA 5 MADDELİK MÜHÜR BASMA
  Future<void> _arenaYayinla() async {
    if (_adController.text.isEmpty) return;
    setState(() => _isSaving = true);
    try {
      await FirebaseFirestore.instance.collection('urunler').add({
        "dukkan": _adController.text.trim().toUpperCase(),
        "kategori": _uzmanlikController.text.trim(),
        "bio": _bioController.text.trim(), // 01
        "akadem_mufredat": _secilenDersler, // 02
        "youtube_url": _youtubeController.text.trim(), // 02
        "danismanlik_notu": _danismanlikController.text.trim(), // 04
        "rezervasyon_url": _rezervasyonLinkController.text.trim(), // 05
        "saat_ucreti": _saatUcretiController.text.trim(),
        "tip": "Usta Sefler",
        "onayDurumu": "onaylandi",
        "kayitTarihi": FieldValue.serverTimestamp(),
      });
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("✅ 5 PRESTİJ MADDESİ ARENA'DA CANLI!")));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          title: const Text("ELİTE ŞEF KOMUTA MERKEZİ",
              style: TextStyle(
                  color: Color(0xFFFFB300),
                  fontSize: 13,
                  fontWeight: FontWeight.bold)),
          bottom: const TabBar(
            indicatorColor: Color(0xFFFFB300),
            tabs: [
              Tab(text: "PRESTİJ"),
              Tab(text: "AKADEMİ"),
              Tab(text: "HİZMETLER")
            ],
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: TabBarView(
                children: [
                  _prestijSekmesi(), // 01 & Bio
                  _akademiSekmesi(), // 02 & Müfredat
                  _hizmetlerSekmesi(), // 04 & 05 Danışmanlık ve Rezervasyon
                ],
              ),
            ),
            _altAksiyonlar(),
          ],
        ),
      ),
    );
  }

  Widget _prestijSekmesi() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(25),
      child: Column(
        children: [
          _buildInput(_adController, "ŞEF ADI SOYADI", Icons.badge),
          _buildInput(_uzmanlikController, "MUTFAK EKOLÜ (Örn: Modern Anadolu)",
              Icons.auto_awesome),
          _buildInput(
              _bioController, "ŞEFİN HİKAYESİ (01. MADDE)", Icons.history_edu,
              maxLines: 4),
        ],
      ),
    );
  }

  Widget _akademiSekmesi() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInput(_youtubeController, "AKADEMİ TANITIM VİDEOSU (URL)",
              Icons.play_circle_fill),
          const SizedBox(height: 10),
          const Text("🎓 MÜFREDAT SEÇİMİ (02. MADDE)",
              style: TextStyle(
                  color: Color(0xFFFFB300),
                  fontSize: 10,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),

          // 👨‍🍳 AŞÇILIK EĞİTİMLERİ (GERİ GELDİ)
          _dersGrubu("AŞÇILIK", [
            "Osmanlı Saray Mutfağı",
            "Yöresel Mutfaklar",
            "Dünya Mutfağı",
            "Tabak Dizayn",
            "Hijyen & Sağlık"
          ]),
          const SizedBox(height: 15),

          // 🍰 PASTACILIK EĞİTİMLERİ (GERİ GELDİ)
          _dersGrubu("PASTACILIK", [
            "Çikolata Sanatı",
            "Pasta Teknikleri",
            "Sütlü Tatlılar",
            "Börek Çeşitleri"
          ]),
          const SizedBox(height: 15),

          // 💼 KAFE & İŞLETME (GERİ GELDİ)
          _dersGrubu("İŞLETME",
              ["Maliyet Hesaplama", "Menü & Reçete", "Satış & İş Akışı"]),
        ],
      ),
    );
  }

  // 🧠 DANIŞMANLIK İKONU DÜZELTİLMİŞ HALİ (Hizmetler Sekmesi İçin)
  Widget _hizmetlerSekmesi() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(25),
      child: Column(
        children: [
          _buildInput(_danismanlikController,
              "DANIŞMANLIK DETAYLARI (04. MADDE)", Icons.psychology,
              maxLines: 3), // ✅ Küçük harf 'p' ile düzeldi
          _buildInput(
              _rezervasyonLinkController,
              "ŞEFİN MASASI REZERVASYON URL (05. MADDE)",
              Icons.event_available),
          _buildInput(_saatUcretiController, "SAAT ÜCRETİ (₺)", Icons.payments),
        ],
      ),
    );
  }

  Widget _dersGrubu(String baslik, List<String> dersler) {
    return Wrap(
      spacing: 8,
      children: dersler
          .map((ders) => FilterChip(
                label: Text(ders, style: const TextStyle(fontSize: 10)),
                selected: _secilenDersler.contains(ders),
                onSelected: (v) => setState(() => v
                    ? _secilenDersler.add(ders)
                    : _secilenDersler.remove(ders)),
                selectedColor: const Color(0xFFFFB300),
                backgroundColor: Colors.white10,
              ))
          .toList(),
    );
  }

  Widget _altAksiyonlar() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          OutlinedButton.icon(
            onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => HizliYemekEkle(
                        tip: "Usta Sef", dukkanAdi: _adController.text))),
            icon: const Icon(Icons.add_a_photo, color: Color(0xFFFFB300)),
            label: const Text("İMZA MUTFAĞI FOTOĞRAFLARI (03. MADDE)",
                style: TextStyle(color: Colors.white, fontSize: 10)),
            style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFFFB300)),
                minimumSize: const Size(double.infinity, 50)),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: _isSaving ? null : _arenaYayinla,
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFB300),
                minimumSize: const Size(double.infinity, 55)),
            child: _isSaving
                ? const CircularProgressIndicator(color: Colors.black)
                : const Text("ARENA'DA YAYINLA",
                    style: TextStyle(
                        color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildInput(TextEditingController c, String h, IconData i,
      {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextField(
        controller: c,
        maxLines: maxLines,
        style: const TextStyle(color: Colors.white, fontSize: 13),
        decoration: InputDecoration(
          prefixIcon: Icon(i, color: const Color(0xFFFFB300), size: 18),
          hintText: h,
          hintStyle: const TextStyle(color: Colors.white24, fontSize: 11),
          filled: true,
          fillColor: const Color(0xFF111111),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none),
        ),
      ),
    );
  }
}
