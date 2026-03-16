import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

class UrunEklemeSayfasi extends StatefulWidget {
  const UrunEklemeSayfasi({super.key});

  @override
  State<UrunEklemeSayfasi> createState() => _UrunEklemeSayfasiState();
}

class _UrunEklemeSayfasiState extends State<UrunEklemeSayfasi> {
  final TextEditingController _dukkanController = TextEditingController();
  final TextEditingController _urunAdiController = TextEditingController();
  final TextEditingController _uzmanlikController = TextEditingController();
  final TextEditingController _videoController = TextEditingController();
  final TextEditingController _resimUrlController = TextEditingController();
  final TextEditingController _fiyatController = TextEditingController();
  Uint8List? _webResimVerisi;
  String? _seciliUrl;

  bool _yukleniyor = false;
  bool _bugunPisiyor = false;
  String _tip = "Usta Sefler";
  String _sehir = "";
  String _ilce = "";
  String _kategori = "Ev Yemekleri";

  Map<String, List<String>> _ilcelerMap = {};
  bool _lokasyonYukleniyor = true;

  final List<String> _evLezzetiKategorileri = const [
    "Ev Yemekleri",
    "Çikolata & Tatlılar",
    "Süt Ürünleri",
    "Turşu & Diğerleri",
    "Baharat & Soslar",
  ];

  static const Color gold = Color(0xFFFFB300);

  @override
  void initState() {
    super.initState();
    _ilceleriYukle();
  }

  @override
  void dispose() {
    _dukkanController.dispose();
    _urunAdiController.dispose();
    _uzmanlikController.dispose();
    _videoController.dispose();
    _resimUrlController.dispose();
    _fiyatController.dispose();
    super.dispose();
  }

  Future<void> _ilceleriYukle() async {
    try {
      final raw = await rootBundle.loadString('assets/ilceler.json');
      final Map<String, dynamic> decoded = jsonDecode(raw);

      final map = decoded.map((k, v) {
        final list = (v as List).map((e) => e.toString()).toList();
        return MapEntry(k.toString(), list);
      });

      if (!mounted) return;
      setState(() {
        _ilcelerMap = Map<String, List<String>>.from(map);
        _lokasyonYukleniyor = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _lokasyonYukleniyor = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ İl/İlçe listesi yüklenemedi: $e")),
      );
    }
  }

  bool _isHttpUrl(String s) {
    final t = s.trim();
    return t.startsWith("http://") || t.startsWith("https://");
  }

  bool _isYoutubeUrl(String s) {
    final t = s.trim().toLowerCase();
    return t.contains("youtube.com") || t.contains("youtu.be");
  }

  Future<void> _youtubeLinkiniAc() async {
    final url = _videoController.text.trim();

    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ Önce YouTube linki giriniz.")),
      );
      return;
    }

