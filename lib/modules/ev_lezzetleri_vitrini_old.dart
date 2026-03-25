import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EvLezzetleriVitrini extends StatelessWidget {
  const EvLezzetleriVitrini({super.key});

  Query<Map<String, dynamic>> _query() {
    return FirebaseFirestore.instance
        .collection('urunler')
        .where('tip', isEqualTo: 'Ev Lezzetleri')
        .where('onayDurumu', isEqualTo: 'onaylandi')
        .where('isActive', isEqualTo: true);
  }

  bool _isHttp(String s) {
    final t = s.trim();
    return t.startsWith('http://') || t.startsWith('https://');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF5E6), // ✅ eski sıcak fildişi
      appBar: AppBar(
        title: const Text(
          "MAHALLE MUTFAĞI",
          style: TextStyle(
            color: Colors.brown,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.brown),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _query().snapshots(),
        builder: (context, snap) {
          if (snap.hasError) {
            return _info("Hata: ${snap.error}");
          }
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snap.data?.docs ?? [];
          if (docs.isEmpty) {
            return _info("Henüz ev lezzeti yok.");
          }

          return GridView.builder(
            padding: const EdgeInsets.all(15),
            itemCount: docs.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.7,
              crossAxisSpacing: 15,
              mainAxisSpacing: 15,
            ),
            itemBuilder: (context, index) {
              final d = docs[index].data();

              final dukkan = (d['dukkan'] ?? '').toString();
              final urunAd = (d['ad'] ?? '').toString(); // varsa kullanılır
              final aciklama = (d['aciklama'] ?? d['uzmanlik'] ?? '')
                  .toString(); // yoksa boş
              final img = (d['img'] ?? '').toString();
              final fiyat = (d['fiyat'] ?? d['gelAlFiyat'] ?? '').toString();

              return _evLezzetiKarti(
                baslik: urunAd.trim().isNotEmpty
                    ? urunAd
                    : (dukkan.isNotEmpty ? dukkan : "Ev Lezzeti"),
                aciklama: aciklama.trim().isNotEmpty
                    ? aciklama
                    : "Taze, günlük ve katkısız.",
                fiyat: fiyat.trim().isNotEmpty ? fiyat : "",
                img: img,
                imgOk: _isHttp(img),
              );
            },
          );
        },
      ),
    );
  }

  Widget _evLezzetiKarti({
    required String baslik,
    required String aciklama,
    required String fiyat,
    required String img,
    required bool imgOk,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
          )
        ],
      ),
      child: Column(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(25),
              child: imgOk
                  ? Image.network(
                      img.trim(),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _imgPlaceholder(),
                    )
                  : _imgPlaceholder(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  baslik,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  aciklama,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      fiyat.isNotEmpty ? "$fiyat TL" : "",
                      style: const TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Icon(Icons.favorite_border, color: Colors.red[300]),
                  ],
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _imgPlaceholder() {
    return Container(
      color: Colors.brown.withValues(alpha: 0.06),
      child: const Center(
        child: Icon(Icons.image, color: Colors.brown),
      ),
    );
  }

  Widget _info(String t) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          t,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.brown),
        ),
      ),
    );
  }
}
