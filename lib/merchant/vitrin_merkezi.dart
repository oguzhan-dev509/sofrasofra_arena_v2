import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';

class VitrinMerkeziSayfasi extends StatefulWidget {
  const VitrinMerkeziSayfasi({super.key});

  @override
  State<VitrinMerkeziSayfasi> createState() => _VitrinMerkeziSayfasiState();
}

class _VitrinMerkeziSayfasiState extends State<VitrinMerkeziSayfasi> {
  static const Color _gold = Color(0xFFFFB300);

  static const String _placeholderImg =
      "https://images.unsplash.com/photo-1546069901-ba9599a7e63c?auto=format&fit=crop&w=1200&q=60";

  final ImagePicker _picker = ImagePicker();

  // 🔥 DÜKKAN ADI (Burası satış tarafına 'dukkan' etiketiyle gider)
  String dukkanAdi = "SOFRASOFRA.COM";

  String seciliKategori = "RESTORANLAR";

  final List<String> evAltKategoriler = const [
    "EV YEMEKLER",
    "EV YAPIMI ÇİKOLATA & TATLILAR",
    "EV YAPIMI SÜT ÜRÜNLERİ",
    "EV YAPIMI TURŞU VE DİĞERLERİ",
  ];
  String seciliEvAltKategori = "EV YEMEKLER";

  late List<Map<String, dynamic>>
      _onSekizUrun; // final kaldırıldı, resetleme için

  bool _gonderiliyor = false;

  @override
  void initState() {
    super.initState();
    _onSekizUrun = List.generate(18, (_) => _bosUrun());
  }

  Map<String, dynamic> _bosUrun() => {
        "ad": "",
        "tarif": "",
        "gelAlFiyat": "",
        "goturFiyat": "",
        "resimBytes": null,
        "resimUrl": "",
        "teslimat": true,
      };

