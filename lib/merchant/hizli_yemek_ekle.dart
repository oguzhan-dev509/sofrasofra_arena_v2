import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class HizliYemekEkle extends StatefulWidget {
  final String tip;
  final String dukkanAdi;
  const HizliYemekEkle({super.key, required this.tip, required this.dukkanAdi});

  @override
  State<HizliYemekEkle> createState() => _HizliYemekEkleState();
}

class _HizliYemekEkleState extends State<HizliYemekEkle> {
  // 📸 ALTIN ÇERÇEVELİ FOTOĞRAF MOTORU VERİLERİ
  final List<Uint8List?> _resimBytesList = [null, null, null];
  final ImagePicker _picker = ImagePicker();

  final _adController = TextEditingController();
  final _fiyatController = TextEditingController();
  final _teknikController = TextEditingController();

  bool _isSaving = false;

  // 📷 FOTOĞRAF SEÇME FONKSİYONU
  Future<void> _fotoSec(int index) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );

      if (image != null) {
        final Uint8List bytes = await image.readAsBytes();
        setState(() {
          _resimBytesList[index] = bytes;
        });
      }
    } catch (e) {
      debugPrint("Fotoğraf seçme hatası: $e");
    }
  }

  // 🚀 ARENA'YA MÜHÜRLEME FONKSİYONU
  Future<void> _yayinla() async {
    if (_adController.text.isEmpty) return;
    setState(() => _isSaving = true);

    try {
      await FirebaseFirestore.instance.collection('urunler').add({
        "dukkan": widget.dukkanAdi.toUpperCase(),
        "ad": _adController.text.trim().toUpperCase(),
        "fiyat": double.tryParse(_fiyatController.text) ?? 0.0,
        "teknik": widget.tip == "Usta Sef" ? _teknikController.text : null,
        "tip": widget.tip,
        "onayDurumu": "onaylandi",
        "kayitTarihi": FieldValue.serverTimestamp(),
      });
      if (mounted) Navigator.pop(context);
    } catch (e) {
      debugPrint("Yayınlama Hatası: $e");
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
        title: const Text("YENİ İMZA TABAK EKLE",
            style: TextStyle(
                color: Color(0xFFFFB300),
                fontSize: 12,
                fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25),
        child: Column(
          children: [
            // ✨ ALTIN ÇERÇEVELİ 3'LÜ VİTRİN
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(
                  3,
                  (index) => GestureDetector(
                        onTap: () => _fotoSec(index),
                        child: Container(
                          width: MediaQuery.of(context).size.width * 0.26,
                          height: MediaQuery.of(context).size.width * 0.26,
                          decoration: BoxDecoration(
                            color: const Color(0xFF0D0D0D),
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(
                              color: _resimBytesList[index] != null
                                  ? const Color(0xFFFFB300)
                                  : Colors.white.withOpacity(0.05),
                              width: _resimBytesList[index] != null ? 2 : 1,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(13),
                            child: _resimBytesList[index] != null
                                ? Image.memory(_resimBytesList[index]!,
                                    fit: BoxFit.cover)
                                : const Icon(Icons.add_a_photo_outlined,
                                    color: Color(0xFFFFB300), size: 24),
                          ),
                        ),
                      )),
            ),
            const SizedBox(height: 30),

            _buildInput(
                _adController, "TABAK ADI / ÖRN: KUZU SIRTI", Icons.restaurant),
            _buildInput(_fiyatController, "FİYAT (₺)", Icons.payments),

            if (widget.tip == "Usta Sef")
              _buildInput(
                  _teknikController, "PİŞİRME TEKNİĞİ", Icons.auto_fix_high),

            const SizedBox(height: 40),

            ElevatedButton(
              onPressed: _isSaving ? null : _yayinla,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFB300),
                minimumSize: const Size(double.infinity, 55),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15)),
              ),
              child: _isSaving
                  ? const CircularProgressIndicator(color: Colors.black)
                  : const Text("ARENA'DA YAYINLA",
                      style: TextStyle(
                          color: Colors.black, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInput(TextEditingController c, String h, IconData i) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextField(
        controller: c,
        style: const TextStyle(color: Colors.white, fontSize: 13),
        decoration: InputDecoration(
          prefixIcon: Icon(i, color: const Color(0xFFFFB300), size: 18),
          hintText: h,
          hintStyle: const TextStyle(color: Colors.white24, fontSize: 11),
          filled: true,
          fillColor: const Color(0xFF111111),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none),
        ),
      ),
    );
  }
}
