import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class UrunEklemeSayfasi extends StatefulWidget {
  const UrunEklemeSayfasi({super.key});

  @override
  State<UrunEklemeSayfasi> createState() => _UrunEklemeSayfasiState();
}

class _UrunEklemeSayfasiState extends State<UrunEklemeSayfasi> {
  // Form
  final TextEditingController _sefAdiController = TextEditingController();
  final TextEditingController _uzmanlikController = TextEditingController();
  final TextEditingController _videoController = TextEditingController();
  final TextEditingController _resimUrlController = TextEditingController();

  // Görsel
  Uint8List? _webResimVerisi; // galeriden seçilen resim bytes (web için)
  String? _seciliUrl; // kullanıcı elle URL yapıştırdıysa buraya alınır

  bool _yukleniyor = false;

  static const String tipValue = "Usta Sefler";
  static const Color gold = Color(0xFFFFB300);

  @override
  void dispose() {
    _sefAdiController.dispose();
    _uzmanlikController.dispose();
    _videoController.dispose();
    _resimUrlController.dispose();
    super.dispose();
  }

  bool _isHttpUrl(String s) {
    final t = s.trim();
    return t.startsWith("http://") || t.startsWith("https://");
  }

  // 📸 Foto seç (Web uyumlu)
  Future<void> _dosyaGezgininiAc() async {
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );

      if (image == null) return;

      final bytes = await image.readAsBytes();

      setState(() {
        _webResimVerisi = bytes;
        _seciliUrl = null; // URL varsa temizle
        _resimUrlController.clear();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Fotoğraf seçildi.")),
        );
      }
    } catch (e) {
      debugPrint("Foto seçim hatası: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ Foto seçim hatası: $e")),
        );
      }
    }
  }

  // 🔗 URL ekle
  void _urlEkle() {
    final url = _resimUrlController.text.trim();

    if (!_isHttpUrl(url)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("❌ Geçerli bir http/https resim linki gir.")),
      );
      return;
    }

    setState(() {
      _seciliUrl = url;
      _webResimVerisi = null; // bytes varsa temizle
    });

    _resimUrlController.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("✅ Resim linki eklendi.")),
    );
  }

  // ☁️ Storage'a yükle (bytes -> downloadURL)
  Future<String> _bulutaYukle(String uid, Uint8List bytes) async {
    final dosyaAdi = "sef_${DateTime.now().millisecondsSinceEpoch}.jpg";
    final ref = FirebaseStorage.instance
        .ref()
        .child("sef_resimleri")
        .child(uid)
        .child(dosyaAdi);

    final task = ref.putData(
      bytes,
      SettableMetadata(contentType: "image/jpeg"),
    );
    final snap = await task;
    return await snap.ref.getDownloadURL();
  }

  // ✅ ARENA'DA YAYINLA
  Future<void> _arenadaYayinla() async {
    final sefAdi = _sefAdiController.text.trim();
    final uzmanlik = _uzmanlikController.text.trim();
    final videoUrl = _videoController.text.trim();

    // 1) Şef adı zorunlu
    if (sefAdi.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ Şef adı zorunludur!")),
      );
      return;
    }

    // 2) FOTO ZORUNLU ✅
    final bool fotoVar = (_webResimVerisi != null) ||
        (_seciliUrl != null && _seciliUrl!.isNotEmpty);
    if (!fotoVar) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("❌ Foto eklemeden Arena’da yayınlayamazsın.")),
      );
      return;
    }

    setState(() => _yukleniyor = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception("Oturum bulunamadı (Anon login çalışmıyor olabilir).");
      }
      final uid = user.uid;

      // 3) img belirle (önce bytes -> storage, yoksa url)
      String imgUrl;
      if (_webResimVerisi != null) {
        imgUrl = await _bulutaYukle(uid, _webResimVerisi!);
      } else {
        imgUrl = _seciliUrl!.trim();
      }

      // 4) img garanti: http/https olmalı
      if (!_isHttpUrl(imgUrl) || imgUrl.length < 10) {
        throw Exception("img URL hatalı üretildi. (img boş olamaz)");
      }

      // 5) Firestore yaz (bio kesinlikle yok)
      await FirebaseFirestore.instance.collection('urunler').add({
        "img": imgUrl, // ✅ kritik
        "dukkan": sefAdi.toUpperCase(), // kart başlığı
        "uzmanlik": uzmanlik,
        "videoUrl": videoUrl,

        "dukkanId": uid,

        "tip": tipValue, // ✅ kritik
        "kategori": "USTA ŞEFLER",

        "onayDurumu": "onaylandi",
        "isActive": true,

        "kayitTarihi": FieldValue.serverTimestamp(),
        "createdAt": FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Şef profili Arena’da mühürlendi!")),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Hata: $e")),
      );
    } finally {
      if (mounted) setState(() => _yukleniyor = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool fotoSecildi = _webResimVerisi != null ||
        (_seciliUrl != null && _seciliUrl!.isNotEmpty);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          "ŞEF YÖNETİM MERKEZİ",
          style: TextStyle(color: gold, fontSize: 13),
        ),
        iconTheme: const IconThemeData(color: gold),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _input("ŞEF ADI", _sefAdiController),
            const SizedBox(height: 12),
            _input("UZMANLIK", _uzmanlikController),
            const SizedBox(height: 12),
            _input("YOUTUBE (opsiyonel)", _videoController),
            const SizedBox(height: 18),

            // URL ekleme satırı
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _resimUrlController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: "Resim linki yapıştır (https://...)",
                      hintStyle: TextStyle(color: Colors.white24, fontSize: 12),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white24),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: gold),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_link, color: Colors.blue),
                  onPressed: _yukleniyor ? null : _urlEkle,
                ),
              ],
            ),

            const SizedBox(height: 14),

            // Foto seç
            _medyaKutusu(
              fotoSecildi ? "✅ FOTO HAZIR" : "FOTOĞRAF SEÇ",
              Icons.add_photo_alternate,
              Colors.blue,
              _yukleniyor ? null : _dosyaGezgininiAc,
            ),

            const SizedBox(height: 16),

            // Küçük önizleme bilgi
            if (_seciliUrl != null && _seciliUrl!.isNotEmpty)
              Text(
                "Link: ${_seciliUrl!}",
                style: const TextStyle(color: Colors.white38, fontSize: 11),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

            if (_webResimVerisi != null) ...[
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.memory(
                  _webResimVerisi!,
                  height: 160,
                  fit: BoxFit.cover,
                ),
              ),
            ],

            const SizedBox(height: 22),

            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _yukleniyor ? null : _arenadaYayinla,
                style: ElevatedButton.styleFrom(backgroundColor: gold),
                child: _yukleniyor
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text(
                        "ARENA'DA YAYINLA",
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _input(String l, TextEditingController c) {
    return TextField(
      controller: c,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: l,
        labelStyle: const TextStyle(color: Colors.white24, fontSize: 11),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.white24),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: gold),
        ),
      ),
    );
  }

  Widget _medyaKutusu(String t, IconData i, Color c, VoidCallback? onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          border: Border.all(color: c.withOpacity(0.35)),
          borderRadius: BorderRadius.circular(12),
          color: const Color(0xFF0A0A0A),
        ),
        child: Row(
          children: [
            Icon(i, color: c),
            const SizedBox(width: 10),
            Text(t,
                style: TextStyle(
                    color: c, fontSize: 11, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
