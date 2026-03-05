import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SefItibarSayfasi extends StatelessWidget {
  final String dukkanId;
  const SefItibarSayfasi({super.key, required this.dukkanId});

  static const gold = Color(0xFFFFB300);

  @override
  Widget build(BuildContext context) {
    final safeDukkanId = dukkanId.trim();

    if (safeDukkanId.isEmpty) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text(
            "Hata: dukkanId boş geldi.",
            style: TextStyle(color: Colors.white70),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: gold),
        title: const Text(
          "ŞEF İTİBAR PROFİLİ",
          style: TextStyle(color: gold, fontSize: 13),
        ),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('urunler')
            .where('tip', isEqualTo: 'Usta Sefler')
            .where('isActive', isEqualTo: true)
            .where('onayDurumu', isEqualTo: 'onaylandi')
            .where('dukkanId', isEqualTo: safeDukkanId)
            .limit(1)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: gold));
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                "Hata: ${snapshot.error}",
                style: const TextStyle(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
            );
          }

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(
              child: Text(
                "Şef profili bulunamadı.",
                style: TextStyle(color: Colors.white38),
              ),
            );
          }

          final data = docs.first.data();

          final String ad = (data['dukkan'] ?? "Usta Şef").toString().trim();
          final String uzman =
              (data['uzmanlik'] ?? "Gastronomi Uzmanı").toString().trim();

          // ✅ newline/space temizliği
          final String rawResim = (data['img'] ?? "").toString();
          final String resim = rawResim.replaceAll(RegExp(r'\s+'), '').trim();
          debugPrint("🧾 PROFIL IMG = $resim");

          final String puan = (data['itibar_puani'] ?? "4.9").toString();
          final String mezun = (data['mezun_sayisi'] ?? "12").toString();
          final String muhur = (data['muhur_sayisi'] ?? "24").toString();

          return SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 30),
                _ustProfil(ad, uzman, resim),
                const SizedBox(height: 30),
                _metrikSistemi(puan, mezun, muhur),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                  child: Divider(color: Colors.white10),
                ),
                const Text(
                  "🎓 AKADEMİ MÜFREDATI",
                  style: TextStyle(
                    color: gold,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 20),
                _mufredatCiz(
                    ["Osmanlı", "Tabak Tasarım", "Dünya Mutf.", "Maliyet"]),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                  child: Divider(color: Colors.white10),
                ),
                const Padding(
                  padding: EdgeInsets.only(left: 25, bottom: 15),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "ŞEFİN İMZA TABAKLARI",
                      style: TextStyle(
                        color: gold,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ),
                _sefTabaklariListesi(safeDukkanId),
                const SizedBox(height: 40),
                _sefHikayesi(ad, uzman),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  // 🍛 DİNAMİK YEMEK LİSTELEYİCİ
  Widget _sefTabaklariListesi(String sId) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('urunler')
          .where('dukkanId', isEqualTo: sId)
          .where('tip', isNotEqualTo: 'Usta Sefler')
          .orderBy('tip') // ✅ isNotEqualTo için daha stabil
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(height: 160);
        }
        if (snapshot.hasError) return const SizedBox();

        final yemekler = snapshot.data?.docs ?? [];
        if (yemekler.isEmpty) {
          return const Padding(
            padding: EdgeInsets.only(left: 25),
            child: Text(
              "Şefin henüz eklenmiş imza tabağı bulunmuyor.",
              style: TextStyle(color: Colors.white24, fontSize: 11),
            ),
          );
        }

        return SizedBox(
          height: 160,
          child: ListView.builder(
            padding: const EdgeInsets.only(left: 25),
            scrollDirection: Axis.horizontal,
            itemCount: yemekler.length,
            itemBuilder: (context, index) {
              final yemek = yemekler[index].data();
              final url = (yemek['img'] ?? "")
                  .toString()
                  .replaceAll(RegExp(r'\s+'), '')
                  .trim();

              return _OzelTabak(
                isim: (yemek['ad'] ?? "İmza Tabağı").toString(),
                url: url,
              );
            },
          ),
        );
      },
    );
  }

  Widget _metrikSistemi(String p, String m, String h) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _metrikBirim("İTİBAR", p, Icons.star),
        _metrikBirim("MEZUN", m, Icons.school),
        _metrikBirim("MÜHÜR", h, Icons.workspace_premium),
      ],
    );
  }

  Widget _metrikBirim(String l, String v, IconData i) {
    return Column(
      children: [
        Icon(i, color: gold, size: 20),
        const SizedBox(height: 8),
        Text(
          v,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        Text(l, style: const TextStyle(color: Colors.white38, fontSize: 10)),
      ],
    );
  }

  Widget _mufredatCiz(List<String> l) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.center,
      children: l
          .map(
            (e) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF111111),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                e.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  // ✅ PROFİL AVATAR
  Widget _ustProfil(String ad, String uzman, String resim) {
    final img = resim.trim();
    final safeImg = _safeHttpUrlOrEmpty(img);

    return Column(
      children: [
        Container(
          width: 124,
          height: 124,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: gold, width: 3),
          ),
          child: ClipOval(
            child: safeImg.isEmpty
                ? const Center(
                    child: Icon(Icons.person, color: Colors.white38, size: 54),
                  )
                : Image.network(
                    safeImg,
                    key: ValueKey(safeImg),
                    fit: BoxFit.cover,
                    gaplessPlayback: true,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return const Center(
                        child: SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: gold,
                          ),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      debugPrint("❌ IMG LOAD ERROR: $error | url=$safeImg");
                      return const Center(
                        child: Icon(Icons.broken_image,
                            color: Colors.white38, size: 40),
                      );
                    },
                  ),
          ),
        ),
        const SizedBox(height: 15),
        Text(
          ad,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        Text(
          uzman,
          style: const TextStyle(color: Colors.white38, fontSize: 13),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  String _safeHttpUrlOrEmpty(String url) {
    final u = url.trim();
    if (u.startsWith('http://') || u.startsWith('https://')) return u;
    return '';
  }

  Widget _sefHikayesi(String ad, String uzman) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Text(
        "$ad, Arena'nın mühürlü şeflerinden biridir. $uzman uzmanlık alanıdır.",
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.white70, fontSize: 13),
      ),
    );
  }
}

class _OzelTabak extends StatelessWidget {
  final String isim;
  final String url;
  const _OzelTabak({required this.isim, required this.url});

  @override
  Widget build(BuildContext context) {
    final u = url.trim();
    final safeU =
        (u.startsWith('http://') || u.startsWith('https://')) ? u : '';

    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: safeU.isEmpty
                ? Container(
                    height: 100,
                    width: 160,
                    color: Colors.white10,
                    child: const Icon(Icons.image, color: Colors.white24),
                  )
                : Image.network(
                    safeU,
                    height: 100,
                    width: 160,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 100,
                      width: 160,
                      color: Colors.white10,
                      child:
                          const Icon(Icons.broken_image, color: Colors.white24),
                    ),
                  ),
          ),
          const SizedBox(height: 8),
          Text(
            isim,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.white70,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
