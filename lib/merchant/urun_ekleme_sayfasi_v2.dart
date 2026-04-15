import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/membership_plan_service.dart';

class UrunEklemeSayfasiV2 extends StatefulWidget {
  const UrunEklemeSayfasiV2({super.key});

  @override
  State<UrunEklemeSayfasiV2> createState() => _UrunEklemeSayfasiV2State();
}

class _UrunEklemeSayfasiV2State extends State<UrunEklemeSayfasiV2> {
  final TextEditingController _dukkanController = TextEditingController();
  final TextEditingController _urunAdiController = TextEditingController();
  final TextEditingController _uzmanlikController = TextEditingController();
  final TextEditingController _videoController = TextEditingController();
  final TextEditingController _resimUrlController = TextEditingController();
  final TextEditingController _fiyatController = TextEditingController();

  final List<Uint8List> _webResimler = [];
  final List<String> _seciliUrlList = [];

  bool _yukleniyor = false;
  bool _bugunPisiyor = false;
  String _tip = "Usta Sefler";
  String _sehir = "";
  String _ilce = "";
  String _kategori = "Ev Yemekleri";

  Map<String, List<String>> _ilcelerMap = {};
  bool _lokasyonYukleniyor = true;

  String _membershipType = 'free';
  int _maxPhotoCount = 3;
  int _maxVideoCount = 0;
  bool _canUseYoutube = false;
  bool _canBeFeatured = false;
  String _featuredScope = 'none';
  String _badgeType = 'none';
  int _priorityScore = 0;
  bool _membershipLoading = true;

  final List<String> _evLezzetiKategorileri = const [
    "Ev Yemekleri",
    "Çikolata & Tatlılar",
    "Süt Ürünleri",
    "Turşu & Diğerleri",
    "Baharat & Soslar",
  ];

  static const Color gold = Color(0xFFFFB300);

  int get _toplamSeciliFoto => _webResimler.length + _seciliUrlList.length;