  // ✅ Storage upload helper
  Future<String> _uploadImageBytesToStorage(Uint8List bytes) async {
    final ts = DateTime.now().millisecondsSinceEpoch;
    final ref =
        FirebaseStorage.instance.ref().child('urunler').child('urun_$ts.jpg');

    final snap = await ref.putData(
      bytes,
      SettableMetadata(contentType: 'image/jpeg'),
    );

    return await snap.ref.getDownloadURL();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: Text(
          dukkanAdi,
          style: const TextStyle(
            // const eklendi
            color: _gold,
            fontWeight: FontWeight.w900,
            fontSize: 18,
            letterSpacing: 0.8,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _kategoriSeciciWidget(),
            if (seciliKategori == "EV LEZZETLERİ") _evAltKategoriSecici(),
            _hizliErisimBari(context),
            const SizedBox(height: 10),
            _urunGridiWidget(),
            const SizedBox(height: 110),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: _gold,
        onPressed: _gonderiliyor ? null : _vitriniMuhurleFirestore,
        icon: _gonderiliyor
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.black),
              )
            : const Icon(Icons.send, color: Colors.black),
        label: Text(
          _gonderiliyor ? "GÖNDERİLİYOR..." : "ARENA'YA GÖNDER",
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }

  // ---------------- UI ----------------

  Widget _kategoriSeciciWidget() {
    final kategoriler = ["EV LEZZETLERİ", "RESTORANLAR", "USTA ŞEFLER"];

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: kategoriler.map((k) {
          final secili = seciliKategori == k;

          return InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () {
              setState(() {
                seciliKategori = k;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
              decoration: BoxDecoration(
                color: secili ? _gold : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: secili ? _gold : Colors.white10),
              ),
              child: Text(
                k,
                style: TextStyle(
                  color: secili ? Colors.black : Colors.white38,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _evAltKategoriSecici() {
    return SizedBox(
      height: 58,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        itemCount: evAltKategoriler.length,
        itemBuilder: (context, i) {
          final k = evAltKategoriler[i];
          final secili = seciliEvAltKategori == k;

          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: ChoiceChip(
              selected: secili,
              selectedColor: _gold,
              backgroundColor: Colors.white10,
              label: Text(
                k,
                style: TextStyle(
                  color: secili ? Colors.black : Colors.white70,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
              onSelected: (_) => setState(() => seciliEvAltKategori = k),
            ),
          );
        },
      ),
    );
  }

  Widget _hizliErisimBari(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _barButonWidget(
            Icons.location_on,
            "ADRES",
            () => _adresGirisPenceresi(context),
          ),
          _barButonWidget(
            Icons.credit_card,
            "ÖDEME",
            () => _odemePenceresiGoster(context),
          ),
        ],
      ),
    );
  }

  Widget _barButonWidget(IconData ikon, String metin, VoidCallback aksiyon) {
    return ActionChip(
      backgroundColor: Colors.white10,
      avatar: Icon(ikon, color: _gold, size: 16),
      label: Text(metin,
          style: const TextStyle(color: Colors.white, fontSize: 10)),
      onPressed: aksiyon,
    );
  }

  Widget _urunGridiWidget() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 20,
        mainAxisSpacing: 25,
        childAspectRatio: 0.82,
      ),
      itemCount: 18,
      itemBuilder: (context, index) => _urunKaresiWidget(index),
    );
  }

  Widget _urunKaresiWidget(int i) {
    final dolu = (_onSekizUrun[i]["ad"] ?? "").toString().trim().isNotEmpty;

    final Uint8List? bytes = _onSekizUrun[i]["resimBytes"] as Uint8List?;
    final String url = (_onSekizUrun[i]["resimUrl"] ?? "").toString().trim();

    Widget imgWidget;
    if (bytes != null) {
      imgWidget =
          Image.memory(bytes, fit: BoxFit.cover, width: double.infinity);
    } else if (url.startsWith("http")) {
      imgWidget = Image.network(url, fit: BoxFit.cover, width: double.infinity);
    } else {
      imgWidget = const Center(
        child: Icon(Icons.add_a_photo, color: Colors.white10, size: 30),
      );
    }

    return GestureDetector(
      onTap: () => _urunDetayFormuAc(i),
      child: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: _gold, width: 5),
                    boxShadow: dolu
                        ? [
                            BoxShadow(
                                color: _gold.withAlpha(40), blurRadius: 15)
                          ]
                        : null,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: imgWidget,
                  ),
                ),
                if (dolu)
                  Positioned(
                    top: 5,
                    right: 5,
                    child: GestureDetector(
                      onTap: () => setState(() => _onSekizUrun[i] = _bosUrun()),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.redAccent,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close,
                            color: Colors.white, size: 14),
                      ),
                    ),
                  ),
                if (dolu)
                  const Positioned(
                    bottom: 8,
                    right: 8,
                    child: Icon(Icons.edit, color: _gold, size: 14),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            dolu
                ? (_onSekizUrun[i]["ad"] ?? "").toString().toUpperCase()
                : "BOŞ KUTU",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            dolu ? "${(_onSekizUrun[i]["gelAlFiyat"] ?? "")} TL" : "-",
            style: const TextStyle(
              color: _gold,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- Form ----------------

  void _urunDetayFormuAc(int i) {
    final ad = TextEditingController(text: _onSekizUrun[i]["ad"]);
    final tarif = TextEditingController(text: _onSekizUrun[i]["tarif"]);
    final gelAl = TextEditingController(text: _onSekizUrun[i]["gelAlFiyat"]);
    final gotur = TextEditingController(text: _onSekizUrun[i]["goturFiyat"]);
    bool teslim = _onSekizUrun[i]["teslimat"] == true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0D0D0D),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (c) => StatefulBuilder(
        builder: (context, setModal) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(c).viewInsets.bottom,
            left: 25,
            right: 25,
            top: 25,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "ÜRÜNÜ MÜHÜRLE",
                style: TextStyle(color: _gold, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 20),
              _inputWidget(ad, "Yemek Adı", Icons.restaurant),
              _inputWidget(tarif, "Tarif / İçerik", Icons.menu_book),
              Row(
                children: [
                  Expanded(
                      child: _inputWidget(gelAl, "Gel-Al", Icons.storefront)),
                  const SizedBox(width: 15),
                  Expanded(
                    child: _inputWidget(gotur, "Götür", Icons.delivery_dining),
                  ),
                ],
              ),
              SwitchListTile(
                title: const Text(
                  "Teslimat var mı?",
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                value: teslim,
                activeColor: _gold,
                onChanged: (v) => setModal(() => teslim = v),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () async {
                  try {
                    final x =
                        await _picker.pickImage(source: ImageSource.gallery);
                    if (x == null) return;

                    final bytes = await x.readAsBytes();

                    // 1) UI preview hemen (setState modal dışında çalışmalı)
                    setState(() {
                      _onSekizUrun[i] = {
                        "ad": ad.text.trim(),
                        "tarif": tarif.text.trim(),
                        "gelAlFiyat": gelAl.text.trim(),
                        "goturFiyat": gotur.text.trim(),
                        "resimBytes": bytes,
                        "resimUrl": "",
                        "teslimat": teslim,
                      };
                    });

                    // 2) Storage upload -> https URL
                    final url = await _uploadImageBytesToStorage(bytes);

                    debugPrint("✅ UPLOAD OK url=$url");

                    // 3) Ürüne URL yaz
                    setState(() {
                      _onSekizUrun[i]["resimUrl"] = url;
                    });

                    if (mounted) Navigator.pop(c);
                  } catch (e) {
                    debugPrint("❌ Resim hatası: $e");
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _gold,
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: Text(
                  kIsWeb ? "RESİM SEÇ (WEB) VE YÜKLE" : "RESİM SEÇ VE YÜKLE",
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _inputWidget(TextEditingController c, String h, IconData ikon) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextField(
          controller: c,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            prefixIcon: Icon(ikon, color: _gold, size: 18),
            hintText: h,
            hintStyle: const TextStyle(color: Colors.white24),
            filled: true,
            fillColor: Colors.white10,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      );

  // ---------------- Modals ----------------

  void _odemePenceresiGoster(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF111111),
      builder: (c) => Container(
        padding: const EdgeInsets.all(30),
        child: const Text(
          "ÖDEME SİSTEMİ AKTİF",
          style: TextStyle(color: _gold),
        ),
      ),
    );
  }

  void _adresGirisPenceresi(BuildContext context) {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: const Color(0xFF111111),
        title: const Text("ADRES", style: TextStyle(color: Colors.white)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text("KAYDET"),
          ),
        ],
      ),
    );
  }

  // ---------------- Firestore ----------------

  Future<void> _vitriniMuhurleFirestore() async {
    final urunler = _onSekizUrun
        .where((u) => (u["ad"] ?? "").toString().trim().isNotEmpty)
        .toList();

    if (urunler.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Gönderilecek ürün yok. En az 1 ürün ekleyin.")),
      );
      return;
    }

    setState(() => _gonderiliyor = true);

    try {
      final fs = FirebaseFirestore.instance;
      final batch = fs.batch();

      // Etiketleme Mantığı: Tip ve Kategori
      final tip = _tipMetni();
      final kategori = _kategoriMetni();

      for (final u in urunler) {
        final fiyatNum = _parseFiyat((u["gelAlFiyat"] ?? "").toString()) ?? 0;
        final String resimUrl = (u["resimUrl"] ?? "").toString().trim();
        final String img =
            resimUrl.startsWith("http") ? resimUrl : _placeholderImg;

        final doc = fs.collection("urunler").doc();
        batch.set(doc, {
          "ad": (u["ad"] ?? "").toString().trim(),
          "tarif": (u["tarif"] ?? "").toString().trim(),
          "dukkan": dukkanAdi, // DÜKKAN ADI BURADA GİDİYOR
          "fiyat": fiyatNum,
          "gelAlFiyat": (u["gelAlFiyat"] ?? "").toString().trim(),
          "goturFiyat": (u["goturFiyat"] ?? "").toString().trim(),
          "teslimat": u["teslimat"] == true,
          "img": img,
          "tip": tip,
          "kategori": kategori, // ALT KATEGORİ BURADA GİDİYOR
          "onayDurumu": "onaylandi",
          "isActive": true,
          "kayitTarihi": FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ VİTRİN ARENA'DA CANLI!")),
      );
    } catch (e) {
      debugPrint("❌ Firestore hatası: $e");
    } finally {
      if (mounted) setState(() => _gonderiliyor = false);
    }
  }

  String _tipMetni() {
    if (seciliKategori == "EV LEZZETLERİ") return "Ev Lezzetleri";
    if (seciliKategori == "USTA ŞEFLER") return "Usta Sefler";
    return "Restoranlar";
  }

  String _kategoriMetni() {
    if (seciliKategori == "EV LEZZETLERİ") return seciliEvAltKategori;
    return seciliKategori;
  }

  num? _parseFiyat(String s) {
    final t = s.trim().replaceAll(",", ".");
    if (t.isEmpty) return null;
    return num.tryParse(t);
  }
}