    if (!_isYoutubeUrl(url)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ Geçerli bir YouTube linki giriniz.")),
      );
      return;
    }

    final uri = Uri.tryParse(url);
    if (uri == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ Link açılamadı.")),
      );
      return;
    }

    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);

    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ YouTube bağlantısı açılamadı.")),
      );
    }
  }

  Future<void> _dosyaGezgininiAc() async {
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );

      if (image == null) return;

      final bytes = await image.readAsBytes();

      if (!mounted) return;
      setState(() {
        _webResimVerisi = bytes;
        _seciliUrl = null;
        _resimUrlController.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Fotoğraf seçildi.")),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Foto seçim hatası: $e")),
      );
    }
  }

  void _urlEkle() {
    final url = _resimUrlController.text.trim();

    if (!_isHttpUrl(url)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ Geçerli http/https resim linki gir.")),
      );
      return;
    }

    setState(() {
      _seciliUrl = url;
      _webResimVerisi = null;
    });

    _resimUrlController.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("✅ Resim linki eklendi.")),
    );
  }

  Future<String> _bulutaYukle(String uid, Uint8List bytes) async {
    final dosyaAdi = "urun_${DateTime.now().millisecondsSinceEpoch}.jpg";

    final ref = FirebaseStorage.instance
        .ref()
        .child("urun_resimleri")
        .child(uid)
        .child(dosyaAdi);

    final task = ref.putData(
      bytes,
      SettableMetadata(contentType: "image/jpeg"),
    );

    final snap = await task;
    return await snap.ref.getDownloadURL();
  }

  Future<void> _arenadaYayinla() async {
    final dukkan = _dukkanController.text.trim();
    final urunAdi = _urunAdiController.text.trim();
    final uzmanlik = _uzmanlikController.text.trim();
    final videoUrl = _videoController.text.trim();
    final fiyatText = _fiyatController.text.trim();
    final double fiyat = double.tryParse(fiyatText.replaceAll(',', '.')) ?? 0;
    if (videoUrl.isNotEmpty && !_isYoutubeUrl(videoUrl)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ Geçerli YouTube linki giriniz.")),
      );
      return;
    }

    if (dukkan.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ Dükkan / Şef adı zorunlu.")),
      );
      return;
    }

    if (_sehir.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ Şehir seçmek zorunlu.")),
      );
      return;
    }

    if (_tip == "Ev Lezzetleri" && _ilce.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ Ev Lezzetleri için ilçe zorunlu.")),
      );
      return;
    }

    if (_tip == "Ev Lezzetleri" && urunAdi.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("❌ Ev Lezzetleri için ürün/yemek adı zorunlu."),
        ),
      );
      return;
    }

    final bool fotoVar = (_webResimVerisi != null) ||
        (_seciliUrl != null && _seciliUrl!.isNotEmpty);

    if (!fotoVar) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ Foto eklemelisin.")),
      );
      return;
    }

    setState(() => _yukleniyor = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      final uid = user?.uid ?? 'demo_user';

      String imgUrl;
      if (_webResimVerisi != null) {
        imgUrl = await _bulutaYukle(uid, _webResimVerisi!);
      } else {
        imgUrl = _seciliUrl!.trim();
      }

      if (!_isHttpUrl(imgUrl)) {
        throw Exception("img URL geçersiz üretildi.");
      }

      await FirebaseFirestore.instance.collection('urunler').add({
        "ad": (_tip == "Ev Lezzetleri") ? urunAdi : "",
        "img": imgUrl,
        "dukkan": dukkan,
        "dukkanId": uid,
        "sehir": _sehir,
        "ilce": _ilce,
        "uzmanlik": uzmanlik,
        "youtubeUrl": videoUrl,
        "tip": _tip,
        "kategori": _tip == "Ev Lezzetleri" ? _kategori : _tip,
        "bugunPisiyor": _tip == "Ev Lezzetleri" ? _bugunPisiyor : false,
        "onayDurumu": "onaylandi",
        "fiyat": fiyat,
        "isActive": true,
        "kayitTarihi": FieldValue.serverTimestamp(),
        "createdAt": FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Arena’da yayınlandı!")),
      );

      setState(() {
        _dukkanController.clear();
        _urunAdiController.clear();
        _uzmanlikController.clear();
        _videoController.clear();
        _resimUrlController.clear();
        _webResimVerisi = null;
        _seciliUrl = null;
        _kategori = "Ev Yemekleri";
        _bugunPisiyor = false;
      });

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

    final ilceler =
        _sehir.isEmpty ? <String>[] : (_ilcelerMap[_sehir] ?? <String>[]);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          "ÜRÜN YÖNETİM MERKEZİ",
          style: TextStyle(color: gold, fontSize: 13),
        ),
        iconTheme: const IconThemeData(color: gold),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<String>(
              dropdownColor: Colors.black,
              value: _tip,
              style: const TextStyle(color: Colors.white),
              items: const [
                DropdownMenuItem(
                  value: "Usta Sefler",
                  child: Text("Usta Şefler"),
                ),
                DropdownMenuItem(
                  value: "Restoranlar",
                  child: Text("Restoranlar"),
                ),
                DropdownMenuItem(
                  value: "Ev Lezzetleri",
                  child: Text("Ev Lezzetleri"),
                ),
              ],
              onChanged: _yukleniyor
                  ? null
                  : (v) {
                      if (v == null) return;
                      setState(() {
                        _tip = v;
                        if (_tip != "Ev Lezzetleri") {
                          _urunAdiController.clear();
                          _bugunPisiyor = false;
                        }
                      });
                    },
              decoration: const InputDecoration(
                labelText: "TİP",
                labelStyle: TextStyle(color: Colors.white24, fontSize: 11),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white24),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: gold),
                ),
              ),
            ),
            const SizedBox(height: 15),
            DropdownButtonFormField<String>(
              dropdownColor: Colors.black,
              value: _sehir.isEmpty ? null : _sehir,
              style: const TextStyle(color: Colors.white),
              items: _ilcelerMap.keys
                  .map((k) => DropdownMenuItem(value: k, child: Text(k)))
                  .toList(),
              onChanged: (_yukleniyor || _lokasyonYukleniyor)
                  ? null
                  : (v) {
                      if (v == null) return;
                      setState(() {
                        _sehir = v;
                        _ilce = "";
                      });
                    },
              decoration: InputDecoration(
                labelText: _lokasyonYukleniyor
                    ? "ŞEHİR (Yükleniyor...)"
                    : "ŞEHİR (ZORUNLU)",
                labelStyle: const TextStyle(
                  color: Colors.white24,
                  fontSize: 11,
                ),
                enabledBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white24),
                ),
                focusedBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: gold),
                ),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              dropdownColor: Colors.black,
              value: _ilce.isEmpty ? null : _ilce,
              style: const TextStyle(color: Colors.white),
              items: ilceler
                  .map((x) => DropdownMenuItem(value: x, child: Text(x)))
                  .toList(),
              onChanged: (_yukleniyor || _lokasyonYukleniyor || _sehir.isEmpty)
                  ? null
                  : (v) {
                      if (v == null) return;
                      setState(() => _ilce = v);
                    },
              decoration: InputDecoration(
                labelText: (_tip == "Ev Lezzetleri")
                    ? "İLÇE (ZORUNLU)"
                    : "İLÇE (OPSİYONEL)",
                labelStyle: const TextStyle(
                  color: Colors.white24,
                  fontSize: 11,
                ),
                enabledBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white24),
                ),
                focusedBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: gold),
                ),
              ),
            ),
            const SizedBox(height: 12),
            _input("DÜKKAN / ŞEF ADI", _dukkanController),
            if (_tip == "Ev Lezzetleri") ...[
              const SizedBox(height: 12),
              _input("YEMEK / ÜRÜN ADI", _urunAdiController),
              const SizedBox(height: 12),
              _input("FİYAT (örn: 120)", _fiyatController),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                dropdownColor: Colors.black,
                value: _kategori,
                style: const TextStyle(color: Colors.white),
                items: _evLezzetiKategorileri
                    .map((x) => DropdownMenuItem(value: x, child: Text(x)))
                    .toList(),
                onChanged: _yukleniyor
                    ? null
                    : (v) {
                        if (v == null) return;
                        setState(() => _kategori = v);
                      },
                decoration: const InputDecoration(
                  labelText: "ÜRÜN KATEGORİSİ",
                  labelStyle: TextStyle(
                    color: Colors.white24,
                    fontSize: 11,
                  ),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white24),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: gold),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF111111),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: gold.withOpacity(0.30)),
                ),
                child: SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  activeColor: gold,
                  value: _bugunPisiyor,
                  onChanged: _yukleniyor
                      ? null
                      : (value) {
                          setState(() {
                            _bugunPisiyor = value;
                          });
                        },
                  title: const Text(
                    "Bugün Pişiyor",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  subtitle: const Text(
                    "Açık olursa ürün 'Bugün Evde Ne Pişiyor' vitrininte öne çıkar.",
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            _input("UZMANLIK (opsiyonel)", _uzmanlikController),
            const SizedBox(height: 12),
            TextField(
              controller: _videoController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: "YOUTUBE LİNKİ (opsiyonel)",
                hintText: "https://youtube.com/... veya https://youtu.be/...",
                hintStyle: TextStyle(
                  color: Colors.white24,
                  fontSize: 12,
                ),
                labelStyle: TextStyle(
                  color: Colors.white24,
                  fontSize: 11,
                ),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white24),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: gold),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _medyaKutusu(
                    "🎬 YOUTUBE LİNKİNİ TEST ET",
                    Icons.play_circle_outline,
                    Colors.redAccent,
                    _yukleniyor ? null : _youtubeLinkiniAc,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _medyaKutusu(
                    "🧹 VİDEO LİNKİNİ TEMİZLE",
                    Icons.delete_outline,
                    Colors.orangeAccent,
                    _yukleniyor
                        ? null
                        : () {
                            setState(() {
                              _videoController.clear();
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("✅ Video linki temizlendi."),
                              ),
                            );
                          },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _resimUrlController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: "Resim linki (http/https)",
                      hintStyle: TextStyle(
                        color: Colors.white24,
                        fontSize: 12,
                      ),
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
            _medyaKutusu(
              fotoSecildi ? "✅ FOTO HAZIR" : "FOTOĞRAF SEÇ",
              Icons.add_photo_alternate,
              Colors.blue,
              _yukleniyor ? null : _dosyaGezgininiAc,
            ),
            const SizedBox(height: 25),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _yukleniyor ? null : _arenadaYayinla,
                style: ElevatedButton.styleFrom(
                  backgroundColor: gold,
                ),
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
            Expanded(
              child: Text(
                t,
                style: TextStyle(
                  color: c,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
