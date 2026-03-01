import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UrunEklemeSayfasi extends StatefulWidget {
  const UrunEklemeSayfasi({super.key});

  @override
  State<UrunEklemeSayfasi> createState() => _UrunEklemeSayfasiState();
}

class _UrunEklemeSayfasiState extends State<UrunEklemeSayfasi> {
  final TextEditingController _adController = TextEditingController();
  final TextEditingController _dukkanController = TextEditingController();
  final TextEditingController _fiyatController = TextEditingController();
  final TextEditingController _videoController = TextEditingController();

  // 📸 Temsili galeri (şimdilik url listesi)
  List<String> secilenFotograflar = [];

  bool _yukleniyor = false;

  @override
  void dispose() {
    _adController.dispose();
    _dukkanController.dispose();
    _fiyatController.dispose();
    _videoController.dispose();
    super.dispose();
  }

  void _dosyaGezgininiAc() {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text("Masaüstü Klasör Erişimi Sağlanıyor... (Max 18 Fotoğraf)"),
    ));

    setState(() {
      secilenFotograflar = [
        "https://images.unsplash.com/photo-1543339308-43e59d6b73a6",
        "https://images.unsplash.com/photo-1601063411135-2623090fb585",
        "https://images.unsplash.com/photo-1519676867240-f031ee04a113",
      ];
    });
  }

  void _videoLinkGir() {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: const Color(0xFF111111),
        title: const Text(
          "YouTube Video URL",
          style: TextStyle(color: Colors.white, fontSize: 14),
        ),
        content: TextField(
          controller: _videoController,
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text("KAYDET"),
          ),
        ],
      ),
    );
  }

  Future<void> _pazaraSur() async {
    final ad = _adController.text.trim();
    final fiyatText = _fiyatController.text.trim();
    final videoUrl = _videoController.text.trim();

    // ✅ Artık dükkan elle girilmeyecek, o yüzden dukkan zorunluluğunu kaldırdık
    if (ad.isEmpty || fiyatText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lütfen ürün adı ve fiyat girin.")),
      );
      return;
    }

    final fiyat = num.tryParse(fiyatText.replaceAll(",", "."));
    if (fiyat == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Fiyat sayısal olmalı. Örn: 150")),
      );
      return;
    }

    final kapakGorsel = secilenFotograflar.isNotEmpty
        ? secilenFotograflar.first
        : "https://images.unsplash.com/photo-1546069901-ba9599a7e63c?auto=format&fit=crop&w=1200&q=60";

    setState(() => _yukleniyor = true);

    try {
      // ✅ UID al
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception(
            "Kullanıcı oturumu yok. (Anon login çalışmıyor olabilir)");
      }
      final uid = user.uid;

      // ✅ dukkanlar/{uid} oku, yoksa oluştur
      final dukkanRef =
          FirebaseFirestore.instance.collection('dukkanlar').doc(uid);
      final dukkanSnap = await dukkanRef.get();

      Map<String, dynamic> dukkanData;

      if (!dukkanSnap.exists) {
        // MVP: İlk kurulum (şimdilik sabit)
        dukkanData = {
          "dukkanAdi": "SOFRASOFRA.COM",
          "sehir": "İSTANBUL",
          "ilce": "KADIKÖY",
          "isActive": true,
          "createdAt": FieldValue.serverTimestamp(),
        };
        await dukkanRef.set(dukkanData);
      } else {
        dukkanData = dukkanSnap.data() as Map<String, dynamic>;
      }

      final dukkanAdi =
          (dukkanData["dukkanAdi"] ?? "SOFRASOFRA.COM").toString();
      final sehir = (dukkanData["sehir"] ?? "İSTANBUL").toString();
      final ilce = (dukkanData["ilce"] ?? "KADIKÖY").toString();

      // ✅ Ürünü root /urunler koleksiyonuna yaz
      await FirebaseFirestore.instance.collection('urunler').add({
        // Ürün temel
        "ad": ad,
        "fiyat": fiyat,
        "img": kapakGorsel,
        "videoUrl": videoUrl,
        "galeri": secilenFotograflar,

        // ✅ Dükkan bağı
        "dukkanId": uid,
        "dukkan": dukkanAdi,

        // Segment/Kategori
        "tip": "Ev Lezzetleri",
        "kategori": "EV LEZZETLERİ",

        // ✅ Lokasyon (dukkan dokümanından)
        "sehir": sehir,
        "ilce": ilce,

        // ✅ Yayın / Onay
        "isActive": true,
        "onayDurumu": "onaylandi",

        // ✅ Zaman (vitrin sıralaması için kritik)
        "kayitTarihi": FieldValue.serverTimestamp(),
        "createdAt": FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Ürün Arena'ya gönderildi!")),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Firestore hata: $e")),
      );
    } finally {
      if (mounted) setState(() => _yukleniyor = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fotoSayisi = secilenFotograflar.length;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          "PROFESYONEL VİTRİN YÖNETİMİ",
          style: TextStyle(color: Color(0xFFFFB300), fontSize: 13),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25),
        child: Column(
          children: [
            Row(
              children: [
                _medyaKutusu(
                  "FOTOĞRAF EKLE ($fotoSayisi/18)",
                  Icons.add_photo_alternate,
                  Colors.blue,
                  _dosyaGezgininiAc,
                ),
                const SizedBox(width: 15),
                _medyaKutusu(
                  "YOUTUBE LİNKİ",
                  Icons.play_circle_fill,
                  Colors.red,
                  _videoLinkGir,
                ),
              ],
            ),
            const SizedBox(height: 30),
            _input("ÜRÜN / BAŞLIK", _adController),
            _input("FİYAT", _fiyatController),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _yukleniyor ? null : _pazaraSur,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFB300),
                ),
                child: _yukleniyor
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text(
                        "ARENA'DA CANLI YAYINA AL",
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

  Widget _medyaKutusu(String t, IconData i, Color c, VoidCallback o) {
    return Expanded(
      child: InkWell(
        onTap: o,
        child: Container(
          height: 100,
          decoration: BoxDecoration(
            color: const Color(0xFF0A0A0A),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: c.withOpacity(0.3)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(i, color: c, size: 32),
              const SizedBox(height: 8),
              Text(
                t,
                style: TextStyle(
                  color: c,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
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
      ),
    );
  }
}
