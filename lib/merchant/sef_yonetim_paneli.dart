import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SefYonetimPaneli extends StatefulWidget {
  const SefYonetimPaneli({super.key});

  @override
  State<SefYonetimPaneli> createState() => _SefYonetimPaneliState();
}

class _SefYonetimPaneliState extends State<SefYonetimPaneli> {
  // --- 📸 VERİ MOTORU ---
  Uint8List? _profilBytes;
  final List<Uint8List?> _vitrinBytesList = List.generate(18, (_) => null);
  final ImagePicker _picker = ImagePicker();
  bool _isSaving = false;

  // --- 📝 KONTROLCÜLER ---
  final _adController = TextEditingController();
  final _uzmanlikController = TextEditingController();
  final _bioController = TextEditingController();
  final _youtubeController = TextEditingController();
  final _danismanlikController = TextEditingController();
  final _rezervasyonController = TextEditingController();
  final _kursDetayController = TextEditingController();

  final List<String> _secilenDersler = [];

  // --- 📷 FOTOĞRAF SEÇME ---
  Future<void> _fotoSec(int index, {bool isProfil = false}) async {
    try {
      final XFile? image = await _picker.pickImage(
          source: ImageSource.gallery, imageQuality: 70);
      if (image != null) {
        final Uint8List bytes = await image.readAsBytes();
        setState(() {
          if (isProfil) {
            _profilBytes = bytes;
          } else {
            _vitrinBytesList[index] = bytes;
          }
        });
      }
    } catch (e) {
      debugPrint("Foto Hatası: $e");
    }
  }

  // --- 🔥 MÜHÜRLEME (FIRESTORE) ---
  Future<void> _sefProfiliniMuhurle() async {
    if (_adController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Lütfen Şef Adını giriniz.")));
      return;
    }
    setState(() => _isSaving = true);
    try {
      await FirebaseFirestore.instance.collection('urunler').add({
        "dukkan": _adController.text.trim().toUpperCase(),
        "uzmanlik": _uzmanlikController.text.trim(),
        "bio": _bioController.text.trim(),
        "youtube_url": _youtubeController.text.trim(),
        "danismanlik": _danismanlikController.text.trim(),
        "rezervasyon": _rezervasyonController.text.trim(),
        "akadem_mufredat": _secilenDersler,
        "kurs_ilani": _kursDetayController.text.trim(),
        "tip": "Usta Sefler",
        "onayDurumu": "onaylandi",
        "kayitTarihi": FieldValue.serverTimestamp(),
      });
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("✅ ŞEF PROFİLİ ARENA'DA MÜHÜRLENDİ!")));
    } catch (e) {
      debugPrint("Mühürleme Hatası: $e");
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // --- 🛠️ YARDIMCI WIDGETLAR ---
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
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color goldColor = Color(0xFFFFB300);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text("USTA ŞEF KOMUTA MERKEZİ",
            style: TextStyle(
                color: goldColor, fontSize: 13, fontWeight: FontWeight.bold)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showDialog(
              context: context,
              builder: (context) => AlertDialog(
                    backgroundColor: const Color(0xFF111111),
                    title: const Text("Kurs İlanı",
                        style: TextStyle(color: goldColor)),
                    content: TextField(
                        controller: _kursDetayController,
                        maxLines: 3,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                            hintText: "Detaylar...",
                            hintStyle: TextStyle(color: Colors.white24))),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text("KAYDET",
                              style: TextStyle(color: goldColor)))
                    ],
                  ));
        },
        backgroundColor: goldColor,
        icon: const Icon(Icons.bolt, color: Colors.black),
        label: const Text("KURS İLANI",
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25),
        child: Column(
          children: [
            // ✨ ŞEF PROFİL İKONU
            GestureDetector(
              onTap: () => _fotoSec(0, isProfil: true),
              child: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: goldColor, width: 2),
                    color: const Color(0xFF111111)),
                child: ClipOval(
                  child: _profilBytes != null
                      ? Image.memory(_profilBytes!, fit: BoxFit.cover)
                      : const Icon(Icons.add_a_photo, color: goldColor),
                ),
              ),
            ),
            const SizedBox(height: 30),
            _buildInput(_adController, "ŞEF ADI SOYADI", Icons.badge),
            _buildInput(
                _uzmanlikController, "UZMANLIK ALANI", Icons.auto_awesome),
            _buildInput(_bioController, "BİYOGRAFİ", Icons.history_edu,
                maxLines: 3),
            _buildInput(_youtubeController, "AKADEMİ VİDEO URL",
                Icons.play_circle_fill),

            const SizedBox(height: 20),
            const Text("🎓 AKADEMİ MÜFREDAI",
                style: TextStyle(
                    color: goldColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold)),
            Wrap(
              spacing: 8,
              children: ["Osmanlı", "Tabak Tasarım", "Dünya Mutf.", "Maliyet"]
                  .map((e) => FilterChip(
                        label: Text(e, style: const TextStyle(fontSize: 10)),
                        selected: _secilenDersler.contains(e),
                        onSelected: (v) => setState(() => v
                            ? _secilenDersler.add(e)
                            : _secilenDersler.remove(e)),
                      ))
                  .toList(),
            ),

            const SizedBox(height: 30),
            _buildInput(
                _danismanlikController, "DANIŞMANLIK", Icons.psychology),
            _buildInput(_rezervasyonController, "WHATSAPP / REZERVASYON",
                Icons.event_available),

            const SizedBox(height: 20),
            const Divider(color: Colors.white10),
            const Text("📸 İMZA TABAKLAR (18 ADET)",
                style: TextStyle(color: goldColor, fontSize: 11)),
            const SizedBox(height: 15),

            // 📸 18'Lİ VİTRİN
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3, crossAxisSpacing: 10, mainAxisSpacing: 10),
              itemCount: 18,
              itemBuilder: (context, index) => GestureDetector(
                onTap: () => _fotoSec(index),
                child: Container(
                  decoration: BoxDecoration(
                      color: const Color(0xFF0D0D0D),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: _vitrinBytesList[index] != null
                              ? goldColor
                              : Colors.white10)),
                  child: _vitrinBytesList[index] != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.memory(_vitrinBytesList[index]!,
                              fit: BoxFit.cover))
                      : const Icon(Icons.add_a_photo,
                          color: Colors.white10, size: 20),
                ),
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _isSaving ? null : _sefProfiliniMuhurle,
              style: ElevatedButton.styleFrom(
                  backgroundColor: goldColor,
                  minimumSize: const Size(double.infinity, 55),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15))),
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
}
