import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class SefYonetimPaneli extends StatefulWidget {
  final String dukkanAdi;

  const SefYonetimPaneli({
    super.key,
    required this.dukkanAdi,
  });

  @override
  State<SefYonetimPaneli> createState() => _SefYonetimPaneliState();
}

class _SefYonetimPaneliState extends State<SefYonetimPaneli> {
  static const Color gold = Color(0xFFFFB300);
  static const Color bg = Color(0xFF050505);
  static const Color card = Color(0xFF121212);

  final TextEditingController _adSoyad = TextEditingController();
  final TextEditingController _unvan = TextEditingController();
  final TextEditingController _bio = TextEditingController();
  final TextEditingController _uzmanlik = TextEditingController();
  final TextEditingController _profilFoto = TextEditingController();
  final TextEditingController _kapakFoto = TextEditingController();

  final List<TextEditingController> _galeriControllers = [];

  bool _yukleniyor = true;
  bool _kaydediliyor = false;

  @override
  void initState() {
    super.initState();
    _yukle();
  }

  @override
  void dispose() {
    _adSoyad.dispose();
    _unvan.dispose();
    _bio.dispose();
    _uzmanlik.dispose();
    _profilFoto.dispose();
    _kapakFoto.dispose();

    for (final controller in _galeriControllers) {
      controller.dispose();
    }

    super.dispose();
  }

  Future<void> _yukle() async {
    setState(() => _yukleniyor = true);

    try {
      final qs = await FirebaseFirestore.instance
          .collection('urunler')
          .where('tip', isEqualTo: 'Usta Sefler')
          .where('dukkanAdi', isEqualTo: widget.dukkanAdi.trim())
          .limit(1)
          .get();

      if (qs.docs.isNotEmpty) {
        final data = qs.docs.first.data();

        _adSoyad.text = (data['adSoyad'] ?? '').toString();
        _unvan.text = (data['unvan'] ?? '').toString();
        _bio.text = (data['bio'] ?? '').toString();
        _uzmanlik.text = (data['uzmanlik'] ?? '').toString();
        _profilFoto.text = (data['img'] ?? '').toString();

        final cover = (data['coverImage'] ?? '').toString().trim();
        _kapakFoto.text =
            cover.isEmpty ? (data['img'] ?? '').toString() : cover;

        final gallery = (data['gallery'] is List)
            ? List<String>.from(
                (data['gallery'] as List).map((e) => e.toString()),
              )
            : <String>[];

        for (final controller in _galeriControllers) {
          controller.dispose();
        }
        _galeriControllers.clear();

        for (final url in gallery) {
          _galeriControllers.add(TextEditingController(text: url));
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Şef paneli yüklenemedi: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _yukleniyor = false);
      }
    }
  }

  Future<void> _kaydet() async {
    setState(() => _kaydediliyor = true);

    try {
      final img = _profilFoto.text.trim();
      final cover =
          _kapakFoto.text.trim().isEmpty ? img : _kapakFoto.text.trim();

      final gallery = _galeriControllers
          .map((e) => e.text.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      final payload = <String, dynamic>{
        'tip': 'Usta Sefler',
        'dukkanAdi': widget.dukkanAdi.trim(),
        'dukkan': widget.dukkanAdi.trim(),
        'adSoyad': _adSoyad.text.trim(),
        'unvan': _unvan.text.trim(),
        'bio': _bio.text.trim(),
        'uzmanlik': _uzmanlik.text.trim(),
        'img': img,
        'coverImage': cover,
        'gallery': gallery,
        'isActive': true,
        'aktifMi': true,
        'onayDurumu': 'onaylandi',
        'updatedAt': FieldValue.serverTimestamp(),
      };

      final qs = await FirebaseFirestore.instance
          .collection('urunler')
          .where('tip', isEqualTo: 'Usta Sefler')
          .where('dukkanAdi', isEqualTo: widget.dukkanAdi.trim())
          .limit(1)
          .get();
final validation = await ChefValidationService.validateChefProductBeforeCreate(
  ownerId: ownerId,
  dukkanId: dukkanId,
  ad: ad,
);

if (!validation.ok) {
  if (!mounted) return;

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(validation.message)),
  );
  return;
}
      if (qs.docs.isEmpty) {
       final validation = await ChefValidationService.validateChefProductBeforeCreate(
  ownerId: ownerId,
  dukkanId: dukkanId,
  ad: ad,
);

if (!validation.ok) {
  if (!mounted) return;

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(validation.message)),
  );
  return;
}

await FirebaseFirestore.instance.collection('urunler').add({
          ...payload,
          'createdAt': FieldValue.serverTimestamp(),
        });
      } else {
        await qs.docs.first.reference.set(payload, SetOptions(merge: true));
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Şef profili kaydedildi.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kayıt başarısız: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _kaydediliyor = false);
      }
    }
  }

  void _galeriSatiriEkle() {
    setState(() {
      _galeriControllers.add(TextEditingController());
    });
  }

  void _galeriSatiriSil(int index) {
    setState(() {
      _galeriControllers[index].dispose();
      _galeriControllers.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: gold),
        title: const Text(
          'ŞEF YÖNETİM PANELİ',
          style: TextStyle(
            color: gold,
            fontSize: 13,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.1,
          ),
        ),
      ),
      body: _yukleniyor
          ? const Center(
              child: CircularProgressIndicator(color: gold),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _kart(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _baslik('TEMEL BİLGİLER'),
                      const SizedBox(height: 12),
                      _alan(_adSoyad, 'Ad Soyad'),
                      _alan(_unvan, 'Unvan'),
                      _alan(_uzmanlik, 'Uzmanlık'),
                      _alan(_bio, 'Bio', maxLines: 4),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _kart(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _baslik('GÖRSEL ALANLAR'),
                      const SizedBox(height: 12),
                      _alan(_profilFoto, 'Ana Görsel URL (img)'),
                      _alan(_kapakFoto, 'Kapak Görsel URL (coverImage)'),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _kart(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _baslik('GALERİ'),
                          const Spacer(),
                          TextButton(
                            onPressed: _galeriSatiriEkle,
                            child: const Text(
                              'Satır Ekle',
                              style: TextStyle(color: gold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (_galeriControllers.isEmpty)
                        const Text(
                          'Henüz galeri görseli eklenmemiş.',
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
                          ),
                        ),
                      for (int i = 0; i < _galeriControllers.length; i++)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            children: [
                              Expanded(
                                child: _alan(
                                  _galeriControllers[i],
                                  'Galeri URL ${i + 1}',
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                onPressed: () => _galeriSatiriSil(i),
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.redAccent,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _kaydediliyor ? null : _kaydet,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: gold,
                      foregroundColor: Colors.black,
                    ),
                    child: _kaydediliyor
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.black,
                            ),
                          )
                        : const Text(
                            'KAYDET',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _kart({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0x22FFB300)),
      ),
      child: child,
    );
  }

  Widget _baslik(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: gold,
        fontSize: 12,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.1,
      ),
    );
  }

  Widget _alan(
    TextEditingController controller,
    String label, {
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white60),
          filled: true,
          fillColor: Colors.white.withAlpha(8),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.white.withAlpha(18)),
            borderRadius: BorderRadius.circular(12),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: gold),
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
