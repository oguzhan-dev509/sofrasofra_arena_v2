import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:sofrasofra_arena_v2/services/seller_order_service.dart';

class RestoranSiparisYonetimiSayfasi extends StatelessWidget {
  const RestoranSiparisYonetimiSayfasi({
    super.key,
    required this.restaurantId,
    this.restaurantName = '',
  });

  final String restaurantId;
  final String restaurantName;
  static const Color _gold = Color(0xFFFFB300);
  static const Color _bg = Color(0xFF070707);
  static const Color _card = Color(0xFF111111);

  Stream<QuerySnapshot<Map<String, dynamic>>> _restaurantOrdersStream() {
    return FirebaseFirestore.instance
        .collection('sellerOrders')
        .where(
          'saticiId',
          isEqualTo: restaurantId,
        )
        .limit(100)
        .snapshots();
  }

  String _safeString(dynamic value, {String fallback = ''}) {
    final text = (value ?? '').toString().trim();
    return text.isEmpty ? fallback : text;
  }

  double _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse((value ?? '').toString()) ?? 0;
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'paid':
      case 'payment_success':
        return 'Ödeme Alındı';
      case 'preparing':
        return 'Hazırlanıyor';
      case 'ready':
        return 'Sipariş Hazır';
      case 'assigned':
        return 'Kurye Atandı';
      case 'on_the_way':
        return 'Kurye Yolda';
      case 'delivered':
      case 'completed':
        return 'Teslim Edildi';
      case 'rejected':
        return 'Restoran Reddetti';
      case 'cancelled':
        return 'İptal';
      default:
        return status.isEmpty ? 'Beklemede' : status;
    }
  }

  String _deliveryLabel(String deliveryMode) {
    switch (deliveryMode) {
      case 'gel_al':
        return 'Gel-Al';
      case 'platform_kurye':
        return 'Götür / Platform Kurye';
      case 'satici_kuryesi':
        return 'Götür / Restoran Kuryesi';
      default:
        return deliveryMode.isEmpty ? '-' : deliveryMode;
    }
  }

  Future<void> _updateStatus({
    required BuildContext context,
    required QueryDocumentSnapshot<Map<String, dynamic>> doc,
    required String nextStatus,
    int? preparationMinutes,
    String? rejectionReason,
  }) async {
    final data = doc.data();

    final orderId = _safeString(data['orderId']);
    final siparisNo = _safeString(data['siparisNo'], fallback: orderId);
    final saticiId = _safeString(data['saticiId']);

    if (orderId.isEmpty || saticiId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sipariş bilgisi eksik. Durum güncellenemedi.'),
        ),
      );
      return;
    }

    try {
      await SellerOrderService.updateOrderStatus(
        sellerOrderId: doc.id,
        orderId: orderId,
        siparisNo: siparisNo,
        status: nextStatus,
        saticiId: saticiId,
        preparationMinutes: preparationMinutes,
        rejectionReason: rejectionReason,
      );

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Sipariş durumu güncellendi: ${_statusLabel(nextStatus)}'),
        ),
      );
    } catch (error) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Durum güncellenemedi: $error'),
        ),
      );
    }
  }

  Future<void> _acceptOrderDialog({
    required BuildContext context,
    required QueryDocumentSnapshot<Map<String, dynamic>> doc,
  }) async {
    int selectedMinutes = 30;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: _card,
              title: const Text(
                'Siparişi Kabul Et',
                style: TextStyle(
                  color: _gold,
                  fontWeight: FontWeight.w900,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tahmini hazırlama süresini seçin.',
                    style: TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [15, 20, 30, 45, 60].map((minutes) {
                      return ChoiceChip(
                        label: Text('$minutes dk'),
                        selected: selectedMinutes == minutes,
                        onSelected: (_) {
                          setDialogState(() {
                            selectedMinutes = minutes;
                          });
                        },
                        selectedColor: _gold,
                        backgroundColor: Colors.black,
                        labelStyle: TextStyle(
                          color: selectedMinutes == minutes
                              ? Colors.black
                              : Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('Vazgeç'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _gold,
                    foregroundColor: Colors.black,
                  ),
                  child: const Text(
                    'Kabul Et ve Hazırlamaya Başla',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmed != true || !context.mounted) return;

    await _updateStatus(
      context: context,
      doc: doc,
      nextStatus: 'preparing',
      preparationMinutes: selectedMinutes,
    );
  }

  Future<void> _rejectOrderDialog({
    required BuildContext context,
    required QueryDocumentSnapshot<Map<String, dynamic>> doc,
  }) async {
    String selectedReason = 'Ürün tükendi';

    const reasons = [
      'Ürün tükendi',
      'Restoran kapalı',
      'Yoğunluk nedeniyle hazırlanamıyor',
      'Sipariş bilgileri eksik',
      'Diğer',
    ];

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: _card,
              title: const Text(
                'Siparişi Reddet',
                style: TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.w900,
                ),
              ),
              content: DropdownButtonFormField<String>(
                initialValue: selectedReason,
                dropdownColor: _card,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
                decoration: const InputDecoration(
                  labelText: 'Ret nedeni',
                  labelStyle: TextStyle(color: Colors.white70),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white24),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.redAccent),
                  ),
                ),
                items: reasons
                    .map(
                      (reason) => DropdownMenuItem(
                        value: reason,
                        child: Text(reason),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value == null) return;

                  setDialogState(() {
                    selectedReason = value;
                  });
                },
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('Vazgeç'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text(
                    'Siparişi Reddet',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmed != true || !context.mounted) return;

    await _updateStatus(
      context: context,
      doc: doc,
      nextStatus: 'rejected',
      rejectionReason: selectedReason,
    );
  }

  Widget _actionButtons({
    required BuildContext context,
    required QueryDocumentSnapshot<Map<String, dynamic>> doc,
    required String status,
    required String deliveryMode,
  }) {
    if (status == 'paid' || status == 'payment_success') {
      return Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          ElevatedButton.icon(
            onPressed: () async {
              await _acceptOrderDialog(
                context: context,
                doc: doc,
              );
            },
            icon: const Icon(Icons.check_circle_outline),
            label: const Text('Kabul Et'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _gold,
              foregroundColor: Colors.black,
              textStyle: const TextStyle(
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          OutlinedButton.icon(
            onPressed: () async {
              await _rejectOrderDialog(
                context: context,
                doc: doc,
              );
            },
            icon: const Icon(Icons.cancel_outlined),
            label: const Text('Reddet'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.redAccent,
              side: const BorderSide(
                color: Colors.redAccent,
              ),
              textStyle: const TextStyle(
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      );
    }

    if (status == 'preparing') {
      return ElevatedButton.icon(
        onPressed: () async {
          await _updateStatus(
            context: context,
            doc: doc,
            nextStatus: 'ready',
          );
        },
        icon: const Icon(Icons.check_circle_outline),
        label: Text(
          deliveryMode == 'platform_kurye'
              ? 'Sipariş Hazır / Kurye Çağır'
              : 'Sipariş Hazır',
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: _gold,
          foregroundColor: Colors.black,
          textStyle: const TextStyle(fontWeight: FontWeight.w900),
        ),
      );
    }

    return Text(
      _statusLabel(status),
      style: const TextStyle(
        color: Colors.white70,
        fontWeight: FontWeight.w800,
      ),
    );
  }

  Widget _orderCard(
    BuildContext context,
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();

    final status = _safeString(data['status'] ?? data['durum']);
    final deliveryMode = _safeString(data['deliveryMode']);
    final siparisNo = _safeString(data['siparisNo'], fallback: doc.id);

    final restaurantName = _safeString(
      data['saticiAdi'] ?? data['restaurantName'] ?? data['dukkanAdi'],
      fallback: 'Restoran',
    );

    final customerName = _safeString(
      data['musteriAd'] ?? data['customerName'],
      fallback: 'Müşteri',
    );

    final customerPhone =
        _safeString(data['musteriTelefon'] ?? data['customerPhone']);

    final total = _asDouble(data['genelToplam'] ?? data['araToplam']);
    final itemCount = data['urunSayisi'] ?? '-';

    final preparationMinutes = (data['preparationMinutes'] as num?)?.toInt();

    final estimatedReadyAt = data['estimatedReadyAt'] as Timestamp?;

    final rejectionReason = _safeString(data['rejectionReason']);
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _gold.withValues(alpha: 0.24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.storefront, color: _gold),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  restaurantName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _gold.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: _gold.withValues(alpha: 0.35),
                  ),
                ),
                child: Text(
                  _statusLabel(status),
                  style: const TextStyle(
                    color: _gold,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Sipariş No: $siparisNo',
            style: const TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Teslimat: ${_deliveryLabel(deliveryMode)}',
            style: const TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Müşteri: $customerName${customerPhone.isNotEmpty ? ' • $customerPhone' : ''}',
            style: const TextStyle(
              color: Colors.white60,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Ürün sayısı: $itemCount • Toplam: ${total.toStringAsFixed(0)} TL',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (preparationMinutes != null && preparationMinutes > 0) ...[
            const SizedBox(height: 6),
            Text(
              'Hazırlama süresi: $preparationMinutes dakika',
              style: const TextStyle(
                color: _gold,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
          if (estimatedReadyAt != null) ...[
            const SizedBox(height: 6),
            Text(
              'Tahmini hazır: '
              '${TimeOfDay.fromDateTime(estimatedReadyAt.toDate()).format(context)}',
              style: const TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          if (status == 'rejected' && rejectionReason.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'Ret nedeni: $rejectionReason',
              style: const TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
          const SizedBox(height: 14),
          _actionButtons(
            context: context,
            doc: doc,
            status: status,
            deliveryMode: deliveryMode,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: _gold),
        title: const Text(
          'Restoran Sipariş Yönetimi',
          style: TextStyle(
            color: _gold,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _restaurantOrdersStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Restoran siparişleri okunamadı:\n${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70),
                ),
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: _gold),
            );
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(
              child: Text(
                'Henüz restoran siparişi bulunmuyor.',
                style: TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.w700,
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              return _orderCard(context, docs[index]);
            },
          );
        },
      ),
    );
  }
}
