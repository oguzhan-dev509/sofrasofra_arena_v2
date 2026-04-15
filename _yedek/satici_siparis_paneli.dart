import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class SaticiSiparisPaneli extends StatefulWidget {
  final String sellerId;
  final String sellerName;

  SaticiSiparisPaneli({
    super.key,
    required this.sellerId,
    this.sellerName = 'Satıcı Paneli',
  });

  @override
  State<SaticiSiparisPaneli> createState() => _SaticiSiparisPaneliState();
}

class _SaticiSiparisPaneliState extends State<SaticiSiparisPaneli> {
  static const Color _bg = Color(0xFF111111);
  static const Color _card = Color(0xFF1C1C1E);
  static const Color _gold = Color(0xFFFFB300);
  static const Color _text = Colors.white;
  static const Color _muted = Color(0xFFBDBDBD);

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<QuerySnapshot<Map<String, dynamic>>> _ordersStream() {
    return _firestore
        .collection('orders')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  List<Map<String, dynamic>> _extractSellerItems(
    Map<String, dynamic> data,
    String sellerId,
  ) {
    final rawItems = data['items'];
    if (rawItems is! List) return [];

    return rawItems
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .where((item) {
      final itemSellerId = (item['saticiId'] ??
              item['sellerId'] ??
              item['merchantId'] ??
              item['satici'] ??
              '')
          .toString()
          .trim();

      return itemSellerId == sellerId;
    }).toList();
  }

  double _sellerTotal(List<Map<String, dynamic>> items) {
    double total = 0;
    for (final item in items) {
      final fiyat = (item['fiyat'] ?? 0);
      final adet = (item['adet'] ?? 0);

      final double fiyatValue =
          fiyat is num ? fiyat.toDouble() : double.tryParse('$fiyat') ?? 0;
      final int adetValue =
          adet is num ? adet.toInt() : int.tryParse('$adet') ?? 0;

      total += fiyatValue * adetValue;
    }
    return total;
  }

  String _formatMoney(num value) {
    if (value % 1 == 0) return '${value.toInt()} ₺';
    return '${value.toStringAsFixed(2)} ₺';
  }

  String _statusText(String status) {
    switch (status.trim()) {
      case 'pending':
        return 'Yeni Sipariş';
      case 'accepted':
        return 'Kabul Edildi';
      case 'preparing':
        return 'Hazırlanıyor';
      case 'ready':
        return 'Hazır';
      case 'on_the_way':
        return 'Yolda';
      case 'delivered':
        return 'Teslim Edildi';
      default:
        return status;
    }
  }

  Color _statusColor(String status) {
    switch (status.trim()) {
      case 'pending':
        return Colors.orange;
      case 'accepted':
        return Colors.lightBlueAccent;
      case 'preparing':
        return _gold;
      case 'ready':
        return Colors.greenAccent;
      case 'on_the_way':
        return Colors.cyanAccent;
      case 'delivered':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Future<void> _updateOrderStatus({
    required String orderId,
    required String newStatus,
  }) async {
    try {
      await _firestore.collection('orders').doc(orderId).update({
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Sipariş durumu güncellendi: ${_statusText(newStatus)}'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Durum güncellenemedi: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildActionButtons({
    required String orderId,
    required String status,
  }) {
    final s = status.trim();

    if (s == 'pending') {
      return Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: () => _updateOrderStatus(
                orderId: orderId,
                newStatus: 'accepted',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _gold,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('Kabul Et'),
            ),
          ),
        ],
      );
    }

    if (s == 'accepted') {
      return Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: () => _updateOrderStatus(
                orderId: orderId,
                newStatus: 'preparing',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _gold,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('Hazırlanıyor Yap'),
            ),
          ),
        ],
      );
    }

