import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/order_service.dart';

class SepetSayfasi extends StatelessWidget {
  const SepetSayfasi({super.key});

  final String userId = 'demo_user';

  Stream<QuerySnapshot<Map<String, dynamic>>> _sepetStream() {
    return FirebaseFirestore.instance
        .collection('sepet')
        .doc(userId)
        .collection('items')
        .orderBy('addedAt', descending: true)
        .snapshots();
  }

  Future<void> _adetArtir(String urunId, int mevcutAdet) async {
    await FirebaseFirestore.instance
        .collection('sepet')
        .doc(userId)
        .collection('items')
        .doc(urunId)
        .update({
      'adet': mevcutAdet + 1,
      'addedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _adetAzalt(String urunId, int mevcutAdet) async {
    final docRef = FirebaseFirestore.instance
        .collection('sepet')
        .doc(userId)
        .collection('items')
        .doc(urunId);

    if (mevcutAdet <= 1) {
      await docRef.delete();
    } else {
      await docRef.update({
        'adet': mevcutAdet - 1,
        'addedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> _urunuSil(String urunId) async {
    await FirebaseFirestore.instance
        .collection('sepet')
        .doc(userId)
        .collection('items')
        .doc(urunId)
        .delete();
  }

  double _toplamHesapla(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    double toplam = 0;

    for (final doc in docs) {
      final data = doc.data();
      final fiyat = (data['fiyat'] ?? 0).toDouble();
      final adet = (data['adet'] ?? 0).toInt();
      toplam += fiyat * adet;
    }

    return toplam;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          'Sepetim',
          style: TextStyle(
            color: Color(0xFFFFB300),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Color(0xFFFFB300)),
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _sepetStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Sepet hatası: ${snapshot.error}',
                  style: const TextStyle(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xFFFFB300),
              ),
            );
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return const Center(
              child: Text(
                'Sepetiniz şu anda boş.',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
            );
          }

          final toplam = _toplamHesapla(docs);

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final item = docs[index].data();

                    final urunId =
                        (item['urunId'] ?? docs[index].id).toString();
                    final urunAdi = (item['urunAdi'] ?? 'Ürün').toString();
                    final dukkanAdi = (item['dukkanAdi'] ?? '').toString();
                    final kategori = (item['kategori'] ?? '').toString();
                    final img = (item['img'] ?? '').toString();
                    final fiyat = (item['fiyat'] ?? 0).toDouble();
                    final adet = (item['adet'] ?? 1).toInt();

                    return Card(
                      color: const Color(0xFF161616),
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: const BorderSide(
                          color: Color(0x33FFB300),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: img.isNotEmpty
                                  ? Image.network(
                                      img,
                                      width: 86,
                                      height: 86,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                        return Container(
                                          width: 86,
                                          height: 86,
                                          color: Colors.grey.shade800,
                                          child: const Icon(
                                            Icons.image_not_supported,
                                            color: Colors.white54,
                                          ),
                                        );
                                      },
                                    )
                                  : Container(
                                      width: 86,
                                      height: 86,
                                      color: Colors.grey.shade800,
                                      child: const Icon(
                                        Icons.fastfood,
                                        color: Colors.white54,
                                      ),
                                    ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    urunAdi,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  if (dukkanAdi.isNotEmpty)
                                    Text(
                                      dukkanAdi,
                                      style: const TextStyle(
                                        color: Color(0xFFFFB300),
                                        fontSize: 13,
                                      ),
                                    ),
                                  if (kategori.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      kategori,
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 8),
                                  Text(
                                    '${fiyat.toStringAsFixed(0)} ₺',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      _adetButonu(
                                        icon: Icons.remove,
                                        onTap: () => _adetAzalt(urunId, adet),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                        ),
                                        child: Text(
                                          adet.toString(),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      _adetButonu(
                                        icon: Icons.add,
                                        onTap: () => _adetArtir(urunId, adet),
                                      ),
                                      const Spacer(),
                                      IconButton(
                                        onPressed: () => _urunuSil(urunId),
                                        icon: const Icon(
                                          Icons.delete_outline,
                                          color: Colors.redAccent,
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
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
                decoration: const BoxDecoration(
                  color: Color(0xFF111111),
                  border: Border(
                    top: BorderSide(color: Color(0x22FFB300)),
                  ),
                ),
                child: SafeArea(
                  top: false,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Toplam',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${toplam.toStringAsFixed(0)} ₺',
                            style: const TextStyle(
                              color: Color(0xFFFFB300),
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: () async {
                            try {
                              final siparisId =
                                  await OrderService.siparisOlustur(
                                userId: 'demo_user',
                                musteriAdSoyad: 'Mehmet Hazret',
                                adres: 'Kadıköy / İstanbul',
                                telefon: '0555 555 55 55',
                                odemeYontemi: 'kapida_odeme',
                              );

                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Sipariş oluşturuldu: $siparisId',
                                    ),
                                  ),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Sipariş oluşturulamadı: $e',
                                    ),
                                  ),
                                );
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFFB300),
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text(
                            'Siparişi Tamamla',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _adetButonu({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: const Color(0x22FFB300),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0x66FFB300)),
        ),
        child: Icon(
          icon,
          color: const Color(0xFFFFB300),
          size: 18,
        ),
      ),
    );
  }
}
