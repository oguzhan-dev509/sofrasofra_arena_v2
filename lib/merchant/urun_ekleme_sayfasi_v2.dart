// EV LEZZETLERİ - FULL PREMIUM CLEAN VERSION

import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:image_picker/image_picker.dart';

import '../services/membership_plan_service.dart';

class UrunEklemeSayfasiV2 extends StatefulWidget {
  const UrunEklemeSayfasiV2({super.key});

  @override
  State<UrunEklemeSayfasiV2> createState() => _UrunEklemeSayfasiV2State();
}

class _UrunEklemeSayfasiV2State extends State<UrunEklemeSayfasiV2> {
  final TextEditingController _dukkan = TextEditingController();
  final TextEditingController _urun = TextEditingController();
  final TextEditingController _uzmanlik = TextEditingController();
  final TextEditingController _video = TextEditingController();
  final TextEditingController _resimUrl = TextEditingController();
  final TextEditingController _fiyat = TextEditingController();

  final List<Uint8List> _webResimler = [];
  final List<String> _urlResimler = [];

  bool _loading = false;
  bool _bugunPisiyor = false;

  String _sehir = '';
  String _ilce = '';
  String _kategori = 'Ev Yemekleri';

  Map<String, List<String>> _ilcelerMap = {};

  String _membershipType = 'free';
  int _maxPhoto = 3;
  int _maxVideo = 0;
  bool _canUseYoutube = false;
  bool _lokasyonYukleniyor = true;

  static const Color gold = Color(0xFFFFB300);

  final List<String> kategoriler = const [
    'Ev Yemekleri',
    'Tatlılar',
    'Süt Ürünleri',
    'Turşu & Reçel',
    'Sos & Baharat',
  ];

  int get toplamFoto => _webResimler.length + _urlResimler.length;

  @override
  void initState() {
    super.initState();
    _ilceleriYukle();
    _uyelikYukle();
  }

  @override
  void dispose() {
    _dukkan.dispose();
    _urun.dispose();
    _uzmanlik.dispose();
    _video.dispose();
    _resimUrl.dispose();
    _fiyat.dispose();
    super.dispose();
  }

  Future<void> _uyelikYukle() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final doc = await FirebaseFirestore.instance
          .collection('sellers')
          .doc(user.uid)
          .get();

      final plan = MembershipPlanService.fromSellerData(doc.data() ?? {});

