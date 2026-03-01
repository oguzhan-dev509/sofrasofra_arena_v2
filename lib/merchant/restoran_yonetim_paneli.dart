import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RestoranYonetimPaneli extends StatefulWidget {
  const RestoranYonetimPaneli({super.key});

  @override
  State<RestoranYonetimPaneli> createState() => _RestoranYonetimPaneliState();
}

class _RestoranYonetimPaneliState extends State<RestoranYonetimPaneli> {
  // 📝 KONTROLCÜLER (Visual & Data Logic)
  final _dukkanAdController = TextEditingController();
  final _urunAdController = TextEditingController();
  final _fiyatController = TextEditingController();
  final _stokController = TextEditingController();
  final _gorselUrlController = TextEditingController();

  String _secilenKategori = 'Ana Yemek';
  bool _isSaving = false;

  Future<void> _urunEkle() async {
    if (_dukkanAdController.text.isEmpty || _urunAdController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("⚠️ LÜTFEN DÜKKAN VE ÜRÜN ADINI BOŞ BIRAKMAYIN!")),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      await FirebaseFirestore.instance.collection('urunler').add({
        "dukkan": _dukkanAdController.text.trim().toUpperCase(),
        "ad": _urunAdController.text.trim().toUpperCase(),
        "fiyat": double.tryParse(_fiyatController.text) ?? 0.0,
        "stok": int.tryParse(_stokController.text) ?? 0,
        "kategori": _secilenKategori,
        "img": _gorselUrlController.text.trim().isEmpty
            ? "https://images.unsplash.com/photo-1546069901-ba9599a7e63c"
            : _gorselUrlController.text.trim(),
        "tip": "Restoran",
        "eklenmeTarihi": FieldValue.serverTimestamp(),
      });

      if (mounted) {
        _urunAdController.clear();
        _fiyatController.clear();
        _stokController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("✅ ÜRÜN ARENA'YA MÜHÜRLENDİ!")));
      }
    } catch (e) {
      debugPrint("Hata: $e");
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
        title: const Text("RESTORAN YÖNETİMİ",
            style: TextStyle(
                color: Color(0xFFFFB300),
                fontSize: 13,
                fontWeight: FontWeight.bold,
                letterSpacing: 1)),
        iconTheme: const IconThemeData(color: Color(0xFFFFB300)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25),
        child: Column(
          children: [
            // 🏢 DÜKKAN İSMİ (SILICON VALLEY STANDARD)
            _buildInput(
                _dukkanAdController, "DÜKKAN İSMİ", Icons.store_mall_directory),
            const SizedBox(height: 10),

            // 🍴 ÜRÜN BİLGİLERİ
            _buildInput(_urunAdController, "ÜRÜN ADI", Icons.restaurant_menu),
            Row(
              children: [
                Expanded(
                    child: _buildInput(
                        _fiyatController, "FİYAT (₺)", Icons.payments)),
                const SizedBox(width: 10),
                Expanded(
                    child: _buildInput(
                        _stokController, "STOK ADEDİ", Icons.inventory_2)),
              ],
            ),
            _buildInput(_gorselUrlController, "GÖRSEL URL (MENÜ FOTOĞRAFI)",
                Icons.image),

            const SizedBox(height: 20),

            // 🔘 KATEGORİ SEÇİCİ (GÖRSELDEKİ GİBİ ŞIK)
            _buildKategoriSecici(),

            const SizedBox(height: 40),

            // 🔥 MÜHÜRLEME BUTONU
            ElevatedButton(
              onPressed: _isSaving ? null : _urunEkle,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFB300),
                minimumSize: const Size(double.infinity, 60),
                shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(30)), // Daha yuvarlak ve modern
                elevation: 5,
              ),
              child: _isSaving
                  ? const CircularProgressIndicator(color: Colors.black)
                  : const Text("MENÜYE EKLE",
                      style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 15)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKategoriSecici() {
    List<String> kategoriler = ['Ana Yemek', 'Aparatif', 'İçecek', 'Tatlı'];
    return Wrap(
      spacing: 12,
      runSpacing: 10,
      alignment: WrapAlignment.center,
      children: kategoriler
          .map((k) => ChoiceChip(
                label: Text(k, style: const TextStyle(fontSize: 11)),
                selected: _secilenKategori == k,
                onSelected: (val) => setState(() => _secilenKategori = k),
                selectedColor: const Color(0xFFFFB300),
                backgroundColor: const Color(0xFF1A1A1A),
                labelStyle: TextStyle(
                    color:
                        _secilenKategori == k ? Colors.black : Colors.white70),
                padding:
                    const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ))
          .toList(),
    );
  }

  Widget _buildInput(TextEditingController c, String h, IconData i) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextField(
        controller: c,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          prefixIcon: Icon(i, color: const Color(0xFFFFB300), size: 20),
          hintText: h,
          hintStyle: const TextStyle(color: Colors.white24, fontSize: 12),
          filled: true,
          fillColor: const Color(0xFF111111),
          contentPadding: const EdgeInsets.symmetric(vertical: 18),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.05))),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(color: Color(0xFFFFB300))),
        ),
      ),
    );
  }
}
