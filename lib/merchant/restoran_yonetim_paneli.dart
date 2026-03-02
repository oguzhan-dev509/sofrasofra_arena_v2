import 'dart:typed_data'; // ✅ Web/Masaüstü için bytes desteği
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // ✅ Firestore bağlantısı
import 'package:flutter/foundation.dart' show kIsWeb; // ✅ Web kontrolü

class RestoranYonetimPaneli extends StatefulWidget {
  const RestoranYonetimPaneli({super.key});

  @override
  State<RestoranYonetimPaneli> createState() => _RestoranYonetimPaneliState();
}

class _RestoranYonetimPaneliState extends State<RestoranYonetimPaneli> {
  // 📸 Profil ve Vitrin Fotoğrafları (Bytes)
  Uint8List? _profilBytes; // ✨ 00. Madde: Profil İkonu
  final List<Uint8List?> _vitrinBytesList = List.generate(18, (_) => null);

  final ImagePicker _picker = ImagePicker();
  bool _isSaving = false;

  // 📝 Kontrolcüler
  final _restoranAdiController = TextEditingController();
  final _bioController = TextEditingController();
  final _fiyatController = TextEditingController();
  final _teknikController = TextEditingController();

  // 📷 PROFİL FOTOĞRAFI SEÇME (Instagram Stili)
  Future<void> _profilSec() async {
    try {
      final XFile? image = await _picker.pickImage(
          source: ImageSource.gallery, imageQuality: 50);
      if (image != null) {
        final Uint8List bytes = await image.readAsBytes();
        setState(() => _profilBytes = bytes);
      }
    } catch (e) {
      debugPrint("Profil seçme hatası: $e");
    }
  }

  // 📷 VİTRİN FOTOĞRAFI SEÇME (Web/Masaüstü Uyumlu)
  Future<void> _fotoSec(int index) async {
    try {
      final XFile? image = await _picker.pickImage(
          source: ImageSource.gallery, imageQuality: 70);
      if (image != null) {
        final Uint8List bytes = await image.readAsBytes();
        setState(() => _vitrinBytesList[index] = bytes);
      }
    } catch (e) {
      debugPrint("Fotoğraf seçme hatası: $e");
    }
  }

  // ❌ FOTOĞRAF SİLME (Tek Tek)
  void _fotoSil(int index) {
    setState(() => _vitrinBytesList[index] = null);
  }