      if (!mounted) return;
      setState(() {
        _membershipType = plan.type;
        _maxPhoto = plan.maxPhotoCount;
        _maxVideo = plan.maxVideoCount;
        _canUseYoutube = plan.canUseYoutube;
      });
    } catch (_) {}
  }

  Future<void> _ilceleriYukle() async {
    try {
      final raw = await rootBundle.loadString('assets/ilceler.json');
      final data = jsonDecode(raw) as Map<String, dynamic>;

      if (!mounted) return;
      setState(() {
        _ilcelerMap = data.map(
          (k, v) => MapEntry(k, List<String>.from(v as List)),
        );
        _lokasyonYukleniyor = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _lokasyonYukleniyor = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ İl/İlçe listesi yüklenemedi: $e')),
      );
    }
  }

  bool _isYoutubeUrl(String value) {
    final t = value.trim().toLowerCase();
    return t.contains('youtube.com') || t.contains('youtu.be');
  }

  Future<String> _upload(Uint8List bytes) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('Giriş yapan kullanıcı bulunamadı.');
    }

    final fileName =
        'urun_${DateTime.now().millisecondsSinceEpoch}_${bytes.length}.jpg';

    final ref = FirebaseStorage.instance
        .ref()
        .child('urunler')
        .child(user.uid)
        .child(fileName);

    //debugPrint('📤 UPLOAD PATH: ${ref.fullPath}');

    final snap = await ref.putData(
      bytes,
      SettableMetadata(contentType: 'image/jpeg'),
    );

    final url = await snap.ref.getDownloadURL();
    // debugPrint('✅ UPLOAD OK: $url');

    return url;
  }

  Future<void> _pick() async {
    if (toplamFoto >= _maxPhoto) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Limit doldu ($_maxPhoto fotoğraf)'),
        ),
      );
      return;
    }

    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );

    if (file == null) return;

    final bytes = await file.readAsBytes();

    if (!mounted) return;
    setState(() {
      _webResimler.add(bytes);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ Fotoğraf eklendi. ($toplamFoto / $_maxPhoto)'),
      ),
    );
  }

  void _urlEkle() {
    final url = _resimUrl.text.trim();

    if (toplamFoto >= _maxPhoto) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Limit doldu ($_maxPhoto fotoğraf)'),
        ),
      );
      return;
    }

    if (!(url.startsWith('http://') || url.startsWith('https://'))) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Geçerli bir resim linki giriniz.'),
        ),
      );
      return;
    }

    setState(() {
      _urlResimler.add(url);
      _resimUrl.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ Resim linki eklendi. ($toplamFoto / $_maxPhoto)'),
      ),
    );
  }

  Future<void> _yayinla() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ Giriş yapmalısın')),
      );
      return;
    }

    final dukkan = _dukkan.text.trim();
    final urun = _urun.text.trim();
    final uzmanlik = _uzmanlik.text.trim();
    final youtubeUrl = _video.text.trim();
    final fiyatText = _fiyat.text.trim();
    final fiyat = double.tryParse(fiyatText.replaceAll(',', '.')) ?? 0;

    if (dukkan.isEmpty ||
        urun.isEmpty ||
        _sehir.isEmpty ||
        _ilce.isEmpty ||
        toplamFoto == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ Tüm alanları doldur')),
      );
      return;
    }

    if (youtubeUrl.isNotEmpty) {
      if (!_canUseYoutube) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '❌ YouTube linki eklemek için daha üst paket gerekir.',
            ),
          ),
        );
        return;
      }

      if (!_isYoutubeUrl(youtubeUrl)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Geçerli bir YouTube linki giriniz.'),
          ),
        );
        return;
      }
    }

    setState(() => _loading = true);

    try {
      final List<String> urls = [];

      for (final img in _webResimler) {
        final uploadedUrl = await _upload(img);
        if (uploadedUrl.trim().isNotEmpty) {
          urls.add(uploadedUrl);
        }
      }

      for (final url in _urlResimler) {
        final clean = url.trim();
        if (clean.isNotEmpty) {
          urls.add(clean);
        }
      }

      if (urls.isEmpty) {
        throw Exception('Hiçbir görsel URL üretilemedi.');
      }

      final primaryImage = urls.first;

      final Map<String, dynamic> payload = {
        'ad': urun,
        'img': primaryImage,
        'images': urls,
        'dukkan': dukkan,
        'dukkanAdi': dukkan,
        'dukkanId': user.uid,
        'sellerId': user.uid,
        'ownerId': user.uid,
        'sehir': _sehir,
        'ilce': _ilce,
        'kategori': _kategori,
        'tip': 'Ev Lezzetleri',
        'bugunPisiyor': _bugunPisiyor,
        'uzmanlik': uzmanlik,
        'youtubeUrl': youtubeUrl,
        'fiyat': fiyat,
        'gelAlFiyat': fiyat > 0 ? fiyat.toStringAsFixed(0) : '',
        'goturFiyat': '',
        'sellerMembershipType': _membershipType,
        'photoCount': urls.length,
        'aktifMi': true,
        'isActive': true,
        'onayDurumu': 'onaylandi',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      //debugPrint('🧠 URUN PAYLOAD: $payload');

      final docRef =
          await FirebaseFirestore.instance.collection('urunler').add(payload);

      // debugPrint('✅ URUN YAZILDI: ${docRef.id}');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Ürün başarıyla yayınlandı')),
      );

      Navigator.pop(context);
    } catch (e, st) {
      debugPrint('❌ YAYINLA HATA: $e');
      debugPrint('$st');

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  String _planTitle() {
    switch (_membershipType.toLowerCase()) {
      case 'premium':
        return 'Premium';
      case 'pro':
        return 'Pro';
      default:
        return 'Ücretsiz';
    }
  }

  String _upgradeTitle() {
    switch (_membershipType.toLowerCase()) {
      case 'pro':
        return "Premium'a yükselt";
      case 'premium':
        return "Premium aktif";
      default:
        return "PRO'ya yükselt";
    }
  }

  String _upgradeSubtitle() {
    switch (_membershipType.toLowerCase()) {
      case 'pro':
        return '24 fotoğraf + 3 video linki + daha güçlü vitrin';
      case 'premium':
        return 'En yüksek görünürlük paketi aktif';
      default:
        return '8 fotoğraf + 1 video linki + daha güçlü görünürlük';
    }
  }

  void _showPlanSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF111111),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.72,
            minChildSize: 0.50,
            maxChildSize: 0.90,
            builder: (context, scrollController) {
              return SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Center(
                      child: SizedBox(
                        width: 42,
                        child: Divider(
                          thickness: 3,
                          color: Colors.white24,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Paket Karşılaştırması',
                      style: TextStyle(
                        color: gold,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _planCard(
                      title: 'Ücretsiz',
                      features: const [
                        'Aylık: 0 TL',
                        'Komisyon: %10',
                        '3 fotoğraf',
                        '0 video linki',
                        'Temel görünürlük',
                      ],
                      highlighted: _membershipType.toLowerCase() == 'free',
                    ),
                    const SizedBox(height: 12),
                    _planCard(
                      title: 'Pro',
                      features: const [
                        'Aylık: 149 TL',
                        'Komisyon: %5',
                        '8 fotoğraf',
                        '1 video linki',
                        'Daha güçlü görünürlük',
                      ],
                      highlighted: _membershipType.toLowerCase() == 'pro',
                    ),
                    const SizedBox(height: 12),
                    _planCard(
                      title: 'Premium',
                      features: const [
                        'Aylık: 299 TL',
                        'Komisyon: %2',
                        '24 fotoğraf',
                        '3 video linki',
                        'Mahalle vitrin önceliği',
                      ],
                      highlighted: _membershipType.toLowerCase() == 'premium',
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(this.context).showSnackBar(
                            const SnackBar(
                              content:
                                  Text('Yükseltme akışı yakında açılacak.'),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: gold,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text(
                          'Yakında Açılacak',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _planCard({
    required String title,
    required List<String> features,
    required bool highlighted,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF181818),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: highlighted ? gold : Colors.white12,
          width: highlighted ? 1.4 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: highlighted ? gold : Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          for (final feature in features) ...[
            Text(
              '• $feature',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
          ],
        ],
      ),
    );
  }

  Widget _upgradeCta() {
    if (_membershipType.toLowerCase() == 'premium') {
      return Container(
        margin: const EdgeInsets.only(top: 10),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF181818),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: gold.withOpacity(0.25)),
        ),
        child: Row(
          children: const [
            Icon(Icons.workspace_premium_rounded, color: gold, size: 18),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Premium aktif · En yüksek görünürlük paketi',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return InkWell(
      onTap: _showPlanSheet,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(top: 10),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF181818),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: gold.withOpacity(0.25)),
        ),
        child: Row(
          children: [
            const Icon(Icons.trending_up_rounded, color: gold, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _upgradeTitle(),
                    style: const TextStyle(
                      color: gold,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _upgradeSubtitle(),
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: gold),
          ],
        ),
      ),
    );
  }

  InputDecoration _decoration(String label) {
    return const InputDecoration().copyWith(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      enabledBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: Colors.white24),
      ),
      focusedBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: gold),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<String> ilceler =
        _sehir.isEmpty ? <String>[] : (_ilcelerMap[_sehir] ?? <String>[]);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          'ÜRÜN EKLE',
          style: TextStyle(color: gold),
        ),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: gold),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF111111),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: gold.withOpacity(0.30)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Paketin: ${_planTitle()} · Pro/Premium ile görünürlüğünü artır',
                    style: const TextStyle(
                      color: gold,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Fotoğraf hakkı: $_maxPhoto',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Video hakkı: $_maxVideo',
                    style: const TextStyle(color: Colors.white54),
                  ),
                  const SizedBox(height: 10),
                  InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: _showPlanSheet,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: gold.withValues(alpha: 0.22),
                        ),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'PAKETİNİ BÜYÜT, DAHA FAZLA GÖRÜNÜR OL',
                            style: TextStyle(
                              color: gold,
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Ücretsiz: Aylık 0 TL • Komisyon %10 • 3 fotoğraf',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12.5,
                              height: 1.35,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Pro: Aylık 149 TL • Komisyon %5 • 8 fotoğraf • 1 video',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12.5,
                              height: 1.35,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Premium: Aylık 299 TL • Komisyon %2 • 24 fotoğraf • 3 video',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12.5,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Seçilen: $toplamFoto / $_maxPhoto',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: _showPlanSheet,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF181818),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: gold.withValues(alpha: 0.24)),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.workspace_premium_rounded,
                            color: gold,
                            size: 18,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Pro ve Premium avantajlarını görmek için dokun',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.keyboard_arrow_up_rounded,
                            color: gold,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _upgradeCta(),
                ],
              ),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              dropdownColor: Colors.black,
              value: _sehir.isEmpty ? null : _sehir,
              style: const TextStyle(color: Colors.white),
              items: _ilcelerMap.keys
                  .map(
                    (e) => DropdownMenuItem<String>(
                      value: e,
                      child: Text(e),
                    ),
                  )
                  .toList(),
              onChanged: (_loading || _lokasyonYukleniyor)
                  ? null
                  : (v) {
                      if (v == null) return;
                      setState(() {
                        _sehir = v;
                        _ilce = '';
                      });
                    },
              decoration: _decoration(
                _lokasyonYukleniyor ? 'Şehir (Yükleniyor...)' : 'Şehir',
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              dropdownColor: Colors.black,
              value: _ilce.isEmpty ? null : _ilce,
              style: const TextStyle(color: Colors.white),
              items: ilceler
                  .map(
                    (e) => DropdownMenuItem<String>(
                      value: e,
                      child: Text(e),
                    ),
                  )
                  .toList(),
              onChanged: (_loading || _lokasyonYukleniyor || _sehir.isEmpty)
                  ? null
                  : (v) {
                      if (v == null) return;
                      setState(() => _ilce = v);
                    },
              decoration: _decoration('İlçe'),
            ),
            const SizedBox(height: 12),
            _input('Dükkan', _dukkan),
            const SizedBox(height: 12),
            _input('Ürün', _urun),
            const SizedBox(height: 12),
            _input('Fiyat', _fiyat),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              dropdownColor: Colors.black,
              value: _kategori,
              style: const TextStyle(color: Colors.white),
              items: kategoriler
                  .map(
                    (e) => DropdownMenuItem<String>(
                      value: e,
                      child: Text(e),
                    ),
                  )
                  .toList(),
              onChanged: _loading
                  ? null
                  : (v) {
                      if (v == null) return;
                      setState(() => _kategori = v);
                    },
              decoration: _decoration('Kategori'),
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              value: _bugunPisiyor,
              onChanged:
                  _loading ? null : (v) => setState(() => _bugunPisiyor = v),
              activeColor: gold,
              title: const Text(
                'Bugün Pişiyor',
                style: TextStyle(color: Colors.white),
              ),
              subtitle: const Text(
                "Açık olursa ürün vitrinde öne çıkar.",
                style: TextStyle(color: Colors.white54),
              ),
            ),
            const SizedBox(height: 12),
            _input('Uzmanlık', _uzmanlik),
            const SizedBox(height: 12),
            _input('YouTube', _video),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _loading ? null : _pick,
              child: const Text('Fotoğraf Seç'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _input('Resim URL', _resimUrl)),
                IconButton(
                  onPressed: _loading ? null : _urlEkle,
                  icon: const Icon(Icons.add, color: gold),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loading ? null : _yayinla,
              style: ElevatedButton.styleFrom(
                backgroundColor: gold,
              ),
              child: _loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                      ),
                    )
                  : const Text(
                      "ARENA'DA YAYINLA",
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _input(String title, TextEditingController controller) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      decoration: _decoration(title),
    );
  }
}
