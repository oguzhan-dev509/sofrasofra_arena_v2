import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class EvLezzetleriVitrini extends StatelessWidget {
  const EvLezzetleriVitrini({super.key});

  static const Color _bg = Color(0xFFFDF5E6);
  static const Color _brown = Colors.brown;

  Query<Map<String, dynamic>> _query() {
    return FirebaseFirestore.instance
        .collection('urunler')
        .where(FieldPath.documentId, isEqualTo: 'OZyXTfzobkNxoOE96xex');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: const Text(
          "MAHALLE MUTFAĞI",
          style: TextStyle(color: _brown, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: _brown),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _query().snapshots(),
        builder: (context, snap) {
          if (snap.hasError) {
            return _CenterInfo(
              icon: Icons.error_outline,
              title: "Hata",
              message: snap.error.toString(),
            );
          }
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snap.data?.docs ?? [];

          debugPrint("✅ EV DOC COUNT: ${docs.length}");
          if (docs.isNotEmpty) {
            final d = docs.first.data();
            debugPrint(
                "✅ EV FIRST DOC FIELDS: tip=${d['tip']} onayDurumu=${d['onayDurumu']} isActive=${d['isActive']}");
          }

          if (docs.isEmpty) {
            return const _CenterInfo(
              icon: Icons.info_outline,
              title: "Henüz ev lezzeti yok.",
              message:
                  "Firestore’da tip='Ev Lezzetleri', onayDurumu='onaylandi', isActive=true kaydı bulunamadı.",
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(15),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.72,
              crossAxisSpacing: 15,
              mainAxisSpacing: 15,
            ),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data();
              final ad = (data['ad'] ?? '').toString();
              final dukkan = (data['dukkan'] ?? '').toString();
              final img = (data['img'] ?? '').toString();

              return _EvKarti(ad: ad, dukkan: dukkan, img: img);
            },
          );
        },
      ),
    );
  }
}

class _EvKarti extends StatelessWidget {
  final String ad;
  final String dukkan;
  final String img;

  const _EvKarti({
    required this.ad,
    required this.dukkan,
    required this.img,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(22)),
              child: (img.trim().isEmpty)
                  ? Container(
                      color: Colors.black12,
                      child: const Center(
                          child:
                              Icon(Icons.image, size: 40, color: Colors.brown)),
                    )
                  : Image.network(
                      img,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.black12,
                        child: const Center(
                          child: Icon(Icons.broken_image,
                              size: 36, color: Colors.brown),
                        ),
                      ),
                    ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ad.isEmpty ? "İsimsiz Ürün" : ad,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  dukkan.isEmpty ? "-" : dukkan,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, color: Colors.brown),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}

class _CenterInfo extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _CenterInfo({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.brown, size: 34),
            const SizedBox(height: 10),
            Text(title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Colors.brown, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.brown, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