  // 🚀 FÜZE ATEŞLEME: ARENA'DA YAYINLA (Firestore Mühürleme)
  Future<void> _yayinla() async {
    if (_restoranAdiController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Lütfen Restoran Adını girin.")));
      return;
    }

    setState(() => _isSaving = true);

    try {
      // 📝 Not: Fotoğraf URL'ye çevirme işlemi (Storage) buraya eklenecek.
      // Şu an sadece metin verilerini mühürlüyoruz.

      await FirebaseFirestore.instance.collection('urunler').add({
        "dukkan": _restoranAdiController.text.trim().toUpperCase(),
        "tarif": _bioController.text.trim(),
        "fiyat": double.tryParse(_fiyatController.text) ?? 0.0,
        "teknik": _teknikController.text.trim(),
        "tip": "Restoran",
        "onayDurumu": "onaylandi", // ✅ Direkt onaylı gidiyor
        "isActive": true,
        "kayitTarihi": FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("✅ VİTRİN ARENA'DA CANLI!")));
      }
    } catch (e) {
      debugPrint("Yayınlama hatası: $e");
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color goldColor = Color(0xFFFFB300);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text("RESTORAN VİTRİN YÖNETİMİ",
            style: TextStyle(
                color: goldColor, fontSize: 13, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: goldColor),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ✨ INSTAGRAM STİLİ PROFİL İKONU VE BAŞLIK (En Üstte)
            Row(
              children: [
                GestureDetector(
                  onTap: _profilSec,
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: goldColor, width: 2),
                      color: const Color(0xFF111111),
                    ),
                    child: ClipOval(
                      child: _profilBytes != null
                          ? Image.memory(_profilBytes!, fit: BoxFit.cover)
                          : const Icon(Icons.person_add_alt_1_outlined,
                              color: goldColor, size: 25),
                    ),
                  ),
                ),
                const SizedBox(width: 15),
                const Expanded(
                  child: Text("👨‍🍳 RESTORAN KİMLİĞİ",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w900)),
                ),
              ],
            ),
            const SizedBox(height: 30),

            // 📝 1. BÖLÜM: BİLGİLER VE LİSTELER
            _buildInput(_restoranAdiController, "RESTORAN ADI / ŞEFİN ADI",
                Icons.restaurant),
            _buildInput(_bioController,
                "YEMEK AKI / ŞEFİN HİKAYESİ (01. MADDE)", Icons.history_edu,
                maxLines: 3),
            Row(
              children: [
                Expanded(
                    child: _buildInput(_fiyatController, "ORTALAMA FİYAT (₺)",
                        Icons.payments)),
                const SizedBox(width: 15),
                Expanded(
                    child: _buildInput(_teknikController, "MUTFAK TARZI",
                        Icons.auto_fix_high)),
              ],
            ),

            const SizedBox(height: 20),
            const Text("🎓 AKADEMİ MÜFREDATI",
                style: TextStyle(
                    color: goldColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                "Osmanlı Mutf.",
                "Yöresel Mutf.",
                "Dünya Mutf.",
                "Çikolata San.",
                "Pasta Tekn.",
                "Sütlü Tatlı."
              ].map((e) => _buildChip(e)).toList(),
            ),

            const SizedBox(height: 40),
            const Divider(color: Colors.white10),
            const SizedBox(height: 20),

            // ✨ 2. BÖLÜM: 18'Lİ ALTIN VİTRİN (ALTTA)
            const Text("📸 RESTORAN VİTRİNİ (18 FOTOĞRAF)",
                style: TextStyle(
                    color: goldColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: 18,
              itemBuilder: (context, index) => Stack(
                children: [
                  GestureDetector(
                    onTap: () => _fotoSec(index),
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D0D0D),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _vitrinBytesList[index] != null
                              ? goldColor
                              : Colors.white.withOpacity(0.05),
                          width: _vitrinBytesList[index] != null ? 1.5 : 1,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: _vitrinBytesList[index] != null
                            ? Image.memory(_vitrinBytesList[index]!,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity)
                            : const Icon(Icons.add_a_photo_outlined,
                                color: goldColor, size: 20),
                      ),
                    ),
                  ),
                  if (_vitrinBytesList[index] != null)
                    Positioned(
                      top: 5,
                      right: 5,
                      child: GestureDetector(
                        onTap: () => _fotoSil(index),
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(
                              color: Colors.redAccent, shape: BoxShape.circle),
                          child: const Icon(Icons.close,
                              color: Colors.white, size: 10),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 50),

            // 🚀 AKTİF YAYINLAMA BUTONU
            ElevatedButton(
              onPressed: _isSaving ? null : _yayinla, // ✅ Canlandırıldı
              style: ElevatedButton.styleFrom(
                  backgroundColor: goldColor,
                  minimumSize: const Size(double.infinity, 55),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15))),
              child: _isSaving
                  ? const CircularProgressIndicator(color: Colors.black)
                  : const Text("VİTRİNİ ARENA'DA YAYINLA",
                      style: TextStyle(
                          color: Colors.black, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(String label) => FilterChip(
      label: Text(label,
          style: const TextStyle(fontSize: 10, color: Colors.white70)),
      onSelected: (v) {},
      backgroundColor: Colors.white10);

  Widget _buildInput(TextEditingController c, String h, IconData i,
          {int maxLines = 1}) =>
      Padding(
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
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none),
          ),
        ),
      );
}
