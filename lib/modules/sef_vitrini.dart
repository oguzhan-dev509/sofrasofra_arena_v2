import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sofrasofra_arena_v2/modules/sef_itibar_sayfasi.dart';

class SefVitrini extends StatelessWidget {
  const SefVitrini({super.key});

  static const gold = Color(0xFFFFB300);

  Query<Map<String, dynamic>> _sefQuery() {
    return FirebaseFirestore.instance
        .collection('urunler')
        .where('isActive', isEqualTo: true)
        .where('onayDurumu', isEqualTo: 'onaylandi')
        .where('tip', isEqualTo: 'Usta Sefler');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: gold),
        centerTitle: true,
        title: const Text(
          "GASTRONOMİ AKADEMİSİ",
          style: TextStyle(
            color: gold,
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _sefQuery().snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: gold));
          }

          if (snapshot.hasError) {
            final msg = snapshot.error.toString();
            final isPermissionDenied = msg.contains('permission-denied') ||
                msg.contains('PERMISSION_DENIED');

            return Center(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isPermissionDenied
                          ? Icons.lock_outline
                          : Icons.error_outline,
                      color: isPermissionDenied ? gold : Colors.redAccent,
                      size: 34,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      isPermissionDenied
                          ? "Erişim Engellendi (Firestore Rules)"
                          : "Bir hata oluştu",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      isPermissionDenied
                          ? "Bu ekranın açılması için Firestore Rules tarafında 'urunler' okumaya izin verilmesi gerekiyor."
                          : msg,
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(
              child: Text(
                "Arena'da henüz şef yok.",
                style: TextStyle(color: Colors.white38),
              ),
            );
          }

          return ListView.separated(
            itemCount: docs.length,
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
            separatorBuilder: (_, __) => const SizedBox(height: 26),
            itemBuilder: (context, i) {
              final data = docs[i].data();

              // ✅ En güvenlisi: Firestore’daki dukkanId alanı
              final String dukkanId =
                  (data['dukkanId'] ?? '').toString().trim();

              // ✅ Eğer dukkanId boşsa: img url içinden UID yakalamayı dene
              final rawImg = (data['img'] ?? '').toString();
              final img = _normalizeUrl(rawImg);
              final fallbackFromImg = _uidFromProfileUrl(img);

              final finalId = dukkanId.isNotEmpty ? dukkanId : fallbackFromImg;

              return _sefKart(
                context: context,
                data: data,
                dukkanId: finalId,
                imgUrl: img,
              );
            },
          );
        },
      ),
    );
  }

  Widget _sefKart({
    required BuildContext context,
    required Map<String, dynamic> data,
    required String dukkanId,
    required String imgUrl,
  }) {
    final ad = (data['dukkan'] ?? "Usta Şef").toString().trim();
    final uzman = (data['uzmanlik'] ?? data['kategori'] ?? "Gastronomi Uzmanı")
        .toString()
        .trim();

    final img = _safeHttpUrlOrEmpty(imgUrl);

    return GestureDetector(
      onTap: () {
        if (dukkanId.trim().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Bu şef için dukkanId bulunamadı."),
            ),
          );
          return;
        }

        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => SefItibarSayfasi(dukkanId: dukkanId)),
        );
      },
      child: Column(
        children: [
          Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: gold, width: 3),
              color: Colors.black,
            ),
            child: ClipOval(
              child: img.isEmpty
                  ? const Center(
                      child:
                          Icon(Icons.person, color: Colors.white38, size: 54),
                    )
                  : Image.network(
                      img,
                      key: ValueKey(img),
                      fit: BoxFit.cover,
                      gaplessPlayback: true,
                      errorBuilder: (context, error, stack) {
                        debugPrint("❌ Chef IMG error: $error | url=$img");
                        return const Center(
                          child: Icon(Icons.broken_image,
                              color: Colors.white38, size: 40),
                        );
                      },
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return const Center(
                          child: SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: gold),
                          ),
                        );
                      },
                    ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            ad.isEmpty ? "USTA ŞEF" : ad.toUpperCase(),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            uzman.isEmpty ? "Gastronomi Uzmanı" : uzman,
            style: const TextStyle(color: Colors.white38, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // URL içindeki satır sonu / boşluk / gizli karakterleri temizler
  String _normalizeUrl(String url) {
    // Tüm whitespace (space, \n, \t vs) kaldır
    final cleaned = url.replaceAll(RegExp(r'\s+'), '').trim();
    return cleaned;
  }

  String _safeHttpUrlOrEmpty(String url) {
    final u = url.trim();
    if (u.startsWith('http://') || u.startsWith('https://')) return u;
    return '';
  }

  // profiller%2F<UID>.jpg şeklinden UID yakalar
  String _uidFromProfileUrl(String url) {
    final u = url.trim();
    if (u.isEmpty) return '';
    final m = RegExp(r'profiller%2F([^\.%\/]+)\.jpg').firstMatch(u);
    return m?.group(1) ?? '';
  }
}
