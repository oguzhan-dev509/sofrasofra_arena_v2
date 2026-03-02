import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class SefYonetimPaneli extends StatefulWidget {
  const SefYonetimPaneli({super.key});

  @override
  State<SefYonetimPaneli> createState() => _SefYonetimPaneliState();
}

class _SefYonetimPaneliState extends State<SefYonetimPaneli> {
  // 📸 Veri Motoru
  Uint8List? _profilBytes;
  final List<Uint8List?> _vitrinBytesList = List.generate(18, (_) => null);
  final ImagePicker _picker = ImagePicker();
  bool _isSaving = false;

  // 📝 Kontrolcüler
  final _adController = TextEditingController();
  final _uzmanlikController = TextEditingController();
  final _bioController = TextEditingController();
  final _youtubeController = TextEditingController();
  final _danismanlikController = TextEditingController();
  final _rezervasyonController = TextEditingController();
  final _kursDetayController = TextEditingController();

  List<String> _secilenDersler = [];

  // 📷 FOTO SEÇME (WEB UYUMLU)
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
      debugPrint("Foto hatası: $e");
    }
  }

  // 🚀 MÜHÜRLEME FONKSİYONU
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
        "akadem_mufredat": _secilenDersler,
        "youtube_url": _youtubeController.text.trim(),
        "kurs_ilani": _kursDetayController.text.trim(),
        "bio": _bioController.text.trim(),
        "tip": "Usta Sefler",
        "onayDurumu": "onaylandi",
        "kayitTarihi": FieldValue.serverTimestamp(),
      });
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("✅ ŞEF AKADEMİSİ VE VİTRİN MÜHÜRLENDİ!")));
    } catch (e) {
      debugPrint("Hata: $e");
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
        title: const Text("USTA ŞEF KOMUTA MERKEZİ",
            style: TextStyle(
                color: goldColor, fontSize: 13, fontWeight: FontWeight.bold)),
      ),
      // 🎓 ASILI BUTON: KURS İLANI
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _kursIlanDialog(),
        backgroundColor: goldColor,
        icon: const Icon(Icons.bolt, color: Colors.black),
        label: const Text("HIZLI KURS İLANI VER",
            style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 11)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ✨ ŞEF PROFİL İKONU (Instagram Stili)
            Center(
              child: GestureDetector(
                onTap: () => _fotoSec(0, isProfil: true),
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: goldColor, width: 2),
                      color: const Color(0xFF111111)),
                  child: ClipOval(
                    child: _profilBytes != null
                        ? Image.memory(_profilBytes!, fit: BoxFit.cover)
                        : const Icon(Icons.add_a_photo,
                            color: goldColor, size: 30),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),

            _buildInput(_adController, "ŞEF ADI SOYADI", Icons.badge),
            _buildInput(
                _uzmanlikController, "UZMANLIK ALANI", Icons.auto_awesome),
            _buildInput(
                _bioController, "BİYOGRAFİ / HİKAYENİZ", Icons.history_edu,
                maxLines: 3),

            // 🎥 VİDEO URL VE YAYINLAMA İKONU
            _buildInput(
              _youtubeController,
              "AKADEMİ VİDEO URL",
              Icons.play_circle_fill,
              suffix: IconButton(
                  icon: const Icon(Icons.send_rounded, color: goldColor),
                  onPressed: () =>
                      launchUrl(Uri.parse(_youtubeController.text))),
            ),

            const SizedBox(height: 20),
            const Text("🎓 AKADEMİ MÜFREDATI (TAM LİSTE)",
                style: TextStyle(
                    color: goldColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            _mufredatWidget(),

            const SizedBox(height: 30),
            _buildInput(_danismanlikController, "DANIŞMANLIK DETAYLARI",
                Icons.psychology,
                maxLines: 2),
            _buildInput(_rezervasyonController, "REZERVASYON/WHATSAPP LİNK",
                Icons.event_available),

            const SizedBox(height: 40),
            const Divider(color: Colors.white10),
            const Text("📸 İMZA TABAKLAR VİTRİNİ (18 ADET)",
                style: TextStyle(
                    color: goldColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),

            // 📸 18'Lİ VİTRİN GRİD
            _vitrinGrid(goldColor),

            const SizedBox(height: 50),

            // 🚀 MÜHÜRLEME BUTONU
            ElevatedButton(
              onPressed: _isSaving ? null : _sefProfiliniMuhurle,
              style: ElevatedButton.styleFrom(
                  backgroundColor: goldColor,
                  minimumSize: const Size(double.infinity, 55),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15))),
              child: _isSaving
                  ? const CircularProgressIndicator(color: Colors.black)
                  : const Text("ŞEF PROFİLİNİ MÜHÜRLE",
                      style: TextStyle(
                          color: Colors.black, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  // 📝 KURS İLANI PENCERESİ
  void _kursIlanDialog() {
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
              backgroundColor: const Color(0xFF111111),
              title: const Text("Kurs İlanı Ver",
                  style: TextStyle(color: Color(0xFFFFB300), fontSize: 14)),
              content: TextField(
                  controller: _kursDetayController,
                  maxLines: 5,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                  decoration: const InputDecoration(
                      hintText: "Detayları yazın...",
                      hintStyle: TextStyle(color: Colors.white24))),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("KAYDET",
                        style: TextStyle(color: Color(0xFFFFB300))))
              ],
            ));
  }

  // 🎓 MÜFREDAT LİSTESİ
  Widget _mufredatWidget() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        "Osmanlı Mutf.",
        "Tabak Tasarım",
        "Maliyet Hes.",
        "Çikolata San.",
        "Dünya Mutf.",
        "Hijyen Eğit.",
        "Yöresel Tatlar",
        "Pastacılık Tekn.",
        "Sos Teknikleri",
        "Et Pişirme"
      ]
          .map((e) => FilterChip(
                label: Text(e,
                    style: const TextStyle(fontSize: 9, color: Colors.white70)),
                selected: _secilenDersler.contains(e),
                onSelected: (v) => setState(() =>
                    v ? _secilenDersler.add(e) : _secilenDersler.remove(e)),
                backgroundColor: Colors.white10,
                selectedColor: const Color(0xFFFFB300).withOpacity(0.3),
              ))
          .toList(),
    );
  }

  // 🖼️ VİTRİN GRİD
  Widget _vitrinGrid(Color goldColor) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3, crossAxisSpacing: 10, mainAxisSpacing: 10),
      itemCount: 18,
      itemBuilder: (context, index) => Stack(children: [
        GestureDetector(
          onTap: () => _fotoSec(index),
          child: Container(
            decoration: BoxDecoration(
                color: const Color(0xFF0D0D0D),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: _vitrinBytesList[index] != null
                        ? goldColor
                        : Colors.white.withOpacity(0.05))),
            child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: _vitrinBytesList[index] != null
                    ? Image.memory(_vitrinBytesList[index]!, fit: BoxFit.cover)
                    : const Icon(Icons.add_a_photo_outlined,
                        color: Color(0xFFFFB300), size: 20)),
          ),
        ),
        if (_vitrinBytesList[index] != null)
          Positioned(
              top: 4,
              right: 4,
              child: GestureDetector(
                  onTap: () => setState(() => _vitrinBytesList[index] = null),
                  child: const CircleAvatar(
                      radius: 8,
                      backgroundColor: Colors.redAccent,
                      child:
                          Icon(Icons.close, size: 10, color: Colors.white)))),
      ]),
    );
  }

  Widget _buildInput(TextEditingController c, String h, IconData i,
      {int maxLines = 1, Widget? suffix}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextField(
        controller: c,
        maxLines: maxLines,
        style: const TextStyle(color: Colors.white, fontSize: 13),
        decoration: InputDecoration(
            prefixIcon: Icon(i, color: const Color(0xFFFFB300), size: 18),
            suffixIcon: suffix,
            hintText: h,
            hintStyle: const TextStyle(color: Colors.white24, fontSize: 11),
            filled: true,
            fillColor: const Color(0xFF111111),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none)),
      ),
    );
  }
}
