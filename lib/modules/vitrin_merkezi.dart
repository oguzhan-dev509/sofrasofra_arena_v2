import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:typed_data';

class VitrinMerkezi extends StatefulWidget {
  const VitrinMerkezi({super.key});

  @override
  State<VitrinMerkezi> createState() => _VitrinMerkeziState();
}

class _VitrinMerkeziState extends State<VitrinMerkezi> {
  final List<Uint8List?> _vitrinResimler = List.generate(18, (index) => null);
  Uint8List? _profilResmi;

  String _sefAdi = "Şef Arda Türkmen";
  String _imzaYemek = "TRÜF MANTARLI RİZOTTO";
  String _youtubeLink = "https://www.youtube.com";
  String _tarifMetni = "";

  // 📸 Fotoğraf İşlemi
  Future<void> _fotoIslem(int index, {bool profil = false}) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        final Uint8List bytes = await image.readAsBytes();
        setState(() {
          if (profil) {
            _profilResmi = bytes;
          } else {
            _vitrinResimler[index] = bytes;
          }
        });
      }
    } catch (e) {
      debugPrint("Fotoğraf seçme hatası: $e");
    }
  }

  // 🗑️ Silme
  void _fotoSil(int index) {
    setState(() => _vitrinResimler[index] = null);
  }

  // 📺 Video Açma (Mühürlü ve Hatasız)
  Future<void> _videoAc() async {
    final Uri url = Uri.parse(_youtubeLink);
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        throw Exception('Açamadık Kaptan: $url');
      }
    } catch (e) {
      debugPrint("YouTube Hatası: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFFFFB300)),
        title: const Text("ŞEFİN VİTRİNİ",
            style: TextStyle(
                color: Color(0xFFFFB300),
                fontWeight: FontWeight.bold,
                letterSpacing: 2)),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildSefHeader(),
            const SizedBox(height: 20),
            _buildActionButtons(),
            const SizedBox(height: 30),
            _buildGallerySection(),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  Widget _buildSefHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _fotoIslem(0, profil: true),
            child: CircleAvatar(
              radius: 45,
              backgroundColor: const Color(0xFFFFB300),
              child: CircleAvatar(
                radius: 42,
                backgroundColor: Colors.black,
                backgroundImage:
                    _profilResmi != null ? MemoryImage(_profilResmi!) : null,
                child: _profilResmi == null
                    ? const Icon(Icons.add_a_photo,
                        color: Colors.white, size: 30)
                    : null,
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_sefAdi,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold)),
                Text(_imzaYemek,
                    style: const TextStyle(
                        color: Color(0xFFFFB300),
                        fontSize: 14,
                        letterSpacing: 1)),
                const Text("⭐⭐⭐⭐⭐ (4.9)",
                    style: TextStyle(color: Colors.white54, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _miniButton(Icons.play_circle, "VİDEO AÇ", Colors.red, _videoAc),
        _miniButton(Icons.edit_note, "LİNK EKLE", Colors.orange, _linkGuncelle),
        _miniButton(
            Icons.menu_book, "TARİFİ YAZ", Colors.blueAccent, _tarifGuncelle),
        _miniButton(Icons.share, "PAYLAŞ", Colors.greenAccent, () {}),
      ],
    );
  }

  Widget _miniButton(
      IconData ikon, String etiket, Color renk, VoidCallback fonks) {
    return InkWell(
      onTap: fonks,
      child: Column(children: [
        Icon(ikon, color: renk, size: 32),
        Text(etiket, style: const TextStyle(color: Colors.white, fontSize: 10))
      ]),
    );
  }

  Widget _buildGallerySection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3, crossAxisSpacing: 10, mainAxisSpacing: 10),
        itemCount: 18,
        itemBuilder: (context, index) {
          return Stack(
            children: [
              GestureDetector(
                onTap: () => _fotoIslem(index),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(15),
                    image: _vitrinResimler[index] != null
                        ? DecorationImage(
                            image: MemoryImage(_vitrinResimler[index]!),
                            fit: BoxFit.cover)
                        : null,
                  ),
                  child: _vitrinResimler[index] == null
                      ? const Center(
                          child: Icon(Icons.camera_alt,
                              color: Colors.white24, size: 24))
                      : null,
                ),
              ),
              if (_vitrinResimler[index] != null)
                Positioned(
                  top: 5,
                  right: 5,
                  child: GestureDetector(
                    onTap: () => _fotoSil(index),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                          color: Colors.black54, shape: BoxShape.circle),
                      child: const Icon(Icons.delete_forever,
                          color: Colors.red, size: 18),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  void _linkGuncelle() {
    TextEditingController controller =
        TextEditingController(text: _youtubeLink);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text("Video Linki",
            style: TextStyle(color: Color(0xFFFFB300))),
        content: TextField(
            controller: controller,
            style: const TextStyle(color: Colors.white)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("İptal")),
          ElevatedButton(
              onPressed: () {
                setState(() => _youtubeLink = controller.text);
                Navigator.pop(context);
              },
              child: const Text("Kaydet")),
        ],
      ),
    );
  }

  void _tarifGuncelle() {
    TextEditingController controller = TextEditingController(text: _tarifMetni);
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
              backgroundColor: const Color(0xFF1A1A1A),
              title: const Text("Tarifi Düzenle",
                  style: TextStyle(color: Color(0xFFFFB300))),
              content: TextField(
                  controller: controller,
                  maxLines: 8,
                  style: const TextStyle(color: Colors.white)),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("İptal")),
                ElevatedButton(
                    onPressed: () {
                      setState(() => _tarifMetni = controller.text);
                      Navigator.pop(context);
                    },
                    child: const Text("Mühürle")),
              ],
            ));
  }
}
