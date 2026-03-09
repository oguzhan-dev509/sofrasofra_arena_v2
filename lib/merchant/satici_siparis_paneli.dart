import 'dart:html' as html;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class SaticiSiparisPaneli extends StatefulWidget {
  const SaticiSiparisPaneli({super.key});

  @override
  State<SaticiSiparisPaneli> createState() => _SaticiSiparisPaneliState();
}

class _SaticiSiparisPaneliState extends State<SaticiSiparisPaneli> {
  final String aktifSaticiId = 'ayse_hanim_mutfagi';

  final Set<String> _gorulenSellerOrderIdleri = <String>{};
  bool _ilkYuklemeTamamlandi = false;

  void _yeniSiparisKontrolEt(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final mevcutIdler = docs.map((e) => e.id).toSet();

    if (!_ilkYuklemeTamamlandi) {
      _gorulenSellerOrderIdleri
        ..clear()
        ..addAll(mevcutIdler);
      _ilkYuklemeTamamlandi = true;
      return;
    }

    final yeniIdler = mevcutIdler.difference(_gorulenSellerOrderIdleri);

    if (yeniIdler.isNotEmpty) {
      _gorulenSellerOrderIdleri.addAll(yeniIdler);
      _alarmCal();

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color(0xFF1E1E1E),
            content: Text(
              '🔔 Yeni sipariş geldi!',
              style: TextStyle(color: Colors.white),
            ),
          ),
        );
      });
    }
  }

  void _alarmCal() {
    try {
      final audio = html.AudioElement()
        ..src =
            'data:audio/wav;base64,UklGRlQAAABXQVZFZm10IBAAAAABAAEAQB8AAEAfAAABAAgAZGF0YTAAAAAAgICAf39/f4CAgH9/f3+AgIB/f39/gICAf39/f4CAgH9/f3+AgIB/f39/gICAf39/f4CAgA=='
        ..autoplay = true;
      audio.play();
    } catch (_) {}
  }

  Future<void> _durumGuncelle({
    required String orderId,
    required String sellerOrderId,
    required String siparisNo,
    required String saticiId,
    required String yeniDurum,
  }) async {
    try {
      final firestore = FirebaseFirestore.instance;
      final batch = firestore.batch();

      final sellerOrderRef =
          firestore.collection('sellerOrders').doc(sellerOrderId);

      final orderRef = firestore.collection('orders').doc(orderId);

      final timelineRef = firestore.collection('orderTimeline').doc();

      batch.update(sellerOrderRef, {
        'status': yeniDurum,
        'durum': yeniDurum,
        'statusUpdatedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      batch.update(orderRef, {
        'status': yeniDurum,
        'statusUpdatedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      batch.set(timelineRef, {
        'orderId': orderId,
        'siparisNo': siparisNo,
        'status': yeniDurum,
        'actorType': 'seller',
        'actorId': saticiId,
        'note': 'Satıcı sipariş durumunu güncelledi',
        'createdAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF1E1E1E),
          content: Text(
            'Durum güncellendi: ${_durumLabel(yeniDurum)}',
            style: const TextStyle(color: Colors.white),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red.shade700,
          content: Text(
            'Durum güncellenemedi: $e',
            style: const TextStyle(color: Colors.white),
          ),
        ),
      );
    }
  }

  Color _durumRenk(String durum) {
    switch (durum) {
      case 'pending':
        return Colors.blueGrey;
      case 'preparing':
        return Colors.orange;
      case 'on_the_way':
        return Colors.blue;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.redAccent;
      default:
        return Colors.grey;
    }
  }

  IconData _durumIcon(String durum) {
    switch (durum) {
      case 'pending':
        return Icons.receipt_long;
      case 'preparing':
        return Icons.restaurant;
      case 'on_the_way':
        return Icons.delivery_dining;
      case 'delivered':
        return Icons.check_circle;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.info_outline;
    }
  }

  String _durumLabel(String durum) {
    switch (durum) {
      case 'pending':
        return 'Sipariş Alındı';
      case 'preparing':
        return 'Hazırlanıyor';
      case 'on_the_way':
        return 'Yolda';
      case 'delivered':
        return 'Teslim Edildi';
      case 'cancelled':
        return 'İptal';
      default:
        return durum;
    }
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

  String _safeString(dynamic value, {String fallback = ''}) {
    if (value == null) return fallback;
    final text = value.toString().trim();
    return text.isEmpty ? fallback : text;
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

  String _price(double value) => '${value.toStringAsFixed(0)} ₺';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
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
        stream: FirebaseFirestore.instance
            .collection('sellerOrders')
            .where('saticiId', isEqualTo: aktifSaticiId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xFF151515),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0x22FFB300)),
                  ),
                  child: Text(
                    'Satıcı paneli yüklenirken hata oluştu.\n\n${snapshot.error}',
                    style: const TextStyle(
                      color: Colors.white70,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
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

          final sellerOrderDocs = snapshot.data?.docs ?? [];
          _yeniSiparisKontrolEt(sellerOrderDocs);

          if (sellerOrderDocs.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        color: const Color(0x22FFB300),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: const Color(0x44FFB300)),
                      ),
                      child: const Icon(
                        Icons.storefront_outlined,
                        size: 40,
                        color: Color(0xFFFFB300),
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Henüz sipariş yok',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Size gelen siparişler burada listelenecek.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white60,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: sellerOrderDocs.length,
            itemBuilder: (context, index) {
              final sellerOrderDoc = sellerOrderDocs[index];
              final sellerOrderData = sellerOrderDoc.data();

              final sellerOrderId = sellerOrderDoc.id;
              final orderId = _safeString(
                sellerOrderData['orderId'],
                fallback: sellerOrderId,
              );
              final siparisNo = _safeString(
                sellerOrderData['siparisNo'],
                fallback: orderId,
              );
              final saticiId = _safeString(
                sellerOrderData['saticiId'],
                fallback: aktifSaticiId,
              );
              final durum = _safeString(
                sellerOrderData['status'] ?? sellerOrderData['durum'],
                fallback: 'pending',
              );
              final altToplam = _asDouble(
                sellerOrderData['araToplam'] ??
                    sellerOrderData['altToplam'] ??
                    sellerOrderData['subtotal'],
              );
              final createdAt = sellerOrderData['createdAt'];

              return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                future: FirebaseFirestore.instance
                    .collection('orders')
                    .doc(orderId)
                    .get(),
                builder: (context, orderSnapshot) {
                  final orderData = orderSnapshot.data?.data() ?? {};
                  final meta = (orderData['meta'] is Map)
                      ? Map<String, dynamic>.from(orderData['meta'] as Map)
                      : <String, dynamic>{};

                  String adres = 'Adres yok';
                  String telefon = 'Telefon yok';

                  final dynamic rawAdres = meta['adres'];
                  if (rawAdres is Map) {
                    final mapAdres = Map<String, dynamic>.from(rawAdres);
                    adres = _safeString(
                      mapAdres['acikAdres'],
                      fallback: 'Adres yok',
                    );
                    telefon = _safeString(
                      mapAdres['telefon'],
                      fallback: 'Telefon yok',
                    );
                  } else {
                    adres = _safeString(rawAdres, fallback: 'Adres yok');
                    telefon = _safeString(
                      meta['telefon'],
                      fallback: 'Telefon yok',
                    );
                  }

                  return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: FirebaseFirestore.instance
                        .collection('sellerOrders')
                        .doc(sellerOrderId)
                        .collection('items')
                        .snapshots(),
                    builder: (context, itemSnapshot) {
                      if (itemSnapshot.hasError) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1C1C1C),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0x22FFB300)),
                          ),
                          child: Text(
                            'Ürünler okunamadı: ${itemSnapshot.error}',
                            style: const TextStyle(color: Colors.white70),
                          ),
                        );
                      }

                      if (!itemSnapshot.hasData) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1C1C1C),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0x22FFB300)),
                          ),
                          child: const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFFFFB300),
                            ),
                          ),
                        );
                      }

                      final itemDocs = itemSnapshot.data!.docs;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF151515),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0x33FFB300)),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x22000000),
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Sipariş No',
                                          style: TextStyle(
                                            color: Colors.white54,
                                            fontSize: 12,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          siparisNo,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          _siparisTarihi(createdAt),
                                          style: const TextStyle(
                                            color: Colors.white60,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 7,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          _durumRenk(durum).withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(30),
                                      border: Border.all(
                                        color: _durumRenk(durum),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          _durumIcon(durum),
                                          size: 16,
                                          color: _durumRenk(durum),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          _durumLabel(durum),
                                          style: TextStyle(
                                            color: _durumRenk(durum),
                                            fontWeight: FontWeight.w700,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1A1A1A),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: const Color(0x22FFFFFF),
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    _infoSatiri(
                                      icon: Icons.storefront_outlined,
                                      label: 'Satıcı',
                                      value: saticiId,
                                    ),
                                    const SizedBox(height: 10),
                                    _infoSatiri(
                                      icon: Icons.location_on_outlined,
                                      label: 'Adres',
                                      value: adres,
                                    ),
                                    const SizedBox(height: 10),
                                    _infoSatiri(
                                      icon: Icons.phone_outlined,
                                      label: 'Telefon',
                                      value: telefon,
                                    ),
                                    const SizedBox(height: 10),
                                    _infoSatiri(
                                      icon: Icons.fingerprint,
                                      label: 'Order ID',
                                      value: orderId,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 14),
                              const Row(
                                children: [
                                  Icon(
                                    Icons.fastfood_outlined,
                                    color: Color(0xFFFFB300),
                                    size: 18,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Ürün Listesi',
                                    style: TextStyle(
                                      color: Color(0xFFFFB300),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              if (itemDocs.isEmpty)
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1A1A1A),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: const Text(
                                    'Bu satıcı siparişinde ürün yok.',
                                    style: TextStyle(color: Colors.white54),
                                  ),
                                )
                              else
                                ...itemDocs.map((itemDoc) {
                                  final item = itemDoc.data();

                                  final urunAdi = _safeString(
                                    item['urunAdi'] ??
                                        item['ad'] ??
                                        item['name'],
                                    fallback: 'Ürün',
                                  );

                                  final adet = _asInt(
                                    item['adet'] ??
                                        item['quantity'] ??
                                        item['qty'],
                                  );

                                  final fiyat = _asDouble(
                                    item['fiyat'] ??
                                        item['birimFiyat'] ??
                                        item['unitPrice'] ??
                                        item['price'],
                                  );

                                  final img = _safeString(
                                    item['gorselUrl'] ??
                                        item['img'] ??
                                        item['imageUrl'],
                                  );

                                  final satirToplam = fiyat * adet;

                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 10),
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF202020),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: const Color(0x14FFFFFF),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          child: img.isNotEmpty
                                              ? Image.network(
                                                  img,
                                                  width: 66,
                                                  height: 66,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (
                                                    context,
                                                    error,
                                                    stackTrace,
                                                  ) {
                                                    return Container(
                                                      width: 66,
                                                      height: 66,
                                                      color:
                                                          Colors.grey.shade800,
                                                      child: const Icon(
                                                        Icons
                                                            .image_not_supported_outlined,
                                                        color: Colors.white54,
                                                      ),
                                                    );
                                                  },
                                                )
                                              : Container(
                                                  width: 66,
                                                  height: 66,
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
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                urunAdi,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(height: 5),
                                              Text(
                                                '$adet adet',
                                                style: const TextStyle(
                                                  color: Colors.white70,
                                                  fontSize: 12,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                '${fiyat.toStringAsFixed(0)} ₺ x $adet',
                                                style: const TextStyle(
                                                  color: Colors.white54,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Text(
                                          _price(satirToplam),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                              const SizedBox(height: 14),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF101010),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: const Color(0x22FFB300),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Alt Toplam',
                                          style: TextStyle(
                                            color: Colors.white70,
                                            fontSize: 13,
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          'Bu satıcıya ait toplam',
                                          style: TextStyle(
                                            color: Colors.white54,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const Spacer(),
                                    Text(
                                      _price(altToplam),
                                      style: const TextStyle(
                                        color: Color(0xFFFFB300),
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 14),
                              Align(
                                alignment: Alignment.centerRight,
                                child: PopupMenuButton<String>(
                                  color: const Color(0xFF1F1F1F),
                                  onSelected: (value) {
                                    _durumGuncelle(
                                      orderId: orderId,
                                      sellerOrderId: sellerOrderId,
                                      siparisNo: siparisNo,
                                      saticiId: saticiId,
                                      yeniDurum: value,
                                    );
                                  },
                                  itemBuilder: (context) => const [
                                    PopupMenuItem(
                                      value: 'pending',
                                      child: Text(
                                        'Sipariş Alındı',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ),
                                    PopupMenuItem(
                                      value: 'preparing',
                                      child: Text(
                                        'Hazırlanıyor',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ),
                                    PopupMenuItem(
                                      value: 'on_the_way',
                                      child: Text(
                                        'Yolda',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ),
                                    PopupMenuItem(
                                      value: 'delivered',
                                      child: Text(
                                        'Teslim Edildi',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ),
                                    PopupMenuItem(
                                      value: 'cancelled',
                                      child: Text(
                                        'İptal',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ),
                                  ],
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0x22FFB300),
                                      borderRadius: BorderRadius.circular(12),
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
                                        SizedBox(width: 8),
                                        Text(
                                          'Durum Güncelle',
                                          style: TextStyle(
                                            color: Color(0xFFFFB300),
                                            fontWeight: FontWeight.w700,
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
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _infoSatiri({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: const Color(0xFFFFB300),
          size: 18,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: '$label: ',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextSpan(
                  text: value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
