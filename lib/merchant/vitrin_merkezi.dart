import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:url_launcher/url_launcher.dart';
import '../main.dart'; // Merkezi hafıza erişimi

class VitrinMerkeziSayfasi extends StatefulWidget {
  const VitrinMerkeziSayfasi({super.key});

  @override
  State<VitrinMerkeziSayfasi> createState() => _VitrinMerkeziSayfasiState();
}

class _VitrinMerkeziSayfasiState extends State<VitrinMerkeziSayfasi> {
  // --- ARENA PREMIUM VERİ SETİ ---
  String _dukkanAdi = "TRÜF MANTARLI RİZOTTO";
  String _altMesaj = "Şefin Masterpiece Serisi";
  String _sefinNotu = "";
  String _sefHikayesi = "Mutfak yolculuğum 15 yıl önce başladı...";
  String _youtubeLink = "";
  List<XFile?> _galeriResimleri = List.generate(18, (index) => null);
  XFile? _profilResmi;
  List<String> _yorumlar = [
    "Ahmet Y.: 'Şefin sunumu tek kelimeyle harikaydı!'"
  ];

  // --- YOUTUBE MOTORU ---
  Future<void> _videoLinkiniAc() async {
    if (_youtubeLink.isEmpty) {
      _youtubeLinkEkle();
      return;
    }
    final Uri url = Uri.parse(_youtubeLink);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("YouTube Linki Açılamadı!")));
      }
    }
  }

  void _youtubeLinkEkle() {
    TextEditingController linkController =
        TextEditingController(text: _youtubeLink);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black.withOpacity(0.95),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 25,
            right: 25,
            top: 25),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.play_circle_fill,
                color: Colors.redAccent, size: 50),
            const SizedBox(height: 15),
            const Text("YOUTUBE LİNKİNİ MÜHÜRLE",
                style: TextStyle(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2)),
            const SizedBox(height: 20),
            TextField(
                controller: linkController,
                style: const TextStyle(color: Colors.white70),
                decoration: InputDecoration(
                    hintText: "YouTube linkini yapıştırın...",
                    filled: true,
                    fillColor: Colors.white10,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15)))),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  minimumSize: const Size(double.infinity, 50)),
              onPressed: () {
                setState(() => _youtubeLink = linkController.text);
                Navigator.pop(context);
              },
              child: const Text("VİTRİNE SABİTLE",
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Color(0xFFFFB300)),
        title: const Text("PREMIUM VİTRİN",
            style: TextStyle(
                color: Color(0xFFFFB300), letterSpacing: 3, fontSize: 14)),
        actions: [
          IconButton(
              onPressed: _notDefteriniAc,
              icon: const Icon(Icons.menu_book, color: Color(0xFFFFB300))),
          IconButton(
              onPressed: _ayarlariAc,
              icon: const Icon(Icons.edit_note,
                  color: Color(0xFFFFB300), size: 30)),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _premiumSefHeader(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _imzaYemekAlani(),
                  const SizedBox(height: 15),
                  _misafirYorumAlani(),
                  const SizedBox(height: 25),
                  Row(children: [
                    _yonetimButonu(
                        _youtubeLink.isEmpty ? "YouTube Ekle" : "YouTube İzle",
                        Icons.videocam,
                        Colors.redAccent,
                        _videoLinkiniAc),
                    const SizedBox(width: 15),
                    _yonetimButonu("Şef Hikayesi", Icons.person_search,
                        Colors.blueAccent, _sefTanitimAc),
                  ]),
                  const SizedBox(height: 30),
                  _bolumBasligi("ŞEFİN PORTFOLYOSU (18 Kare)"),
                  const SizedBox(height: 15),
                  _galeriIzgarasi(),
                  const SizedBox(height: 50),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- PREMİUM BİLEŞENLER ---
  Widget _galeriIzgarasi() => GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 6, crossAxisSpacing: 8, mainAxisSpacing: 8),
      itemCount: 18,
      itemBuilder: (c, i) => Stack(children: [
            GestureDetector(
                onTap: () async {
                  final r = await ImagePicker()
                      .pickImage(source: ImageSource.gallery);
                  if (r != null) setState(() => _galeriResimleri[i] = r);
                },
                child: Container(
                    decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white10),
                        image: _galeriResimleri[i] != null
                            ? DecorationImage(
                                image: kIsWeb
                                    ? NetworkImage(_galeriResimleri[i]!.path)
                                    : FileImage(File(_galeriResimleri[i]!.path))
                                        as ImageProvider,
                                fit: BoxFit.cover)
                            : null),
                    child: _galeriResimleri[i] == null
                        ? const Icon(Icons.add_a_photo,
                            color: Color(0xFFFFB300), size: 12)
                        : null)),
            if (_galeriResimleri[i] != null)
              Positioned(
                  right: -2,
                  top: -2,
                  child: InkWell(
                      onTap: () => setState(() => _galeriResimleri[i] = null),
                      child: const Icon(Icons.cancel,
                          color: Colors.redAccent, size: 18))),
          ]));

  Widget _premiumSefHeader() => Padding(
      padding: const EdgeInsets.all(20),
      child: Row(children: [
        GestureDetector(
            onTap: () async {
              final r =
                  await ImagePicker().pickImage(source: ImageSource.gallery);
              if (r != null) setState(() => _profilResmi = r);
            },
            child: CircleAvatar(
                radius: 40,
                backgroundColor: Colors.white10,
                backgroundImage: _profilResmi != null
                    ? (kIsWeb
                        ? NetworkImage(_profilResmi!.path)
                        : FileImage(File(_profilResmi!.path)) as ImageProvider)
                    : null,
                child: _profilResmi == null
                    ? const Icon(Icons.add_a_photo, color: Color(0xFFFFB300))
                    : null)),
        const SizedBox(width: 15),
        Expanded(
            child: SizedBox(
                height: 80,
                child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: 6,
                    itemBuilder: (c, i) => const Padding(
                        padding: EdgeInsets.only(right: 10),
                        child: CircleAvatar(
                            radius: 25,
                            backgroundColor: Colors.white10,
                            child: Icon(Icons.workspace_premium,
                                size: 15, color: Colors.white10))))))
      ]));

  Widget _yonetimButonu(String b, IconData i, Color r, VoidCallback e) =>
      Expanded(
          child: GestureDetector(
              onTap: e,
              child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  decoration: BoxDecoration(
                      color: r.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: r.withOpacity(0.3))),
                  child: Column(children: [
                    Icon(i, color: r, size: 28),
                    const SizedBox(height: 5),
                    Text(b,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold))
                  ]))));

  Widget _imzaYemekAlani() =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(_dukkanAdi,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold)),
        Text(_altMesaj,
            style: const TextStyle(color: Colors.white38, fontSize: 11))
      ]);

  Widget _misafirYorumAlani() => GestureDetector(
        onTap: _yorumYaz,
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.03),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.white10)),
          child: Column(children: [
            Row(children: [
              const Icon(Icons.star, color: Color(0xFFFFB300), size: 16),
              const SizedBox(width: 5),
              Text("4.9 (${_yorumlar.length} Yorum)",
                  style: const TextStyle(color: Colors.white54, fontSize: 11)),
              const Spacer(),
              const Icon(Icons.add_comment, color: Color(0xFFFFB300), size: 16)
            ]),
            const Divider(color: Colors.white10, height: 20),
            ..._yorumlar.take(1).map((y) => Text(y,
                style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontStyle: FontStyle.italic))),
          ]),
        ),
      );

  void _yorumYaz() {
    TextEditingController c = TextEditingController();
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.black.withOpacity(0.95),
        builder: (context) => Padding(
            padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 25,
                right: 25,
                top: 25),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Text("GURME YORUMU"),
              const SizedBox(height: 15),
              TextField(
                  controller: c,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white10,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15)))),
              const SizedBox(height: 20),
              ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFB300)),
                  onPressed: () {
                    if (c.text.isNotEmpty)
                      setState(() => _yorumlar.insert(0, "Gurme: '${c.text}'"));
                    Navigator.pop(context);
                  },
                  child: const Text("YORUMU GÖNDER",
                      style: TextStyle(color: Colors.black))),
              const SizedBox(height: 30)
            ])));
  }

  void _notDefteriniAc() {
    TextEditingController c = TextEditingController(text: _sefinNotu);
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.black.withOpacity(0.95),
        builder: (context) => Padding(
            padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 25,
                right: 25,
                top: 25),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Text("ŞEFİN NOT DEFTERİ"),
              const SizedBox(height: 15),
              TextField(
                  controller: c,
                  maxLines: 5,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white10,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15)))),
              const SizedBox(height: 20),
              ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFB300)),
                  onPressed: () {
                    setState(() => _sefinNotu = c.text);
                    Navigator.pop(context);
                  },
                  child: const Text("NOTU SAKLA",
                      style: TextStyle(color: Colors.black))),
              const SizedBox(height: 30)
            ])));
  }

  void _ayarlariAc() {
    TextEditingController ad = TextEditingController(text: _dukkanAdi);
    TextEditingController alt = TextEditingController(text: _altMesaj);
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.black.withOpacity(0.95),
        builder: (context) => Padding(
            padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 25,
                right: 25,
                top: 25),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Text("VİTRİN AYARLARI"),
              const SizedBox(height: 20),
              TextField(
                  controller: ad,
                  style: const TextStyle(color: Colors.white),
                  decoration:
                      const InputDecoration(labelText: "Dükkan / İmza Yemek")),
              const SizedBox(height: 15),
              TextField(
                  controller: alt,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: "Kısa Tanıtım")),
              const SizedBox(height: 20),
              ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFB300)),
                  onPressed: () {
                    setState(() {
                      _dukkanAdi = ad.text.toUpperCase();
                      _altMesaj = alt.text;
                    });
                    Navigator.pop(context);
                  },
                  child: const Text("VİTRİNİ GÜNCELLE")),
              const SizedBox(height: 30)
            ])));
  }

  void _sefTanitimAc() {
    TextEditingController h = TextEditingController(text: _sefHikayesi);
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.black.withOpacity(0.95),
        builder: (context) => Padding(
            padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 25,
                right: 25,
                top: 25),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Text("ŞEFİN HİKAYESİ"),
              const SizedBox(height: 15),
              TextField(
                  controller: h,
                  maxLines: 6,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white10,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15)))),
              const SizedBox(height: 20),
              ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent),
                  onPressed: () {
                    setState(() => _sefHikayesi = h.text);
                    Navigator.pop(context);
                  },
                  child: const Text("HİKAYEYİ KAYDET",
                      style: TextStyle(color: Colors.white))),
              const SizedBox(height: 30)
            ])));
  }

  Widget _bolumBasligi(String b) => Text(b,
      style: const TextStyle(
          color: Color(0xFFFFB300),
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 2));
}
