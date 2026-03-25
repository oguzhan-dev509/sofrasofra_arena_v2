import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class UstaSefGorselYonetimi extends StatefulWidget {
  final String chefId;
  const UstaSefGorselYonetimi({super.key, required this.chefId});

  @override
  State<UstaSefGorselYonetimi> createState() => _UstaSefGorselYonetimiState();
}

class _UstaSefGorselYonetimiState extends State<UstaSefGorselYonetimi> {
  // Arena Altın ve Siyah Teması
  static const Color gold = Color(0xFFFFB300);
  static const Color cardBg = Color(0xFF171717);

  final ImagePicker _picker = ImagePicker();
  Uint8List? _localBytes;
  String _profileUrl = '';
  bool _isBusy = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // Veritabanından veriyi sessizce çekiyoruz (Ekranı kilitlemeden)
  Future<void> _loadData() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('chefs')
          .doc(widget.chefId)
          .get();
      if (doc.exists) {
        final data = doc.data();
        if (mounted) {
          setState(() {
            _profileUrl =
                (data?['media']?['profileImage'] ?? '').toString().trim();
          });
        }
      }
    } catch (e) {
      debugPrint("Sessiz Veri Hatası: $e");
    }
  }

  // Fotoğraf Seçme ve Yükleme (Videodaki Restoran Mantığı)
  Future<void> _pickAndUpload() async {
    if (_isBusy) return;
    final XFile? image =
        await _picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
    if (image == null) return;

    final bytes = await image.readAsBytes();
    setState(() {
      _isBusy = true;
      _localBytes = bytes;
    });

    try {
      final ref = FirebaseStorage.instance.ref().child(
          'chefs/${widget.chefId}/profile_${DateTime.now().msSinceEpoch}.jpg');
      await ref.putData(bytes);
      final url = await ref.getDownloadURL();

      await FirebaseFirestore.instance
          .collection('chefs')
          .doc(widget.chefId)
          .update({
        'media.profileImage': url,
      });

      if (mounted) setState(() => _profileUrl = url);
    } catch (e) {
      debugPrint("Yükleme Hatası: $e");
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Fotoğraf kontrolü (Eğer her ikisi de boşsa kamera simgesi gelecek)
    final bool hasImage = _profileUrl.isNotEmpty || _localBytes != null;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text('GÖRSEL PANELİ',
            style: TextStyle(
                color: gold, fontSize: 14, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: gold),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // --- ANA GÖRSEL ALANI (ENGEL TANIMAZ) ---
              GestureDetector(
                onTap: _pickAndUpload,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: gold.withOpacity(0.3), width: 2),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: hasImage
                        ? (_localBytes != null
                            ? Image.memory(_localBytes!, fit: BoxFit.cover)
                            : Image.network(_profileUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(
                                    Icons.add_a_photo,
                                    color: gold,
                                    size: 60)))
                        : const Icon(Icons.add_a_photo,
                            color: gold,
                            size: 60), // GİZLİ ENGEL BURADA KIRILIYOR
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // --- BİLGİ VE AKSİYON ---
              Text(
                hasImage ? "FOTOĞRAFI DEĞİŞTİR" : "FOTOĞRAF EKLE",
                style: const TextStyle(
                    color: gold, fontSize: 12, letterSpacing: 1.5),
              ),
              const SizedBox(height: 40),

              if (_isBusy)
                const CircularProgressIndicator(color: gold)
              else
                Text("Chef ID: ${widget.chefId}",
                    style:
                        const TextStyle(color: Colors.white24, fontSize: 10)),
            ],
          ),
        ),
      ),
    );
  }
}