  @override
  void initState() {
    super.initState();
    _ilceleriYukle();
    _uyelikPlaniniYukle();
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

  Future<void> _uyelikPlaniniYukle() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      final uid = user?.uid ?? 'demo_user';

      final doc =
          await FirebaseFirestore.instance.collection('sellers').doc(uid).get();

      final data = doc.data() ?? {};
      final plan = MembershipPlanService.fromSellerData(data);

      if (!mounted) return;

      setState(() {
        _membershipType = plan.type;
        _maxPhotoCount = plan.maxPhotoCount;
        _maxVideoCount = plan.maxVideoCount;
        _canUseYoutube = plan.canUseYoutube;
        _canBeFeatured = plan.canBeFeatured;
        _featuredScope = plan.featuredScope;
        _badgeType = plan.badgeType;
        _priorityScore = plan.priorityScore;
        _membershipLoading = false;
      });
    } catch (_) {
      final plan = MembershipPlanService.free;

      if (!mounted) return;

      setState(() {
        _membershipType = plan.type;
        _maxPhotoCount = plan.maxPhotoCount;
        _maxVideoCount = plan.maxVideoCount;
        _canUseYoutube = plan.canUseYoutube;
        _canBeFeatured = plan.canBeFeatured;
        _featuredScope = plan.featuredScope;
        _badgeType = plan.badgeType;
        _priorityScore = plan.priorityScore;
        _membershipLoading = false;
      });
    }
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
    if (!_canUseYoutube) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "❌ YouTube linki eklemek için Pro veya Premium paket gerekir.",
          ),
        ),
      );
      return;
    }

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
      if (_toplamSeciliFoto >= _maxPhotoCount) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '❌ Fotoğraf limitine ulaştınız. Paketiniz en fazla $_maxPhotoCount fotoğraf destekliyor.',
            ),
          ),
        );
        return;
      }

      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );

      if (image == null) return;

      final bytes = await image.readAsBytes();

      if (!mounted) return;
      setState(() {
        _webResimler.add(bytes);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '✅ Fotoğraf eklendi. ($_toplamSeciliFoto / $_maxPhotoCount)',
          ),
        ),
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

    if (_toplamSeciliFoto >= _maxPhotoCount) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '❌ Fotoğraf limitine ulaştınız. Paketiniz en fazla $_maxPhotoCount fotoğraf destekliyor.',
          ),
        ),
      );
      return;
    }

    if (!_isHttpUrl(url)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ Geçerli http/https resim linki gir.")),
      );
      return;
    }

    setState(() {
      _seciliUrlList.add(url);
    });

    _resimUrlController.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '✅ Resim linki eklendi. ($_toplamSeciliFoto / $_maxPhotoCount)',
        ),
      ),
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

    if (videoUrl.isNotEmpty) {
      if (!_canUseYoutube) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "❌ YouTube linki eklemek için Pro veya Premium paket gerekir.",
            ),
          ),
        );
        return;
      }

      if (!_isYoutubeUrl(videoUrl)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("❌ Geçerli YouTube linki giriniz.")),
        );
        return;
      }
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

    final bool fotoVar = _webResimler.isNotEmpty || _seciliUrlList.isNotEmpty;

    if (!fotoVar) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ En az 1 foto eklemelisin.")),
      );
      return;
    }

    setState(() => _yukleniyor = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      final uid = user?.uid ?? 'demo_user';

      List<String> uploadedImages = [];

// Galeriden seçilenleri yükle
      for (final bytes in _webResimler) {
        final url = await _bulutaYukle(uid, bytes);
        uploadedImages.add(url);
      }

// URL ile eklenenleri ekle
      uploadedImages.addAll(_seciliUrlList);

// Ana görsel
      String imgUrl = uploadedImages.isNotEmpty ? uploadedImages.first : '';

      if (!_isHttpUrl(imgUrl)) {
        throw Exception("img URL geçersiz üretildi.");
      }

      final List<String> allImages = [];

      if (_webResimler.isNotEmpty) {
        allImages.add('[local_images_pending_upload]');
      }

      if (_seciliUrlList.isNotEmpty) {
        allImages.addAll(_seciliUrlList);
      }

      await FirebaseFirestore.instance.collection('urunler').add({
        "ad": (_tip == "Ev Lezzetleri") ? urunAdi : "",
        "img": imgUrl,
        "images": uploadedImages,
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
        "sellerMembershipType": _membershipType,
        "sellerBadgeType": _badgeType,
        "featuredScope": _featuredScope,
        "isFeatured": false,
        "featureRank": 0,
        "photoCount": _toplamSeciliFoto,
        "listingScore": _priorityScore,
        "kayitTarihi": FieldValue.serverTimestamp(),
        "createdAt": FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _toplamSeciliFoto > 1
                ? "✅ Ürün yayınlandı. Çoklu upload’un tam sürümü sonraki adımda açılacak."
                : "✅ Arena’da yayınlandı!",
          ),
        ),
      );

      setState(() {
        _dukkanController.clear();
        _urunAdiController.clear();
        _uzmanlikController.clear();
        _videoController.clear();
        _resimUrlController.clear();
        _fiyatController.clear();
        _webResimler.clear();
        _seciliUrlList.clear();
        _kategori = "Ev Yemekleri";
        _bugunPisiyor = false;
        _ilce = "";
      });

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Hata: $e")),
      );
    } finally {
      if (mounted) {
        setState(() => _yukleniyor = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool fotoSecildi =
        _webResimler.isNotEmpty || _seciliUrlList.isNotEmpty;

    final List<String> ilceler =
        _sehir.isEmpty ? <String>[] : (_ilcelerMap[_sehir] ?? <String>[]);

    final String planName =
        MembershipPlanService.planDisplayName(_membershipType);
    final String badgeLabel = MembershipPlanService.badgeLabel(_badgeType);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          "ÜRÜN YÖNETİM MERKEZİ V2",
          style: TextStyle(color: gold, fontSize: 13),
        ),
        iconTheme: const IconThemeData(color: gold),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF111111),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: gold.withValues(alpha: 0.30)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _membershipLoading
                        ? "Paket bilgisi yükleniyor..."
                        : "Paket: $planName",
                    style: const TextStyle(
                      color: gold,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Fotoğraf hakkı: $_maxPhotoCount • Video hakkı: $_maxVideoCount",
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _canUseYoutube
                        ? "YouTube linki kullanabilirsiniz."
                        : "YouTube linki için Pro veya Premium gerekir.",
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 11,
                    ),
                  ),
                  if (_canBeFeatured) ...[
                    const SizedBox(height: 4),
                    Text(
                      "Öne çıkarma kapsamı: $_featuredScope",
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 11,
                      ),
                    ),
                  ],
                  if (badgeLabel.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      "Rozet: $badgeLabel",
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Text(
                    "Seçilen görseller: $_toplamSeciliFoto / $_maxPhotoCount",
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 15),
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
                  .map((k) => DropdownMenuItem<String>(
                        value: k,
                        child: Text(k),
                      ))
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
                  .map((x) => DropdownMenuItem<String>(
                        value: x,
                        child: Text(x),
                      ))
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
                    .map((x) => DropdownMenuItem<String>(
                          value: x,
                          child: Text(x),
                        ))
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
                  border: Border.all(color: gold.withValues(alpha: 0.30)),
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
              enabled: _canUseYoutube && !_yukleniyor,
              style: TextStyle(
                color: _canUseYoutube ? Colors.white : Colors.white38,
              ),
              decoration: InputDecoration(
                labelText: "YOUTUBE LİNKİ (opsiyonel)",
                hintText: _canUseYoutube
                    ? "https://youtube.com/... veya https://youtu.be/..."
                    : "Bu alan Pro / Premium pakette açılır",
                hintStyle: const TextStyle(
                  color: Colors.white24,
                  fontSize: 12,
                ),
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
                disabledBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white24),
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
                    (_yukleniyor || !_canUseYoutube) ? null : _youtubeLinkiniAc,
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
              fotoSecildi
                  ? "✅ FOTOĞRAF EKLE ($_toplamSeciliFoto / $_maxPhotoCount)"
                  : "FOTOĞRAF SEÇ",
              Icons.add_photo_alternate,
              Colors.blue,
              _yukleniyor ? null : _dosyaGezgininiAc,
            ),
            if (_webResimler.isNotEmpty || _seciliUrlList.isNotEmpty) ...[
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (int i = 0; i < _webResimler.length; i++)
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.memory(
                            _webResimler[i],
                            width: 86,
                            height: 86,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _webResimler.removeAt(i);
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.black87,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                size: 14,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  for (int i = 0; i < _seciliUrlList.length; i++)
                    Stack(
                      children: [
                        Container(
                          width: 86,
                          height: 86,
                          decoration: BoxDecoration(
                            color: const Color(0xFF151515),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white12),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              _seciliUrlList[i],
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) {
                                return const Center(
                                  child: Icon(
                                    Icons.link,
                                    color: Colors.white54,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _seciliUrlList.removeAt(i);
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.black87,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                size: 14,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ],
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
          border: Border.all(color: c.withValues(alpha: 0.35)),
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
