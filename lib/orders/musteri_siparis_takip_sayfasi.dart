import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'musteri_canli_kurye_takip_haritasi.dart';

class MusteriSiparisTakipSayfasi extends StatefulWidget {
  const MusteriSiparisTakipSayfasi({super.key});

  @override
  State<MusteriSiparisTakipSayfasi> createState() =>
      _MusteriSiparisTakipSayfasiState();
}

class _MusteriSiparisTakipSayfasiState
    extends State<MusteriSiparisTakipSayfasi> {
  String? get userId => FirebaseAuth.instance.currentUser?.uid;

  Stream<QuerySnapshot<Map<String, dynamic>>> _siparislerStream() {
    return FirebaseFirestore.instance
        .collection('orders')
        .orderBy('createdAt', descending: true)
        .limit(20)
        .snapshots();
  }

  String _normalizeStatus(dynamic value) {
    final raw = _safeString(value).trim().toLowerCase();

    switch (raw) {
      case 'pending':
        return 'pending';

      case 'accepted':
      case 'onaylandi':
      case 'approved':
        return 'accepted';

      case 'preparing':
      case 'hazirlaniyor':
        return 'preparing';

      case 'ready':
      case 'hazir':
        return 'ready';

      case 'waiting_courier':
      case 'kurye_bekleniyor':
      case 'courier_waiting':
        return 'waiting_courier';

      case 'assigned':
      case 'courier_assigned':
      case 'atandi':
      case 'kurye_atandi':
        return 'assigned';

      case 'retry_scheduled':
      case 'kurye_yeniden_araniyor':
        return 'retry_scheduled';

      case 'manual_review_required':
      case 'operasyon_kontrolu':
        return 'manual_review_required';

      case 'on_the_way':
      case 'yolda':
        return 'on_the_way';

      case 'delivered':
      case 'teslim_edildi':
      case 'completed':
      case 'complete':
        return 'delivered';

      case 'cancelled':
      case 'iptal':
      case 'canceled':
      case 'cancel':
        return 'cancelled';

      default:
        return 'pending';
    }
  }

  String _statusText(String status) {
    switch (status) {
      case 'pending':
        return 'Sipariş Alındı';
      case 'accepted':
        return 'Sipariş Onaylandı';
      case 'preparing':
        return 'Hazırlanıyor';
      case 'ready':
        return 'Hazır';
      case 'waiting_courier':
        return 'Kurye Aranıyor';
      case 'assigned':
        return 'Kurye Atandı';
      case 'retry_scheduled':
        return 'Kurye Yeniden Aranıyor';
      case 'manual_review_required':
        return 'Operasyon Kontrolünde';
      case 'on_the_way':
        return 'Yolda';
      case 'delivered':
        return 'Teslim Edildi';
      case 'cancelled':
        return 'İptal Edildi';
      default:
        return 'Sipariş Alındı';
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.grey;
      case 'accepted':
        return Colors.blue;
      case 'preparing':
        return Colors.orange;
      case 'ready':
        return Colors.purple;
      case 'waiting_courier':
        return Colors.amber;
      case 'assigned':
        return Colors.lightBlueAccent;
      case 'retry_scheduled':
        return Colors.deepOrangeAccent;
      case 'manual_review_required':
        return Colors.indigoAccent;
      case 'on_the_way':
        return Colors.teal;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.redAccent;
      default:
        return Colors.grey;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.receipt_long;
      case 'accepted':
        return Icons.check_circle_outline;
      case 'preparing':
        return Icons.restaurant;
      case 'ready':
        return Icons.inventory_2_outlined;
      case 'waiting_courier':
        return Icons.search;
      case 'assigned':
        return Icons.delivery_dining;
      case 'retry_scheduled':
        return Icons.sync;
      case 'manual_review_required':
        return Icons.support_agent;
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

  String _siparisTarihi(dynamic createdAt) {
    if (createdAt is! Timestamp) return 'Tarih yok';
    final dt = createdAt.toDate();

    return '${dt.day.toString().padLeft(2, '0')}.'
        '${dt.month.toString().padLeft(2, '0')}.'
        '${dt.year} '
        '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
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
    if (value is String) {
      return int.tryParse(value) ?? 0;
    }
    return 0;
  }

  String _safeString(dynamic value, {String fallback = ''}) {
    if (value == null) return fallback;
    final text = value.toString().trim();
    return text.isEmpty ? fallback : text;
  }

  Map<String, dynamic> _safeMap(dynamic value) {
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return <String, dynamic>{};
  }

  String _extractAdres(Map<String, dynamic> data) {
    final direct = _safeString(
      data['teslimatAdresi'] ?? data['addressText'] ?? data['adres'],
    );
    if (direct.isNotEmpty) return direct;

    final meta = _safeMap(data['meta']);
    final adres = meta['adres'];

    if (adres is Map) {
      final mapAdres = Map<String, dynamic>.from(adres);
      return _safeString(mapAdres['acikAdres'], fallback: 'Adres yok');
    }

    return _safeString(adres, fallback: 'Adres yok');
  }

  String _extractTelefon(Map<String, dynamic> data) {
    final direct = _safeString(data['musteriTelefon'] ?? data['phone']);
    if (direct.isNotEmpty) return direct;

    final meta = _safeMap(data['meta']);
    final adres = meta['adres'];

    if (adres is Map) {
      final mapAdres = Map<String, dynamic>.from(adres);
      return _safeString(mapAdres['telefon'], fallback: 'Telefon yok');
    }

    return _safeString(meta['telefon'], fallback: 'Telefon yok');
  }

  String _extractOdemeYontemi(Map<String, dynamic> data) {
    final direct = _safeString(data['paymentMethod']);

    if (direct.isNotEmpty) {
      switch (direct) {
        case 'cash':
          return 'Kapıda Nakit';
        case 'pos':
          return 'Kapıda Kart';
        case 'online':
          return 'Online Ödeme';
        default:
          return direct;
      }
    }

    final meta = _safeMap(data['meta']);
    return _safeString(
      meta['odemeYontemi'] ?? meta['odemeTipi'],
      fallback: 'Belirtilmedi',
    );
  }

  String _extractTeslimatTipi(Map<String, dynamic> data) {
    final direct = _safeString(data['siparisTipi'] ?? data['deliveryMode']);

    if (direct.isNotEmpty) {
      switch (direct) {
        case 'gel_al':
          return 'Gel Al';
        case 'platform_kurye':
          return 'Platform Kurye';
        case 'satici_kuryesi':
          return 'Satıcı Kuryesi';
        case 'teslimat':
          return 'Teslimat';
        default:
          return direct;
      }
    }

    final meta = _safeMap(data['meta']);
    return _safeString(meta['teslimatTipi'], fallback: 'Standart');
  }

  String _price(double value) => '${value.toStringAsFixed(0)} ₺';

  Widget _buildStatusBadge(String status) {
    final color = _statusColor(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_statusIcon(status), size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            'Durum: ${_statusText(status)}',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSiparisKart(
    BuildContext context,
    QueryDocumentSnapshot<Map<String, dynamic>> siparisDoc,
  ) {
    final data = siparisDoc.data();

    final courierId = _safeString(data['assignedCourierId']);
    final status = _normalizeStatus(data['status'] ?? data['durum']);
    final courierStatus = _normalizeStatus(
      data['assignmentStatus'] ??
          data['courierAssignmentStatus'] ??
          data['courierOfferStatus'],
    );
    final bool hasCourier = courierId.isNotEmpty;
    final bool canOpenLiveMap =
        hasCourier && (courierStatus == 'assigned' || status == 'on_the_way');
    final bool isDeliveryDone =
        status == 'delivered' || courierStatus == 'delivered';
    final siparisNo = _safeString(data['siparisNo'], fallback: siparisDoc.id);

    final toplamTutar = _asDouble(
      data['genelToplam'] ?? data['toplamTutar'] ?? data['total'],
    );

    final createdAt = data['createdAt'];
    final adres = _extractAdres(data);
    final telefon = _extractTelefon(data);
    final odemeYontemi = _extractOdemeYontemi(data);
    final teslimatTipi = _extractTeslimatTipi(data);

    final kuryeAdi = _safeString(
      data['assignedCourierName'] ?? data['kuryeAdi'],
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatusBadge(status),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              _siparisTarihi(createdAt),
              style: const TextStyle(
                color: Colors.white60,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 14),
            OrderTimeline(status: status),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0x22FFFFFF)),
              ),
              child: Column(
                children: [
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
                    icon: Icons.payments_outlined,
                    label: 'Ödeme',
                    value: odemeYontemi,
                  ),
                  const SizedBox(height: 10),
                  _infoSatiri(
                    icon: Icons.local_shipping_outlined,
                    label: 'Teslimat',
                    value: teslimatTipi,
                  ),
                  if (teslimatTipi == 'Platform Kurye' ||
                      courierStatus != 'pending' ||
                      hasCourier) ...[
                    const SizedBox(height: 10),
                    _infoSatiri(
                      icon: Icons.delivery_dining_outlined,
                      label: 'Kurye Takip',
                      value: hasCourier && courierStatus == 'pending'
                          ? 'Kurye Atandı'
                          : _statusText(courierStatus),
                    ),
                  ],
                  if (kuryeAdi.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    _infoSatiri(
                      icon: Icons.delivery_dining,
                      label: 'Kurye',
                      value: kuryeAdi,
                    ),
                  ],
                  if (courierId.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    if (canOpenLiveMap) ...[
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => MusteriCanliKuryeTakipHaritasi(
                                  orderId: siparisDoc.id,
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.map_outlined),
                          label: Text(
                            status == 'assigned'
                                ? 'Kuryeyi Haritada Gör'
                                : 'Canlı Kuryeyi Takip Et',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFFB300),
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                    ] else if (hasCourier && isDeliveryDone) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF102418),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Colors.greenAccent.withValues(alpha: 0.35),
                          ),
                        ),
                        child: const Text(
                          'Teslimat tamamlandı.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ] else ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF111111),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Color(0x33FFB300),
                          ),
                        ),
                        child: const Text(
                          'Kurye atanınca canlı harita takibi burada açılacak.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),
            const Row(
              children: [
                Icon(
                  Icons.storefront_outlined,
                  color: Color(0xFFFFB300),
                  size: 18,
                ),
                SizedBox(width: 8),
                Text(
                  'Satıcı Siparişleri',
                  style: TextStyle(
                    color: Color(0xFFFFB300),
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('sellerOrders')
                  .where('orderId', isEqualTo: siparisDoc.id)
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
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFFFB300),
                      ),
                    ),
                  );
                }

                final saticiDocs = saticiSnapshot.data!.docs;

                if (saticiDocs.isEmpty) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A1A),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0x22FFFFFF)),
                    ),
                    child: const Text(
                      'Satıcı siparişi bulunamadı.',
                      style: TextStyle(color: Colors.white54),
                    ),
                  );
                }

                return Column(
                  children: saticiDocs.map((saticiDoc) {
                    final saticiData = saticiDoc.data();

                    final saticiStatus = _normalizeStatus(
                      saticiData['status'] ?? saticiData['durum'],
                    );

                    final saticiId = _safeString(
                      saticiData['saticiId'] ??
                          saticiData['sellerId'] ??
                          saticiData['dukkanAdi'] ??
                          saticiData['dukkan'],
                      fallback: saticiDoc.id,
                    );

                    final altToplam = _asDouble(
                      saticiData['araToplam'] ??
                          saticiData['altToplam'] ??
                          saticiData['subtotal'],
                    );

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A1A),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0x22FFB300)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Satıcı',
                                      style: TextStyle(
                                        color: Colors.white54,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      saticiId,
                                      style: const TextStyle(
                                        color: Color(0xFFFFB300),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: _statusColor(saticiStatus)
                                      .withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(30),
                                  border: Border.all(
                                    color: _statusColor(saticiStatus),
                                  ),
                                ),
                                child: Text(
                                  'Durum: ${_statusText(saticiStatus)}',
                                  style: TextStyle(
                                    color: _statusColor(saticiStatus),
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                            stream: FirebaseFirestore.instance
                                .collection('sellerOrders')
                                .doc(saticiDoc.id)
                                .collection('items')
                                .snapshots(),
                            builder: (context, itemSnapshot) {
                              if (itemSnapshot.hasError) {
                                return Text(
                                  'Ürünler okunamadı: ${itemSnapshot.error}',
                                  style: const TextStyle(color: Colors.white54),
                                );
                              }

                              if (!itemSnapshot.hasData) {
                                return const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 8),
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      color: Color(0xFFFFB300),
                                    ),
                                  ),
                                );
                              }

                              final itemDocs = itemSnapshot.data!.docs;

                              if (itemDocs.isEmpty) {
                                return const Text(
                                  'Ürün bulunamadı.',
                                  style: TextStyle(color: Colors.white54),
                                );
                              }

                              return Column(
                                children: [
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
                                                            .grey.shade800,
                                                        child: const Icon(
                                                          Icons
                                                              .image_not_supported_outlined,
                                                          color: Colors.white54,
                                                          size: 20,
                                                        ),
                                                      );
                                                    },
                                                  )
                                                : Container(
                                                    width: 58,
                                                    height: 58,
                                                    color: Colors.grey.shade800,
                                                    child: const Icon(
                                                      Icons.fastfood,
                                                      color: Colors.white54,
                                                      size: 20,
                                                    ),
                                                  ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  urunAdi,
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 14,
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
                                              ],
                                            ),
                                          ),
                                          Text(
                                            _price(satirToplam),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
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
                                        'Satıcı Alt Toplamı',
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 13,
                                        ),
                                      ),
                                      const Spacer(),
                                      Text(
                                        _price(altToplam),
                                        style: const TextStyle(
                                          color: Color(0xFFFFB300),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
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
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 16,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF101010),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0x22FFB300)),
              ),
              child: Row(
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Toplam Tutar',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Sipariş genel toplamı',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    _price(toplamTutar),
                    style: const TextStyle(
                      color: Color(0xFFFFB300),
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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
        centerTitle: true,
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
                padding: const EdgeInsets.all(24),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xFF151515),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0x22FFB300)),
                  ),
                  child: Text(
                    'Siparişler yüklenirken hata oluştu.\n\n${snapshot.error}',
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

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
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
                        Icons.receipt_long_outlined,
                        size: 40,
                        color: Color(0xFFFFB300),
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Henüz siparişiniz bulunmuyor',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Oluşturduğunuz siparişler burada listelenecek.',
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
            itemCount: docs.length,
            itemBuilder: (context, index) {
              return _buildSiparisKart(context, docs[index]);
            },
          );
        },
      ),
    );
  }
}

