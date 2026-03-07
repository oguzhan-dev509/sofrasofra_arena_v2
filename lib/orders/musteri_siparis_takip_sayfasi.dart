import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class MusteriSiparisTakipSayfasi extends StatelessWidget {
  const MusteriSiparisTakipSayfasi({super.key});

  final String userId = 'demo_user';

  Stream<QuerySnapshot<Map<String, dynamic>>> _siparislerStream() {
    return FirebaseFirestore.instance
        .collection('siparisler')
        .where('kullaniciId', isEqualTo: userId)
        .snapshots();
  }

  Color _durumRenk(String durum) {
    switch (durum) {
      case 'alindi':
        return Colors.blueGrey;
      case 'hazirlaniyor':
        return Colors.orange;
      case 'yolda':
        return Colors.blue;
      case 'teslim_edildi':
        return Colors.green;
      case 'iptal':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _durumYazi(String durum) {
    switch (durum) {
      case 'alindi':
        return 'Sipariş Alındı';
      case 'hazirlaniyor':
        return 'Hazırlanıyor';
      case 'yolda':
        return 'Yolda';
      case 'teslim_edildi':
        return 'Teslim Edildi';
      case 'iptal':
        return 'İptal Edildi';
      default:
        return durum;
    }
  }

  IconData _durumIcon(String durum) {
    switch (durum) {
      case 'alindi':
        return Icons.receipt_long;
      case 'hazirlaniyor':
        return Icons.restaurant;
      case 'yolda':
        return Icons.delivery_dining;
      case 'teslim_edildi':
        return Icons.check_circle;
      case 'iptal':
        return Icons.cancel;
      default:
        return Icons.info_outline;
    }
  }

  String _siparisTarihi(dynamic createdAt) {
    if (createdAt is! Timestamp) return 'Tarih yok';
    final dt = createdAt.toDate();
    return '${dt.day.toString().padLeft(2, '0')}.'
        '${dt.month.toString().padLeft(2, '0')}.'
        '${dt.year} '
        '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          'Sipariş Takibi',
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
        stream: _siparislerStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Sipariş hatası: ${snapshot.error}',
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
                'Henüz siparişiniz bulunmuyor.',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final siparisDoc = docs[index];
              final data = siparisDoc.data();

              final genelDurum =
                  (data['genelDurum'] ?? data['durum'] ?? 'alindi').toString();
              final toplamTutar =
                  ((data['toplamTutar'] ?? 0) as num).toDouble();
              final adres = (data['adres'] ?? '').toString();
              final telefon = (data['telefon'] ?? '').toString();
              final odemeYontemi = (data['odemeYontemi'] ?? '').toString();
              final createdAt = data['createdAt'];
              final musteriAdSoyad = (data['musteriAdSoyad'] ?? '').toString();

              return Card(
                color: const Color(0xFF161616),
                margin: const EdgeInsets.only(bottom: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: Color(0x33FFB300)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Sipariş No: ${siparisDoc.id}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: _durumRenk(genelDurum)
                                  .withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                color: _durumRenk(genelDurum),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _durumIcon(genelDurum),
                                  size: 16,
                                  color: _durumRenk(genelDurum),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _durumYazi(genelDurum),
                                  style: TextStyle(
                                    color: _durumRenk(genelDurum),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      if (musteriAdSoyad.isNotEmpty)
                        Text(
                          'Müşteri: $musteriAdSoyad',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                      const SizedBox(height: 6),
                      Text(
                        'Tarih: ${_siparisTarihi(createdAt)}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Adres: $adres',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Telefon: $telefon',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Ödeme: $odemeYontemi',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Divider(color: Color(0x22FFFFFF)),
                      const SizedBox(height: 8),
                      const Text(
                        'Satıcı Siparişleri',
                        style: TextStyle(
                          color: Color(0xFFFFB300),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                        stream: FirebaseFirestore.instance
                            .collection('siparisler')
                            .doc(siparisDoc.id)
                            .collection('saticiSiparisleri')
                            .snapshots(),
                        builder: (context, saticiSnapshot) {
                          if (saticiSnapshot.hasError) {
                            return Text(
                              'Satıcı siparişleri okunamadı: ${saticiSnapshot.error}',
                              style: const TextStyle(color: Colors.white54),
                            );
                          }

                          if (!saticiSnapshot.hasData) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child: CircularProgressIndicator(
                                color: Color(0xFFFFB300),
                              ),
                            );
                          }

                          final saticiDocs = saticiSnapshot.data!.docs;

                          if (saticiDocs.isEmpty) {
                            return const Text(
                              'Satıcı siparişi bulunamadı.',
                              style: TextStyle(color: Colors.white54),
                            );
                          }

                          return Column(
                            children: saticiDocs.map((saticiDoc) {
                              final saticiData = saticiDoc.data();
                              final dukkanAdi =
                                  (saticiData['dukkanAdi'] ?? '').toString();
                              final durum =
                                  (saticiData['durum'] ?? 'alindi').toString();
                              final altToplam =
                                  ((saticiData['altToplam'] ?? 0) as num)
                                      .toDouble();

                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1A1A1A),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: const Color(0x22FFB300),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            dukkanAdi.isEmpty
                                                ? saticiDoc.id
                                                : dukkanAdi,
                                            style: const TextStyle(
                                              color: Color(0xFFFFB300),
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: _durumRenk(durum)
                                                .withValues(alpha: 0.18),
                                            borderRadius:
                                                BorderRadius.circular(30),
                                            border: Border.all(
                                              color: _durumRenk(durum),
                                            ),
                                          ),
                                          child: Text(
                                            _durumYazi(durum),
                                            style: TextStyle(
                                              color: _durumRenk(durum),
                                              fontWeight: FontWeight.w600,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    StreamBuilder<
                                        QuerySnapshot<Map<String, dynamic>>>(
                                      stream: FirebaseFirestore.instance
                                          .collection('siparisler')
                                          .doc(siparisDoc.id)
                                          .collection('saticiSiparisleri')
                                          .doc(saticiDoc.id)
                                          .collection('items')
                                          .snapshots(),
                                      builder: (context, itemSnapshot) {
                                        if (itemSnapshot.hasError) {
                                          return Text(
                                            'Ürünler okunamadı: ${itemSnapshot.error}',
                                            style: const TextStyle(
                                              color: Colors.white54,
                                            ),
                                          );
                                        }

                                        if (!itemSnapshot.hasData) {
                                          return const Padding(
                                            padding: EdgeInsets.symmetric(
                                              vertical: 8,
                                            ),
                                            child: CircularProgressIndicator(
                                              color: Color(0xFFFFB300),
                                            ),
                                          );
                                        }

                                        final itemDocs =
                                            itemSnapshot.data!.docs;

                                        if (itemDocs.isEmpty) {
                                          return const Text(
                                            'Ürün bulunamadı.',
                                            style: TextStyle(
                                              color: Colors.white54,
                                            ),
                                          );
                                        }

                                        return Column(
                                          children: [
                                            ...itemDocs.map((itemDoc) {
                                              final item = itemDoc.data();
                                              final urunAdi =
                                                  (item['urunAdi'] ?? 'Ürün')
                                                      .toString();
                                              final adet =
                                                  ((item['adet'] ?? 1) as num)
                                                      .toInt();
                                              final fiyat =
                                                  ((item['fiyat'] ?? 0) as num)
                                                      .toDouble();
                                              final img = (item['img'] ?? '')
                                                  .toString();

                                              return Container(
                                                margin: const EdgeInsets.only(
                                                  bottom: 10,
                                                ),
                                                padding:
                                                    const EdgeInsets.all(10),
                                                decoration: BoxDecoration(
                                                  color:
                                                      const Color(0xFF1D1D1D),
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                child: Row(
                                                  children: [
                                                    ClipRRect(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                        10,
                                                      ),
                                                      child: img.isNotEmpty
                                                          ? Image.network(
                                                              img,
                                                              width: 58,
                                                              height: 58,
                                                              fit: BoxFit.cover,
                                                              errorBuilder: (
                                                                context,
                                                                error,
                                                                stackTrace,
                                                              ) {
                                                                return Container(
                                                                  width: 58,
                                                                  height: 58,
                                                                  color: Colors
                                                                      .grey
                                                                      .shade800,
                                                                  child:
                                                                      const Icon(
                                                                    Icons
                                                                        .image_not_supported,
                                                                    color: Colors
                                                                        .white54,
                                                                    size: 20,
                                                                  ),
                                                                );
                                                              },
                                                            )
                                                          : Container(
                                                              width: 58,
                                                              height: 58,
                                                              color: Colors.grey
                                                                  .shade800,
                                                              child: const Icon(
                                                                Icons.fastfood,
                                                                color: Colors
                                                                    .white54,
                                                                size: 20,
                                                              ),
                                                            ),
                                                    ),
                                                    const SizedBox(width: 10),
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Text(
                                                            urunAdi,
                                                            style:
                                                                const TextStyle(
                                                              color:
                                                                  Colors.white,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                            height: 4,
                                                          ),
                                                          Text(
                                                            '$adet adet',
                                                            style:
                                                                const TextStyle(
                                                              color: Colors
                                                                  .white70,
                                                              fontSize: 12,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    Text(
                                                      '${(fiyat * adet).toStringAsFixed(0)} ₺',
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            }),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                const Text(
                                                  'Alt Toplam',
                                                  style: TextStyle(
                                                    color: Colors.white70,
                                                    fontSize: 13,
                                                  ),
                                                ),
                                                const Spacer(),
                                                Text(
                                                  '${altToplam.toStringAsFixed(0)} ₺',
                                                  style: const TextStyle(
                                                    color: Color(0xFFFFB300),
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                      const Divider(color: Color(0x22FFFFFF)),
                      Row(
                        children: [
                          const Text(
                            'Toplam Tutar',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 15,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${toplamTutar.toStringAsFixed(0)} ₺',
                            style: const TextStyle(
                              color: Color(0xFFFFB300),
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
