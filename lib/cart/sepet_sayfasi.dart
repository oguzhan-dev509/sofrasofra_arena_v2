import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../orders/musteri_siparis_takip_sayfasi.dart';
import '../services/order_service.dart';

class SepetSayfasi extends StatefulWidget {
  const SepetSayfasi({super.key});

  @override
  State<SepetSayfasi> createState() => _SepetSayfasiState();
}

class _SepetSayfasiState extends State<SepetSayfasi> {
  final String userId = 'demo_user';
  bool _siparisOlusturuluyor = false;

  Stream<QuerySnapshot<Map<String, dynamic>>> _sepetStream() {
    return FirebaseFirestore.instance
        .collection('sepet')
        .doc(userId)
        .collection('items')
        .snapshots();
  }

  QueryDocumentSnapshot<Map<String, dynamic>>? _findDocByUrunId(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    String urunId,
  ) {
    for (final doc in docs) {
      final data = doc.data();
      final currentId =
          (data['urunId'] ?? data['productId'] ?? data['id'] ?? doc.id)
              .toString();
      if (currentId == urunId) return doc;
    }
    return null;
  }

  Future<void> _adetArtir(
    String urunId,
    int mevcutAdet,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) async {
    final targetDoc = _findDocByUrunId(docs, urunId);
    if (targetDoc == null) return;

    await FirebaseFirestore.instance
        .collection('sepet')
        .doc(userId)
        .collection('items')
        .doc(targetDoc.id)
        .update({
      'adet': mevcutAdet + 1,
      'addedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _adetAzalt(
    String urunId,
    int mevcutAdet,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) async {
    final targetDoc = _findDocByUrunId(docs, urunId);
    if (targetDoc == null) return;

    final docRef = FirebaseFirestore.instance
        .collection('sepet')
        .doc(userId)
        .collection('items')
        .doc(targetDoc.id);

    if (mevcutAdet <= 1) {
      await docRef.delete();
    } else {
      await docRef.update({
        'adet': mevcutAdet - 1,
        'addedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> _urunuSil(
    String urunId,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) async {
    final targetDoc = _findDocByUrunId(docs, urunId);
    if (targetDoc == null) return;

    await FirebaseFirestore.instance
        .collection('sepet')
        .doc(userId)
        .collection('items')
        .doc(targetDoc.id)
        .delete();
  }

  Future<void> _sepetiTemizle(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) async {
    final batch = FirebaseFirestore.instance.batch();

    for (final doc in docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }

  Future<void> _siparisiTamamla(
    BuildContext context,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) async {
    if (_siparisOlusturuluyor || docs.isEmpty) return;

    setState(() {
      _siparisOlusturuluyor = true;
    });

    try {
      final List<Map<String, dynamic>> items = docs.map((doc) {
        final data = doc.data();

        final urunId = _readString(
          data,
          ['urunId', 'productId', 'id'],
          fallback: doc.id,
        );

        final urunAdi = _readString(
          data,
          ['urunAdi', 'ad', 'isim', 'title', 'name', 'yemekAdi'],
          fallback: 'Ürün',
        );

        final dukkanAdi = _readString(
          data,
          ['dukkanAdi', 'dukkan', 'saticiAdi', 'sellerName', 'magazaAdi'],
          fallback: 'Dükkan',
        );

        final kategori = _readString(
          data,
          ['kategori', 'category'],
          fallback: 'Ev Lezzetleri',
        );

        final img = _readString(
          data,
          ['img', 'imageUrl', 'foto', 'gorselUrl'],
        );

        final fiyat = _asDouble(
          data['fiyat'] ??
              data['price'] ??
              data['birimFiyat'] ??
              data['unitPrice'] ??
              0,
        );

        final adet = _asInt(
          data['adet'] ?? data['quantity'] ?? data['qty'] ?? 1,
        );

        final saticiId = _readString(
          data,
          ['saticiId', 'sellerId', 'dukkanId', 'merchantId'],
          fallback: dukkanAdi
              .toLowerCase()
              .replaceAll('ı', 'i')
              .replaceAll('ş', 's')
              .replaceAll('ğ', 'g')
              .replaceAll('ç', 'c')
              .replaceAll('ö', 'o')
              .replaceAll('ü', 'u')
              .replaceAll(' ', '_'),
        );

        return {
          'urunId': urunId,
          'urunAdi': urunAdi,
          'dukkanAdi': dukkanAdi,
          'kategori': kategori,
          'img': img,
          'fiyat': fiyat,
          'adet': adet,
          'saticiId': saticiId,
        };
      }).toList();

      final sonuc = await OrderService.siparisOlustur(
        kullaniciId: userId,
        items: items,
        odemeDurumu: 'beklemede',
        odemeYontemi: 'kapida_odeme',
        paraBirimi: 'TRY',
        adres: 'Kadıköy / İstanbul',
        teslimatTipi: 'standart',
      );

      await _sepetiTemizle(docs);

      if (!mounted) return;

      final siparisNo = (sonuc['siparisNo'] ?? '').toString();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF1E1E1E),
          content: Text(
            siparisNo.isNotEmpty
                ? 'Sipariş oluşturuldu: $siparisNo'
                : 'Sipariş başarıyla oluşturuldu.',
            style: const TextStyle(color: Colors.white),
          ),
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const MusteriSiparisTakipSayfasi(),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red.shade700,
          content: Text(
            'Sipariş oluşturulamadı: $e',
            style: const TextStyle(color: Colors.white),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _siparisOlusturuluyor = false;
        });
      }
    }
  }

  double _toplamHesapla(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    double toplam = 0;

    for (final doc in docs) {
      final data = doc.data();
      final fiyat = _asDouble(
        data['fiyat'] ??
            data['price'] ??
            data['birimFiyat'] ??
            data['unitPrice'] ??
            0,
      );
      final adet = _asInt(
        data['adet'] ?? data['quantity'] ?? data['qty'] ?? 0,
      );
      toplam += fiyat * adet;
    }

    return toplam;
  }

  double _asDouble(dynamic value) {
    if (value == null) return 0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();
    if (value is String) {
      return double.tryParse(value.replaceAll(',', '.')) ?? 0;
    }
    return 0;
  }

  int _asInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  String _readString(
    Map<String, dynamic> data,
    List<String> keys, {
    String fallback = '',
  }) {
    for (final key in keys) {
      final value = data[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString().trim();
      }
    }
    return fallback;
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _sortDocs(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final sorted = [...docs];
    sorted.sort((a, b) {
      final aData = a.data();
      final bData = b.data();

      final aTs = aData['addedAt'];
      final bTs = bData['addedAt'];

      DateTime aTime = DateTime.fromMillisecondsSinceEpoch(0);
      DateTime bTime = DateTime.fromMillisecondsSinceEpoch(0);

      if (aTs is Timestamp) aTime = aTs.toDate();
      if (bTs is Timestamp) bTime = bTs.toDate();

      return bTime.compareTo(aTime);
    });
    return sorted;
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
            final err = snapshot.error?.toString() ?? 'Bilinmeyen hata';
            debugPrint('❌ SEPET STREAM ERROR: $err');

            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Sepet yüklenirken hata oluştu.\n\n$err',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
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

          final docs = _sortDocs(snapshot.data?.docs ?? []);

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

                    final urunId = _readString(
                      item,
                      ['urunId', 'productId', 'id'],
                      fallback: docs[index].id,
                    );

                    final urunAdi = _readString(
                      item,
                      ['urunAdi', 'ad', 'isim', 'title', 'name', 'yemekAdi'],
                      fallback: 'Ürün',
                    );

                    final dukkanAdi = _readString(
                      item,
                      [
                        'dukkanAdi',
                        'dukkan',
                        'saticiAdi',
                        'sellerName',
                        'magazaAdi'
                      ],
                    );

                    final kategori = _readString(
                      item,
                      ['kategori', 'category'],
                    );

                    final img = _readString(
                      item,
                      ['img', 'imageUrl', 'foto', 'gorselUrl'],
                    );

                    final fiyat = _asDouble(
                      item['fiyat'] ??
                          item['price'] ??
                          item['birimFiyat'] ??
                          item['unitPrice'] ??
                          0,
                    );

                    final adet = _asInt(
                      item['adet'] ?? item['quantity'] ?? item['qty'] ?? 1,
                    );

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
                                        onTap: () =>
                                            _adetAzalt(urunId, adet, docs),
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
                                        onTap: () =>
                                            _adetArtir(urunId, adet, docs),
                                      ),
                                      const Spacer(),
                                      IconButton(
                                        onPressed: () =>
                                            _urunuSil(urunId, docs),
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
                          onPressed: _siparisOlusturuluyor
                              ? null
                              : () => _siparisiTamamla(context, docs),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFFB300),
                            foregroundColor: Colors.black,
                            disabledBackgroundColor: Colors.grey.shade700,
                            disabledForegroundColor: Colors.white70,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: _siparisOlusturuluyor
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.4,
                                    color: Colors.black,
                                  ),
                                )
                              : const Text(
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
