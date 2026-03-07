import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class SaticiSiparisPaneli extends StatelessWidget {
  const SaticiSiparisPaneli({super.key});

  Future<void> _durumGuncelle({
    required String siparisId,
    required String dukkanId,
    required String yeniDurum,
    required BuildContext context,
  }) async {
    try {
      await FirebaseFirestore.instance
          .collection('siparisler')
          .doc(siparisId)
          .collection('saticiSiparisleri')
          .doc(dukkanId)
          .update({
        'durum': yeniDurum,
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Durum güncellendi: $yeniDurum')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Durum güncellenemedi: $e')),
        );
      }
    }
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

  String _durumLabel(String durum) {
    switch (durum) {
      case 'alindi':
        return 'Alındı';
      case 'hazirlaniyor':
        return 'Hazırlanıyor';
      case 'yolda':
        return 'Yolda';
      case 'teslim_edildi':
        return 'Teslim Edildi';
      case 'iptal':
        return 'İptal';
      default:
        return durum;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFFFFB300)),
        title: const Text(
          'Satıcı Siparişleri',
          style: TextStyle(
            color: Color(0xFFFFB300),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('siparisler').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Satıcı paneli hatası: ${snapshot.error}',
                  style: const TextStyle(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFFFB300)),
            );
          }

          final siparisDocs = snapshot.data?.docs ?? [];

          if (siparisDocs.isEmpty) {
            return const Center(
              child: Text(
                'Henüz sipariş yok.',
                style: TextStyle(color: Colors.white70),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: siparisDocs.length,
            itemBuilder: (context, index) {
              final siparisDoc = siparisDocs[index];
              final siparisData = siparisDoc.data();

              final siparisId = siparisDoc.id;
              final adres = (siparisData['adres'] ?? '').toString();
              final telefon = (siparisData['telefon'] ?? '').toString();

              return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('siparisler')
                    .doc(siparisId)
                    .collection('saticiSiparisleri')
                    .snapshots(),
                builder: (context, saticiSnapshot) {
                  if (saticiSnapshot.hasError) {
                    return Card(
                      color: const Color(0xFF1C1C1C),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'Satıcı siparişleri okunamadı: ${saticiSnapshot.error}',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    );
                  }

                  if (!saticiSnapshot.hasData) {
                    return const Card(
                      color: Color(0xFF1C1C1C),
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFFFFB300),
                          ),
                        ),
                      ),
                    );
                  }

                  final saticiDocs = saticiSnapshot.data!.docs;

                  if (saticiDocs.isEmpty) {
                    return Card(
                      color: const Color(0xFF1C1C1C),
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'Bu siparişte saticiSiparisleri yok. Sipariş No: $siparisId',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    );
                  }

                  return Column(
                    children: saticiDocs.map((saticiDoc) {
                      final saticiData = saticiDoc.data();
                      final dukkanId = saticiDoc.id;
                      final dukkanAdi =
                          (saticiData['dukkanAdi'] ?? '').toString();
                      final durum =
                          (saticiData['durum'] ?? 'alindi').toString();
                      final altToplam =
                          ((saticiData['altToplam'] ?? 0) as num).toDouble();

                      return FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
                        future: FirebaseFirestore.instance
                            .collection('siparisler')
                            .doc(siparisId)
                            .collection('saticiSiparisleri')
                            .doc(dukkanId)
                            .collection('items')
                            .get(),
                        builder: (context, itemSnapshot) {
                          if (itemSnapshot.hasError) {
                            return Card(
                              color: const Color(0xFF1C1C1C),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Text(
                                  'Item okuma hatası: ${itemSnapshot.error}',
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                            );
                          }

                          if (!itemSnapshot.hasData) {
                            return const Card(
                              color: Color(0xFF1C1C1C),
                              child: Padding(
                                padding: EdgeInsets.all(16),
                                child: Center(
                                  child: CircularProgressIndicator(
                                    color: Color(0xFFFFB300),
                                  ),
                                ),
                              ),
                            );
                          }

                          final itemDocs = itemSnapshot.data!.docs;

                          return Card(
                            color: const Color(0xFF1C1C1C),
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                              side: const BorderSide(color: Color(0x33FFB300)),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    dukkanAdi.isEmpty ? dukkanId : dukkanAdi,
                                    style: const TextStyle(
                                      color: Color(0xFFFFB300),
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Sipariş No: $siparisId',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                                  Text(
                                    'dukkanId: $dukkanId',
                                    style: const TextStyle(
                                      color: Colors.white54,
                                      fontSize: 11,
                                    ),
                                  ),
                                  if (adres.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      'Adres: $adres',
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                  if (telefon.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      'Telefon: $telefon',
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 12),
                                  if (itemDocs.isEmpty)
                                    const Text(
                                      'Bu satıcı siparişinde ürün yok.',
                                      style: TextStyle(color: Colors.white54),
                                    )
                                  else
                                    ...itemDocs.map((itemDoc) {
                                      final item = itemDoc.data();

                                      final urunAdi =
                                          (item['urunAdi'] ?? 'Ürün')
                                              .toString();
                                      final adet =
                                          ((item['adet'] ?? 0) as num).toInt();
                                      final fiyat =
                                          ((item['fiyat'] ?? 0) as num)
                                              .toDouble();
                                      final img =
                                          (item['img'] ?? '').toString();

                                      return Container(
                                        margin:
                                            const EdgeInsets.only(bottom: 10),
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF161616),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Row(
                                          children: [
                                            ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              child: img.isNotEmpty
                                                  ? Image.network(
                                                      img,
                                                      width: 64,
                                                      height: 64,
                                                      fit: BoxFit.cover,
                                                      errorBuilder: (
                                                        context,
                                                        error,
                                                        stackTrace,
                                                      ) {
                                                        return Container(
                                                          width: 64,
                                                          height: 64,
                                                          color: Colors
                                                              .grey.shade800,
                                                          child: const Icon(
                                                            Icons
                                                                .image_not_supported,
                                                            color:
                                                                Colors.white54,
                                                          ),
                                                        );
                                                      },
                                                    )
                                                  : Container(
                                                      width: 64,
                                                      height: 64,
                                                      color:
                                                          Colors.grey.shade800,
                                                      child: const Icon(
                                                        Icons.fastfood,
                                                        color: Colors.white54,
                                                      ),
                                                    ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    urunAdi,
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    'Adet: $adet',
                                                    style: const TextStyle(
                                                      color: Colors.white70,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    'Tutar: ${(fiyat * adet).toStringAsFixed(0)} ₺',
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _durumRenk(durum)
                                              .withValues(alpha: 0.15),
                                          borderRadius:
                                              BorderRadius.circular(20),
                                          border: Border.all(
                                            color: _durumRenk(durum),
                                          ),
                                        ),
                                        child: Text(
                                          _durumLabel(durum),
                                          style: TextStyle(
                                            color: _durumRenk(durum),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                      const Spacer(),
                                      Text(
                                        'Alt Toplam: ${altToplam.toStringAsFixed(0)} ₺',
                                        style: const TextStyle(
                                          color: Color(0xFFFFB300),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: PopupMenuButton<String>(
                                      color: const Color(0xFF1F1F1F),
                                      onSelected: (value) {
                                        _durumGuncelle(
                                          siparisId: siparisId,
                                          dukkanId: dukkanId,
                                          yeniDurum: value,
                                          context: context,
                                        );
                                      },
                                      itemBuilder: (context) => const [
                                        PopupMenuItem(
                                          value: 'alindi',
                                          child: Text(
                                            'Alındı',
                                            style:
                                                TextStyle(color: Colors.white),
                                          ),
                                        ),
                                        PopupMenuItem(
                                          value: 'hazirlaniyor',
                                          child: Text(
                                            'Hazırlanıyor',
                                            style:
                                                TextStyle(color: Colors.white),
                                          ),
                                        ),
                                        PopupMenuItem(
                                          value: 'yolda',
                                          child: Text(
                                            'Yolda',
                                            style:
                                                TextStyle(color: Colors.white),
                                          ),
                                        ),
                                        PopupMenuItem(
                                          value: 'teslim_edildi',
                                          child: Text(
                                            'Teslim Edildi',
                                            style:
                                                TextStyle(color: Colors.white),
                                          ),
                                        ),
                                        PopupMenuItem(
                                          value: 'iptal',
                                          child: Text(
                                            'İptal',
                                            style:
                                                TextStyle(color: Colors.white),
                                          ),
                                        ),
                                      ],
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0x22FFB300),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          border: Border.all(
                                            color: const Color(0x66FFB300),
                                          ),
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.edit_note,
                                              color: Color(0xFFFFB300),
                                              size: 18,
                                            ),
                                            SizedBox(width: 6),
                                            Text(
                                              'Durum Güncelle',
                                              style: TextStyle(
                                                color: Color(0xFFFFB300),
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    }).toList(),
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
