import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class EvFislerSayfasi extends StatelessWidget {
  final String sellerId;
  final String sellerName;

  const EvFislerSayfasi({
    super.key,
    required this.sellerId,
    this.sellerName = 'Ev Lezzetleri',
  });

  static const Color _bg = Color(0xFF0F0F10);
  static const Color _card = Color(0xFF17181C);
  static const Color _gold = Color(0xFFFFD54F);

  String _text(
    dynamic value, {
    String fallback = '',
  }) {
    final result = (value ?? '').toString().trim();
    return result.isEmpty ? fallback : result;
  }

  double _number(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse((value ?? '').toString()) ?? 0;
  }

  int _integer(dynamic value) {
    if (value is num) {
      return value.toInt();
    }

    return int.tryParse((value ?? '').toString()) ?? 0;
  }

  String _money(dynamic value) {
    final amount = _number(value);

    if (amount % 1 == 0) {
      return '${amount.toStringAsFixed(0)} TL';
    }

    return '${amount.toStringAsFixed(2)} TL';
  }

  List<Map<String, dynamic>> _mapList(dynamic value) {
    if (value is! List) {
      return <Map<String, dynamic>>[];
    }

    return value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  String _statusLabel(dynamic rawStatus) {
    final status = _text(rawStatus).toLowerCase();

    switch (status) {
      case 'pending_vendor_approval':
        return 'Üretici Onayı Bekleniyor';
      case 'approved':
        return 'Onaylandı';
      case 'paid':
      case 'payment_success':
        return 'Ödeme Başarılı';
      case 'payment_failed':
        return 'Ödeme Başarısız';
      case 'preparing':
        return 'Hazırlanıyor';
      case 'ready':
        return 'Hazır';
      case 'courier_pending':
      case 'waiting_courier':
        return 'Kurye Bekleniyor';
      case 'assigned':
        return 'Kurye Atandı';
      case 'picked_up':
        return 'Kurye Teslim Aldı';
      case 'on_the_way':
        return 'Kurye Yolda';
      case 'delivered':
      case 'completed':
        return 'Teslim Edildi';
      case 'rejected':
        return 'Reddedildi';
      case 'cancelled':
        return 'İptal Edildi';
      default:
        return status.isEmpty ? 'Beklemede' : rawStatus.toString();
    }
  }

  String _deliveryLabel(dynamic rawMode) {
    final mode = _text(rawMode).toLowerCase();

    switch (mode) {
      case 'gel_al':
      case 'gel-al':
        return 'Gel-Al';
      case 'gotur':
      case 'götür':
      case 'platform_kurye':
        return 'Götür / Platform Kurye';
      case 'satici_kuryesi':
        return 'Götür / Üretici Kuryesi';
      default:
        return mode.isEmpty ? '-' : rawMode.toString();
    }
  }

  String _address(Map<String, dynamic> data) {
    final direct = _text(
      data['teslimatAdresi'] ??
          data['deliveryAddress'] ??
          data['adres'] ??
          data['address'],
    );

    if (direct.isNotEmpty) {
      return direct;
    }

    final rawMap = data['deliveryAddressData'] ?? data['addressData'];

    if (rawMap is Map) {
      final map = Map<String, dynamic>.from(rawMap);

      final nested = _text(
        map['fullAddress'] ?? map['address'] ?? map['adres'],
      );

      if (nested.isNotEmpty) {
        return nested;
      }
    }

    final district = _text(data['district'] ?? data['ilce']);
    final city = _text(data['city'] ?? data['sehir']);

    final parts = <String>[
      if (district.isNotEmpty) district,
      if (city.isNotEmpty) city,
    ];

    return parts.isEmpty ? '-' : parts.join(' / ');
  }

  List<Map<String, dynamic>> _items(Map<String, dynamic> data) {
    final items = _mapList(
      data['items'] ?? data['urunler'] ?? data['orderItems'],
    );

    if (items.isNotEmpty) {
      return items;
    }

    final title = _text(
      data['title'] ?? data['urunAdi'] ?? data['productName'],
    );

    if (title.isEmpty) {
      return <Map<String, dynamic>>[];
    }

    return <Map<String, dynamic>>[
      {
        'title': title,
        'quantity': data['quantity'] ?? data['adet'] ?? 1,
        'price': data['price'] ?? data['birimFiyat'] ?? 0,
        'total': data['total'] ?? data['toplam'] ?? 0,
      },
    ];
  }

  String _dateText(dynamic rawDate) {
    if (rawDate is! Timestamp) {
      return '-';
    }

    final date = rawDate.toDate();

    return '${date.day.toString().padLeft(2, '0')}.'
        '${date.month.toString().padLeft(2, '0')}.'
        '${date.year} '
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }

  Widget _line(
    String label,
    String value, {
    bool highlight = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 135,
            child: Text(
              label,
              style: TextStyle(
                color: highlight ? _gold : Colors.white60,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.trim().isEmpty ? '-' : value,
              style: TextStyle(
                color: highlight ? _gold : Colors.white,
                fontWeight: highlight ? FontWeight.w900 : FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _productLine(Map<String, dynamic> item) {
    final title = _text(
      item['title'] ?? item['name'] ?? item['urunAdi'],
      fallback: 'Ürün',
    );

    final quantity = _integer(
      item['quantity'] ?? item['adet'] ?? 1,
    );

    final price = _number(
      item['price'] ?? item['birimFiyat'] ?? item['unitPrice'],
    );

    final total = _number(
      item['total'] ?? item['toplam'] ?? item['lineTotal'],
    );

    final effectiveTotal = total > 0 ? total : price * quantity;

    return Container(
      margin: const EdgeInsets.only(bottom: 7),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '$quantity × $title',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            _money(effectiveTotal),
            style: const TextStyle(
              color: _gold,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  void _showReceipt({
    required BuildContext context,
    required String documentId,
    required Map<String, dynamic> data,
  }) {
    final orderId = _text(
      data['orderId'],
      fallback: documentId,
    );

    final orderNo = _text(
      data['siparisNo'] ?? data['orderNumber'] ?? data['orderNo'],
      fallback: orderId,
    );

    final resolvedSellerName = _text(
      data['saticiAdi'] ??
          data['sellerName'] ??
          data['dukkanAdi'] ??
          data['storeName'],
      fallback: sellerName,
    );

    final customerName = _text(
      data['musteriAd'] ?? data['customerName'] ?? data['adSoyad'],
      fallback: 'Müşteri',
    );

    final customerPhone = _text(
      data['musteriTelefon'] ?? data['customerPhone'] ?? data['telefon'],
    );

    final orderStatus = _statusLabel(
      data['orderStatus'] ?? data['status'] ?? data['durum'],
    );

    final paymentStatus = _statusLabel(
      data['paymentStatus'] ?? data['odemeDurumu'],
    );

    final products = _items(data);

    final subtotal = _number(
      data['araToplam'] ??
          data['subtotal'] ??
          data['productTotal'] ??
          data['totalPrice'],
    );

    final addonsTotal = _number(
      data['addonsTotal'] ?? data['yanUrunToplami'],
    );

    final deliveryFee = _number(
      data['teslimatUcreti'] ?? data['deliveryFee'] ?? data['courierFee'],
    );

    final total = _number(
      data['genelToplam'] ?? data['totalAmount'] ?? data['totalPrice'],
    );

    final effectiveTotal =
        total > 0 ? total : subtotal + addonsTotal + deliveryFee;

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: _card,
          title: const Text(
            'Fiş / Çıktı Önizleme',
            style: TextStyle(
              color: _gold,
              fontWeight: FontWeight.w900,
            ),
          ),
          content: SizedBox(
            width: 560,
            child: SingleChildScrollView(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _gold.withValues(alpha: 0.24),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Center(
                      child: Text(
                        'SOFRASOFRA EV LEZZETLERİ SİPARİŞ FİŞİ',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _gold,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _line('Sipariş No', orderNo, highlight: true),
                    _line(
                      'Sipariş Tarihi',
                      _dateText(data['createdAt']),
                    ),
                    _line('Ev Lezzetleri', resolvedSellerName),
                    _line('Müşteri', customerName),
                    if (customerPhone.isNotEmpty)
                      _line('Telefon', customerPhone),
                    _line(
                      'Teslimat',
                      _deliveryLabel(
                        data['deliveryMode'] ??
                            data['teslimatModu'] ??
                            data['siparisTipi'],
                      ),
                    ),
                    _line('Teslimat Adresi', _address(data)),
                    _line('Sipariş Durumu', orderStatus),
                    _line('Ödeme Durumu', paymentStatus),
                    const Divider(color: Colors.white24),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'ÜRÜNLER',
                        style: TextStyle(
                          color: _gold,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    if (products.isEmpty)
                      const Text(
                        'Ürün bilgisi bulunamadı.',
                        style: TextStyle(color: Colors.white54),
                      )
                    else
                      ...products.map(_productLine),
                    const Divider(color: Colors.white24),
                    _line('Ara Toplam', _money(subtotal)),
                    if (addonsTotal > 0)
                      _line('Yan Ürünler', _money(addonsTotal)),
                    _line('Teslimat Ücreti', _money(deliveryFee)),
                    _line(
                      'Genel Toplam',
                      _money(effectiveTotal),
                      highlight: true,
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Kapat'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final normalizedSellerId = sellerId.trim();

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: _gold),
        title: const Text(
          'Siparişlerim / Fişlerim',
          style: TextStyle(
            color: _gold,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: normalizedSellerId.isEmpty
          ? const Center(
              child: Text(
                'Dükkân kimliği bulunamadı.',
                style: TextStyle(color: Colors.white),
              ),
            )
          : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('sellerOrders')
                  .where(
                    'saticiId',
                    isEqualTo: normalizedSellerId,
                  )
                  .orderBy(
                    'createdAt',
                    descending: true,
                  )
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Fişler yüklenemedi:\n${snapshot.error}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.redAccent,
                        ),
                      ),
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: _gold,
                    ),
                  );
                }

                final docs = snapshot.data?.docs ?? [];

                if (docs.isEmpty) {
                  return const Center(
                    child: Text(
                      'Bu dükkâna ait sipariş veya fiş bulunamadı.',
                      style: TextStyle(color: Colors.white70),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data();

                    final orderNo = _text(
                      data['siparisNo'] ??
                          data['orderNumber'] ??
                          data['orderNo'] ??
                          data['orderId'],
                      fallback: doc.id,
                    );

                    final total = _number(
                      data['genelToplam'] ??
                          data['totalAmount'] ??
                          data['totalPrice'],
                    );

                    final customerName = _text(
                      data['musteriAd'] ??
                          data['customerName'] ??
                          data['adSoyad'],
                      fallback: 'Müşteri',
                    );

                    return Card(
                      color: _card,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Sipariş: $orderNo',
                              style: const TextStyle(
                                color: _gold,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              customerName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              _statusLabel(
                                data['orderStatus'] ?? data['status'],
                              ),
                              style: const TextStyle(
                                color: Colors.white70,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              _money(total),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 12),
                            OutlinedButton.icon(
                              onPressed: () {
                                _showReceipt(
                                  context: context,
                                  documentId: doc.id,
                                  data: data,
                                );
                              },
                              icon: const Icon(
                                Icons.receipt_long_outlined,
                              ),
                              label: const Text('Fiş / Çıktı'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: _gold,
                                side: const BorderSide(
                                  color: _gold,
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
            ),
    );
  }
}