    if (s == 'preparing') {
      return Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: () => _updateOrderStatus(
                orderId: orderId,
                newStatus: 'ready',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('Hazır Yap'),
            ),
          ),
        ],
      );
    }

    if (s == 'ready') {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
        decoration: BoxDecoration(
          color: Colors.green.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green),
        ),
        child: const Text(
          'Sipariş hazır. Kurye / teslim sürecine geçebilir.',
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    if (s == 'on_the_way') {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
        decoration: BoxDecoration(
          color: Colors.cyan.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.cyan),
        ),
        child: const Text(
          'Sipariş yolda.',
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    if (s == 'delivered') {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
        decoration: BoxDecoration(
          color: Colors.green.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green),
        ),
        child: const Text(
          'Sipariş teslim edildi.',
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildItemCard(Map<String, dynamic> item) {
    final urunAdi = (item['urunAdi'] ?? 'Ürün').toString();
    final adet = (item['adet'] ?? 0).toString();
    final fiyatRaw = item['fiyat'] ?? 0;
    final gorselUrl = (item['gorselUrl'] ?? '').toString();

    final double fiyat = fiyatRaw is num
        ? fiyatRaw.toDouble()
        : double.tryParse('$fiyatRaw') ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2D),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: gorselUrl.isNotEmpty
                ? Image.network(
                    gorselUrl,
                    width: 64,
                    height: 64,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 64,
                      height: 64,
                      color: Colors.white10,
                      child: const Icon(Icons.image_not_supported,
                          color: Colors.white54),
                    ),
                  )
                : Container(
                    width: 64,
                    height: 64,
                    color: Colors.white10,
                    child: const Icon(Icons.fastfood, color: Colors.white54),
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
                    color: _text,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$adet adet',
                  style: const TextStyle(
                    color: _muted,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Text(
            _formatMoney(fiyat),
            style: const TextStyle(
              color: _gold,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final sellerItems = _extractSellerItems(data, widget.sellerId);

    if (sellerItems.isEmpty) {
      return const SizedBox.shrink();
    }

    final status = (data['status'] ?? 'pending').toString();
    final adres = (data['adres'] ?? 'Adres yok').toString();
    final telefon = (data['telefon'] ?? '-').toString();
    final odeme =
        (data['paymentMethodLabel'] ?? data['paymentMethod'] ?? '-').toString();
    final teslimat =
        (data['deliveryTypeLabel'] ?? data['deliveryType'] ?? 'Teslimat')
            .toString();

    final ts = data['createdAt'];
    String tarihText = '-';
    if (ts is Timestamp) {
      final dt = ts.toDate();
      tarihText =
          '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year} '
          '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }

    final sellerSubtotal = _sellerTotal(sellerItems);

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            runSpacing: 10,
            spacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                'Sipariş No: ${doc.id}',
                style: const TextStyle(
                  color: _text,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: _statusColor(status).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: _statusColor(status)),
                ),
                child: Text(
                  _statusText(status),
                  style: TextStyle(
                    color: _statusColor(status),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            tarihText,
            style: const TextStyle(color: _muted),
          ),
          const SizedBox(height: 16),
          _infoRow(Icons.location_on_outlined, 'Adres: $adres'),
          const SizedBox(height: 8),
          _infoRow(Icons.phone_outlined, 'Telefon: $telefon'),
          const SizedBox(height: 8),
          _infoRow(Icons.payments_outlined, 'Ödeme: $odeme'),
          const SizedBox(height: 8),
          _infoRow(Icons.local_shipping_outlined, 'Teslimat: $teslimat'),
          const SizedBox(height: 18),
          const Text(
            'Sipariş Kalemleri',
            style: TextStyle(
              color: _gold,
              fontWeight: FontWeight.bold,
              fontSize: 17,
            ),
          ),
          const SizedBox(height: 12),
          ...sellerItems.map(_buildItemCard),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              'Satıcı Alt Toplamı: ${_formatMoney(sellerSubtotal)}',
              style: const TextStyle(
                color: _gold,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 18),
          _buildActionButtons(orderId: doc.id, status: status),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: _gold, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: _text,
              fontSize: 15,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        foregroundColor: _gold,
        centerTitle: true,
        title: Text(widget.sellerName),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _ordersStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Hata oluştu:\n${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.redAccent),
                ),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: _gold),
            );
          }

          final docs = snapshot.data?.docs ?? [];

          final filtered = docs.where((doc) {
            final data = doc.data();
            final sellerItems = _extractSellerItems(data, widget.sellerId);
            return sellerItems.isNotEmpty;
          }).toList();

          if (filtered.isEmpty) {
            return const Center(
              child: Text(
                'Bu satıcıya ait sipariş bulunamadı.',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              return _buildOrderCard(filtered[index]);
            },
          );
        },
      ),
    );
  }
}