class OrderTimeline extends StatelessWidget {
  final String status;

  const OrderTimeline({
    super.key,
    required this.status,
  });

  int _activeStep(String status) {
    switch (status) {
      case 'pending':
      case 'created':
      case 'awaiting_payment':
        return 0;

      case 'paid':
      case 'payment_success':
      case 'accepted':
        return 1;

      case 'preparing':
      case 'pending_vendor_approval':
        return 2;

      case 'ready':
        return 3;

      case 'assigned':
        return 4;

      case 'on_the_way':
        return 5;

      case 'delivered':
      case 'completed':
        return 6;

      default:
        return 0;
    }
  }

  String _timelineTitle(String status) {
    switch (status) {
      case 'pending':
      case 'created':
        return 'Siparişiniz alındı';

      case 'awaiting_payment':
        return 'Ödeme bekleniyor';

      case 'paid':
      case 'payment_success':
      case 'accepted':
        return 'Siparişiniz onaylandı';

      case 'pending_vendor_approval':
      case 'preparing':
        return 'Siparişiniz hazırlanıyor';

      case 'ready':
        return 'Siparişiniz hazır';

      case 'assigned':
        return 'Kurye atandı';

      case 'on_the_way':
        return 'Kurye yola çıktı';

      case 'delivered':
      case 'completed':
        return 'Sipariş teslim edildi';

      case 'cancelled':
        return 'Sipariş iptal edildi';

      default:
        return 'Sipariş durumu';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (status == 'cancelled') {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.redAccent.withValues(alpha: 0.45)),
        ),
        child: const Row(
          children: [
            Icon(Icons.cancel, color: Colors.redAccent),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Sipariş İptal Edildi',
                style: TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final activeStep = _activeStep(status);

    const labels = [
      'Alındı',
      'Onay',
      'Hazırlık',
      'Hazır',
      'Kurye',
      'Yolda',
      'Teslim',
    ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x33FFB300)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _timelineTitle(status),
            style: const TextStyle(
              color: Color(0xFFFFB300),
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: List.generate(labels.length * 2 - 1, (index) {
              if (index.isEven) {
                final stepIndex = index ~/ 2;
                final isActive = stepIndex <= activeStep;

                return Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color:
                        isActive ? const Color(0xFFFFB300) : Colors.transparent,
                    border: Border.all(
                      color: const Color(0xFFFFB300),
                      width: 2,
                    ),
                  ),
                  child: isActive
                      ? const Center(
                          child: Icon(
                            Icons.check,
                            size: 11,
                            color: Colors.black,
                          ),
                        )
                      : null,
                );
              }

              final leftStep = index ~/ 2;
              final isActive = leftStep < activeStep;

              return Expanded(
                child: Container(
                  height: 3,
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  decoration: BoxDecoration(
                    color: isActive ? const Color(0xFFFFB300) : Colors.white24,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: labels
                .map(
                  (label) => Expanded(
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}
