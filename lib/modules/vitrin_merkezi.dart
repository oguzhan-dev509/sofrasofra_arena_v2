import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:typed_data';
import 'package:sofrasofra_arena_v2/sepet_kontrol.dart';

class VitrinMerkezi extends StatefulWidget {
  const VitrinMerkezi({super.key});

  @override
  State<VitrinMerkezi> createState() => _VitrinMerkeziState();
}

class _VitrinMerkeziState extends State<VitrinMerkezi> {
  final List<Uint8List?> _vitrinResimler = List.generate(18, (index) => null);
  Uint8List? _profilResmi;

  String _secilenKategori = "Tümü";

  final List<Map<String, dynamic>> _kategoriler = const [
    {"ad": "Tümü", "ikon": Icons.grid_view},
    {"ad": "Ev Yapımı Yemekler", "ikon": Icons.soup_kitchen},
    {"ad": "Ev Yapımı Çikolata & Tatlılar", "ikon": Icons.cake},
    {"ad": "Ev Yapımı Süt Ürünleri", "ikon": Icons.water_drop},
    {"ad": "Ev Yapımı Turşu ve Diğerleri", "ikon": Icons.inventory_2},
    {"ad": "Ev Yapımı Baharat & Sos", "ikon": Icons.grass},
    {"ad": "Kasap: Taze Et, Köy Tavuk, Yumurta", "ikon": Icons.restaurant},
  ];

  String _sefAdi = "Şef Arda Türkmen";
  String _imzaYemek = "TRÜF MANTARLI RİZOTTO";
  String _youtubeLink = "https://www.youtube.com";
  String _tarifMetni = "";

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

  void _fotoSil(int index) {
    setState(() => _vitrinResimler[index] = null);
  }

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
            Container(
              height: 120,
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _kategoriler.length,
                itemBuilder: (context, index) {
                  bool secili = _secilenKategori == _kategoriler[index]['ad'];
                  return GestureDetector(
                    onTap: () => setState(
                        () => _secilenKategori = _kategoriler[index]['ad']),
                    child: Container(
                      width: 120,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Column(
                        children: [
                          CircleAvatar(
                            backgroundColor: secili
                                ? const Color(0xFFFFB300)
                                : const Color(0xFF1A1A1A),
                            radius: 30,
                            child: Icon(_kategoriler[index]['ikon'],
                                color: secili
                                    ? Colors.black
                                    : const Color(0xFFFFB300),
                                size: 26),
                          ),
                          const SizedBox(height: 6),
                          Text(_kategoriler[index]['ad'],
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  color: secili
                                      ? const Color(0xFFFFB300)
                                      : Colors.white38,
                                  fontWeight: secili
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  fontSize: 11)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const Divider(color: Colors.white10, height: 1),
            _buildSefHeader(),
            const SizedBox(height: 20),
            _buildActionButtons(),
            const SizedBox(height: 30),
            _buildGallerySection(),
            const SizedBox(height: 120),
          ],
        ),
      ),
      floatingActionButton: SepetKontrol().sepetim.isNotEmpty
          ? FloatingActionButton.extended(
              backgroundColor: const Color(0xFFFFB300),
              onPressed: () => _odemePaneliniAc(),
              icon: const Icon(Icons.shopping_basket, color: Colors.black),
              label: Text("${SepetKontrol().sepetim.length} ÜRÜN - ÖDEMEYE GİT",
                  style: const TextStyle(
                      color: Colors.black, fontWeight: FontWeight.bold)),
            )
          : null,
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
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 15,
          mainAxisSpacing: 15,
          childAspectRatio: 0.85,
        ),
        itemCount: 18,
        itemBuilder: (context, index) {
          return Stack(
            children: [
              GestureDetector(
                onTap: () => _fotoIslem(index),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white10),
                    image: _vitrinResimler[index] != null
                        ? DecorationImage(
                            image: MemoryImage(_vitrinResimler[index]!),
                            fit: BoxFit.cover)
                        : null,
                  ),
                  child: _vitrinResimler[index] == null
                      ? const Center(
                          child: Icon(Icons.camera_alt,
                              color: Colors.white24, size: 30))
                      : null,
                ),
              ),
              Positioned(
                bottom: 10,
                right: 10,
                child: GestureDetector(
                  onTap: () {
                    SepetKontrol().sepeteEkle(
                        "Arena Ürünü ${index + 1}", 250, Icons.restaurant);
                    setState(() {});
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text("Ürün Sepete Eklendi!"),
                        backgroundColor: Color(0xFFFFB300),
                        duration: Duration(milliseconds: 500)));
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                        color: Color(0xFFFFB300), shape: BoxShape.circle),
                    child: const Icon(Icons.add, color: Colors.black, size: 22),
                  ),
                ),
              ),
              if (_vitrinResimler[index] != null)
                Positioned(
                  top: 10,
                  right: 10,
                  child: GestureDetector(
                    onTap: () => _fotoSil(index),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                          color: Colors.black54, shape: BoxShape.circle),
                      child: const Icon(Icons.delete_forever,
                          color: Colors.red, size: 20),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  // ✨ GÜNCELLENEN ÖDEME PANELİ
  void _odemePaneliniAc() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(25),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("ARENA GÜVENLİ KASA",
                style: TextStyle(
                    color: Color(0xFFFFB300),
                    fontWeight: FontWeight.bold,
                    fontSize: 20)),
            const SizedBox(height: 15),
            Text("Toplam Tutar: ${SepetKontrol().toplamTutar} TL",
                style: const TextStyle(color: Colors.white, fontSize: 18)),
            const SizedBox(height: 25),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFB300),
                  minimumSize: const Size(double.infinity, 55),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15))),
              onPressed: () {
                // 1. Paneli kapat
                Navigator.pop(context);
                // 2. Sepeti boşalt
                SepetKontrol().sepetiBosalt();
                // 3. UI güncelle
                setState(() {});
                // 4. Başarı mesajını göster
                _basariMesajiGoster(context);
              },
              child: const Text("ÖDEMEYI TAMAMLA",
                  style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 16)),
            )
          ],
        ),
      ),
    );
  }

  // ✨ YENİ: BAŞARI ONAY EKRANI
  void _basariMesajiGoster(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_outline,
                color: Color(0xFFFFB300), size: 80),
            const SizedBox(height: 20),
            const Text("SİPARİŞ ALINDI!",
                style: TextStyle(
                    color: Color(0xFFFFB300),
                    fontWeight: FontWeight.bold,
                    fontSize: 20)),
            const SizedBox(height: 10),
            const Text(
                "Şef Arda Türkmen siparişinizi hazırlamaya başladı. Afiyet olsun!",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 14)),
            const SizedBox(height: 25),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("ARENA'YA DÖN",
                  style: TextStyle(color: Color(0xFFFFB300))),
            )
          ],
        ),
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
