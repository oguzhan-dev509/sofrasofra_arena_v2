import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// NOT: Eğer alttaki import hata verirse klasör yolunu kontrol et
// import '../theme/app_theme.dart';
import 'dukkan_detay_sayfasi.dart';

// 🎨 GÜVENLİ TEMA TANIMLARI (AppTheme hatasını önlemek için)
class AppTheme {
  static const Color gold = Color(0xFFFFB300);
  static const Color card = Color(0xFF111111);
  static const Color text = Colors.white;
}

class EvLezzetleriVitriniPage extends StatelessWidget {
  const EvLezzetleriVitriniPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("EV LEZZETLERİ",
            style: TextStyle(
                color: AppTheme.gold,
                fontSize: 16,
                fontWeight: FontWeight.bold)),
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.gold),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('urunler')
            .where('tip', isEqualTo: 'Ev Lezzetleri')
            .where('onayDurumu', isEqualTo: 'onaylandi')
            .orderBy('kayitTarihi', descending: true)
            .snapshots(),
        builder: (context, snap) {
          if (snap.hasError) {
            return _EmptyState(text: "❌ Hata: ${snap.error}");
          }
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: AppTheme.gold));
          }

          final docs = snap.data?.docs ?? [];
          if (docs.isEmpty) {
            return const _EmptyState(text: "Henüz ev lezzeti satıcısı yok.");
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final d = docs[i].data();
              final urunAd = (d['ad'] ?? '').toString();
              final dukkan = (d['dukkan'] ?? '').toString();
              final img = (d['img'] ?? '').toString();
              final kategori = (d['kategori'] ?? '').toString();

              final fiyatRaw = d['fiyat'];
              String fiyatText =
                  fiyatRaw?.toString() ?? d['gelAlFiyat']?.toString() ?? '';

              return _UrunCard(
                urunAd: urunAd,
                dukkan: dukkan,
                img: img,
                kategori: kategori,
                fiyatText: fiyatText,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DukkanDetaySayfasi(dukkanAdi: dukkan),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _UrunCard extends StatelessWidget {
  final String urunAd;
  final String dukkan;
  final String img;
  final String kategori;
  final String fiyatText;
  final VoidCallback onTap;

  const _UrunCard({
    required this.urunAd,
    required this.dukkan,
    required this.img,
    required this.kategori,
    required this.fiyatText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: AppTheme.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppTheme.gold.withOpacity(0.35)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(18)),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: (img.isEmpty || !img.startsWith('http'))
                    ? Container(
                        color: Colors.black26,
                        child: const Center(
                          child: Icon(Icons.image_not_supported,
                              color: AppTheme.gold),
                        ),
                      )
                    : Image.network(
                        img,
                        key: ValueKey(img),
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: Colors.black26,
                          child: const Center(
                            child:
                                Icon(Icons.broken_image, color: AppTheme.gold),
                          ),
                        ),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    urunAd.isEmpty ? dukkan : urunAd,
                    style: const TextStyle(
                      color: AppTheme.text,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (kategori.isNotEmpty)
                    Text(
                      kategori,
                      style: TextStyle(color: AppTheme.text.withOpacity(0.75)),
                    ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.store, color: AppTheme.gold, size: 14),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          dukkan,
                          style:
                              TextStyle(color: AppTheme.text.withOpacity(0.7)),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (fiyatText.isNotEmpty)
                        Text(
                          "$fiyatText ₺",
                          style: const TextStyle(
                            color: AppTheme.gold,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 🛡️ EKSİK OLABİLECEK _EmptyState WIDGET'I
class _EmptyState extends StatelessWidget {
  final String text;
  const _EmptyState({required this.text});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(20),
        margin: const EdgeInsets.all(25),
        decoration: BoxDecoration(
          color: AppTheme.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.info_outline, color: AppTheme.gold, size: 30),
            const SizedBox(height: 10),
            Text(text,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppTheme.text, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
