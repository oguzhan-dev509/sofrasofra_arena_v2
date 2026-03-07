import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class SefYonetimPaneli extends StatefulWidget {
  const SefYonetimPaneli({super.key});

  @override
  State<SefYonetimPaneli> createState() => _SefYonetimPaneliState();
}

class _SefYonetimPaneliState extends State<SefYonetimPaneli> {
  Uint8List? _profilBytes;
  final List<Uint8List?> _vitrinBytesList = List.generate(18, (_) => null);
  final ImagePicker _picker = ImagePicker();
  bool _isSaving = false;

  final _adController = TextEditingController();
  final _uzmanlikController = TextEditingController();
  final _uzmanlikDetayController = TextEditingController(); // Bio yerine bu!
  final _youtubeController = TextEditingController();
  final _danismanlikController = TextEditingController();
  final _rezervasyonController = TextEditingController();

  final List<String> _secilenDersler = [];

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

  Future<String?> _resmiBulutaGonder(Uint8List bytes, String path) async {
    try {
      final ref = FirebaseStorage.instance.ref().child(path);
      final uploadTask = ref.putData(bytes);
      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      return null;
    }
  }

  Future<void> _sefProfiliniMuhurle() async {
    final ad = _adController.text.trim();
    if (ad.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Lütfen Şef Adını giriniz.")));
      return;
    }

    setState(() => _isSaving = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      final uid = user?.uid ?? "anonim_sef";

      String profilUrl = "";
      if (_profilBytes != null) {
        profilUrl =
            await _resmiBulutaGonder(_profilBytes!, "profiller/$uid.jpg") ?? "";
      }

      await FirebaseFirestore.instance.collection('urunler').add({
        "img": profilUrl, // Vitrin burayı okuyor
        "dukkan": ad.toUpperCase(),
        "uzmanlik": _uzmanlikController.text.trim(),
        "uzmanlik_detay":
            _uzmanlikDetayController.text.trim(), // Bio tamamen kovuldu
        "youtube_url": _youtubeController.text.trim(),
        "danismanlik": _danismanlikController.text.trim(),
        "rezervasyon": _rezervasyonController.text.trim(),
        "akadem_mufredat": _secilenDersler,
        "tip": "Usta Sefler",
        "onayDurumu": "onaylandi",
        "isActive": true,
        "dukkanId": uid,
        "kayitTarihi": FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("✅ ŞEF PROFİLİ ARENA'DA MÜHÜRLENDİ!")));
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint("Mühürleme Hatası: $e");
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
        title: const Text("ŞEF YÖNETİM PANELİ",
            style: TextStyle(color: goldColor, fontSize: 13)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25),
        child: Column(
          children: [
            // 📸 GERİ GELEN PROFİL ALANI
            _profilResmiAlani(goldColor),

            const SizedBox(height: 30),
            _buildInput(_adController, "ŞEF ADI SOYADI", Icons.badge),
            _buildInput(
                _uzmanlikController, "UZMANLIK ALANI", Icons.auto_awesome),
            _buildInput(
                _uzmanlikDetayController, "UZMANLIK DETAYI", Icons.history_edu,
                maxLines: 3),
            _buildInput(_youtubeController, "AKADEMİ VİDEO URL",
                Icons.play_circle_fill),

            const SizedBox(height: 20),
            _medyaBolumu(goldColor),

            const SizedBox(height: 40),
            _yayinlaButonu(goldColor),
          ],
        ),
      ),
    );
  }

  // 🛠️ YARDIMCI WIDGETLAR: KAYIP PARÇALAR MONTE EDİLDİ
  Widget _profilResmiAlani(Color gold) {
    return GestureDetector(
      onTap: () => _fotoSec(0, isProfil: true),
      child: Center(
        child: Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: gold, width: 2),
            color: const Color(0xFF111111),
          ),
          child: ClipOval(
            child: _profilBytes != null
                ? Image.memory(_profilBytes!, fit: BoxFit.cover)
                : Icon(Icons.camera_alt, color: gold, size: 40),
          ),
        ),
      ),
    );
  }

  Widget _medyaBolumu(Color gold) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("📸 İMZA TABAKLAR",
            style: TextStyle(color: Colors.white54, fontSize: 10)),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3, crossAxisSpacing: 10, mainAxisSpacing: 10),
          itemCount: 3, // Şimdilik 3 adet gösterelim
          itemBuilder: (context, index) => GestureDetector(
            onTap: () => _fotoSec(index),
            child: Container(
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFF111111),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: _vitrinBytesList[index] != null
                        ? gold
                        : Colors.white10),
              ),
              child: _vitrinBytesList[index] != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.memory(_vitrinBytesList[index]!,
                          fit: BoxFit.cover))
                  : const Icon(Icons.add_photo_alternate,
                      color: Colors.white10),
            ),
          ),
        ),
      ],
    );
  }

  Widget _yayinlaButonu(Color gold) {
    return ElevatedButton(
      onPressed: _isSaving ? null : _sefProfiliniMuhurle,
      style: ElevatedButton.styleFrom(
          backgroundColor: gold,
          minimumSize: const Size(double.infinity, 55),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
      child: _isSaving
          ? const CircularProgressIndicator(color: Colors.black)
          : const Text("ARENA'DA YAYINLA",
              style:
                  TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
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
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none),
        ),
      ),
    );
  }
}
