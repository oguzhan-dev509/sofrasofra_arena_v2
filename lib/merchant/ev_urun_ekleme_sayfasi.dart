import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class EvLezzetleriVitrini extends StatelessWidget {
  const EvLezzetleriVitrini({super.key});

  Query<Map<String, dynamic>> _query() {
    return FirebaseFirestore.instance
        .collection('urunler')
        .where('tip', isEqualTo: 'Ev Lezzetleri')
        .where('onayDurumu', isEqualTo: 'onaylandi')
        .where('isActive', isEqualTo: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF5E6),
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
            return _centerText("❌ Hata: ${snap.error}");
          }
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snap.data?.docs ?? [];

          // DEBUG: kaç kayıt geliyor görelim
          if (kDebugMode) {
            debugPrint("✅ EV DOC COUNT: ${docs.length}");
            for (final d in docs) {
              debugPrint("✅ EV DOC: ${d.id} => ${d.data()}");
            }
          }

          if (docs.isEmpty) {
            return _centerText(
              "Henüz ev lezzeti yok.\n\nFirestore’da tip='Ev Lezzetleri', onayDurumu='onaylandi', isActive=true kayıt bulunamadı.",
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(15),
            itemCount: docs.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.70,
              crossAxisSpacing: 15,
              mainAxisSpacing: 15,
            ),
            itemBuilder: (context, index) {
              final data = docs[index].data();

              final ad = (data['ad'] ?? '').toString().trim();
              final dukkan = (data['dukkan'] ?? '').toString().trim();
              final img = (data['img'] ?? '').toString().trim();

              final baslik = ad.isNotEmpty
                  ? ad
                  : (dukkan.isNotEmpty ? dukkan : "Ev Lezzeti");
              final alt = dukkan.isNotEmpty ? dukkan : "Ev yapımı";

              return _EvLezzetiKarti(
                baslik: baslik,
                alt: alt,
                imgUrl: img,
              );
            },
          );
        },
      ),
    );
  }

  Widget _centerText(String text) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.brown),
        ),
      ),
    );
  }
}

class _EvLezzetiKarti extends StatelessWidget {
  final String baslik;
  final String alt;
  final String imgUrl;

  const _EvLezzetiKarti({
    required this.baslik,
    required this.alt,
    required this.imgUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(25),
              child: _imageOrPlaceholder(imgUrl),
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
                const SizedBox(height: 4),
                Text(
                  alt,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
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

  Widget _imageOrPlaceholder(String url) {
    final safe = url.trim();
    final valid = safe.startsWith('http://') || safe.startsWith('https://');

    if (!valid) {
      return Container(
        color: Colors.black12,
        child: const Center(
          child: Icon(Icons.image, size: 40, color: Colors.brown),
        ),
      );
    }

    return Image.network(
      safe,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) {
        return Container(
          color: Colors.black12,
          child: const Center(
            child: Icon(Icons.broken_image, size: 40, color: Colors.brown),
          ),
        );
      },
    );
  }
}
