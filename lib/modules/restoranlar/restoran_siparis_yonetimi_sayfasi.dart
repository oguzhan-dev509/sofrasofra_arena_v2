import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:sofrasofra_arena_v2/services/platform_admin_service.dart';
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

  Future<bool> _canManageRestaurantOrders() async {
    final isPlatformAdmin =
        await PlatformAdminService.isCurrentUserPlatformAdmin();

    if (isPlatformAdmin) {
      return true;
    }

    final currentUid = (FirebaseAuth.instance.currentUser?.uid ?? '').trim();

    if (currentUid.isEmpty) {
      return false;
    }

    final restaurantSnap = await FirebaseFirestore.instance
        .collection('restaurants')
        .doc(restaurantId)
        .get();

    final ownerUid =
        (restaurantSnap.data()?['ownerUid'] ?? '').toString().trim();

    return ownerUid == currentUid;
  }

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
      case 'courier_pending':
        return 'Kurye bekleniyor';
      case 'waiting_vendor_ready':
        return 'Restoran hazır, kurye bekleniyor';
      case 'waiting_courier':
        return 'Kurye bekleniyor';
      case 'not_required':
        return 'Kurye gerekmez';
      case 'retry_scheduled':
        return 'Kurye Yeniden Aranıyor';
      case 'manual_review_required':
        return 'Operasyon Kontrolünde';
      case 'no_courier_found':
      case 'not_assigned_after_ready':
        return 'Kurye Bulunamadı';
      case 'assigned':
        return 'Kurye Atandı';
      case 'on_the_way':
        return 'Kurye Yolda';
      case 'picked_up':
        return 'Kurye teslim aldı';
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

    if (saticiId != restaurantId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bu sipariş bu restorana ait değil.'),
        ),
      );
      return;
    }

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

  Widget _receiptButton({
    required BuildContext context,
    required QueryDocumentSnapshot<Map<String, dynamic>> doc,
  }) {
    return OutlinedButton.icon(
      onPressed: () {
        _showReceiptPreviewDialog(
          context: context,
          doc: doc,
        );
      },
      icon: const Icon(Icons.receipt_long_outlined),
      label: const Text('Fiş / Çıktı'),
      style: OutlinedButton.styleFrom(
        foregroundColor: _gold,
        side: BorderSide(
          color: _gold.withValues(alpha: 0.7),
        ),
        textStyle: const TextStyle(
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _receiptLine(
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
            width: 130,
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
              value.isEmpty ? '-' : value,
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

  void _showReceiptPreviewDialog({
    required BuildContext context,
    required QueryDocumentSnapshot<Map<String, dynamic>> doc,
  }) {
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
    final itemCount = data['urunSayisi']?.toString() ?? '-';

    final preparationMinutes = (data['preparationMinutes'] as num?)?.toInt();

    final estimatedReadyAt = data['estimatedReadyAt'] as Timestamp?;

    final kuryeAdi = _safeString(
      data['assignedCourierName'] ?? data['courierName'] ?? data['kuryeAdi'],
    );

    final kuryeTelefon = _safeString(
      data['courierPhone'] ?? data['kuryeTelefon'],
    );

    final rawCourierStatus = _safeString(
      data['assignmentStatus'] ??
          data['courierAssignmentStatus'] ??
          data['courierAssignmentResult'],
    );

    final courierStatus = rawCourierStatus.isEmpty && kuryeAdi.isNotEmpty
        ? 'assigned'
        : rawCourierStatus.isEmpty
            ? 'courier_pending'
            : rawCourierStatus;

    final estimatedReadyText = estimatedReadyAt == null
        ? '-'
        : TimeOfDay.fromDateTime(estimatedReadyAt.toDate()).format(context);

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
            width: 520,
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
                        'SOFRASOFRA RESTORAN SİPARİŞ FİŞİ',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _gold,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _receiptLine('Sipariş No', siparisNo, highlight: true),
                    _receiptLine('Restoran', restaurantName),
                    _receiptLine(
                      'Müşteri',
                      '$customerName${customerPhone.isNotEmpty ? ' • $customerPhone' : ''}',
                    ),
                    _receiptLine('Teslimat', _deliveryLabel(deliveryMode)),
                    _receiptLine('Ürün Sayısı', itemCount),
                    _receiptLine(
                      'Toplam',
                      '${total.toStringAsFixed(0)} TL',
                      highlight: true,
                    ),
                    _receiptLine(
                      'Hazırlama',
                      preparationMinutes == null
                          ? '-'
                          : '$preparationMinutes dakika',
                    ),
                    _receiptLine('Tahmini Hazır', estimatedReadyText),
                    _receiptLine('Sipariş Durumu', _statusLabel(status)),
                    _receiptLine('Kurye Durumu', _statusLabel(courierStatus)),
                    if (kuryeAdi.isNotEmpty) _receiptLine('Kurye', kuryeAdi),
                    if (kuryeTelefon.isNotEmpty)
                      _receiptLine('Kurye Tel', kuryeTelefon),
                    const SizedBox(height: 12),
                    const Divider(color: Colors.white24),
                    const SizedBox(height: 8),
                    const Text(
                      'Not: Bu ekran ilk faz fiş önizlemesidir. Tarayıcıdan yazdırma entegrasyonu sonraki adımda eklenecektir.',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
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
          _receiptButton(
            context: context,
            doc: doc,
          ),
        ],
      );
    }

    if (status == 'preparing') {
      return Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          ElevatedButton.icon(
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
          ),
          _receiptButton(
            context: context,
            doc: doc,
          ),
        ],
      );
    }

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          _statusLabel(status),
          style: const TextStyle(
            color: Colors.white70,
            fontWeight: FontWeight.w800,
          ),
        ),
        _receiptButton(
          context: context,
          doc: doc,
        ),
      ],
    );
  }

  Widget _buildSelectedAddonsList(dynamic rawAddons) {
    if (rawAddons is! List || rawAddons.isEmpty) {
      return const SizedBox.shrink();
    }

    final addons = rawAddons
        .whereType<Map>()
        .map((addon) => Map<String, dynamic>.from(addon))
        .toList();

    if (addons.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: addons.map((addon) {
          final name = (addon['name'] ?? 'Yan ürün').toString().trim();
          final quantity =
              int.tryParse((addon['quantity'] ?? 1).toString()) ?? 1;

          final rawPrice = addon['price'];
          final num price = rawPrice is num
              ? rawPrice
              : num.tryParse(rawPrice?.toString() ?? '') ?? 0;

          final priceText = price % 1 == 0
              ? price.toStringAsFixed(0)
              : price.toStringAsFixed(2);

          return Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              '+ $quantity x $name • $priceText TL',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.72),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          );
        }).toList(),
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

    final kuryeAdi = _safeString(
      data['assignedCourierName'] ?? data['courierName'] ?? data['kuryeAdi'],
    );

    final kuryeTelefon = _safeString(
      data['courierPhone'] ?? data['kuryeTelefon'],
    );

    final rawCourierStatus = _safeString(
      data['assignmentStatus'] ??
          data['courierAssignmentStatus'] ??
          data['courierAssignmentResult'],
    );

    final courierStatus = rawCourierStatus.isEmpty && kuryeAdi.isNotEmpty
        ? 'assigned'
        : rawCourierStatus.isEmpty
            ? 'courier_pending'
            : rawCourierStatus;

    final platformKuryeAktif = data['platformKuryeAktif'] == true;

    final isDeliveryOrder = deliveryMode == 'gotur' ||
        deliveryMode == 'platform_kurye' ||
        deliveryMode == 'satici_kuryesi';

    final isPlatformCourier = isDeliveryOrder ||
        platformKuryeAktif ||
        rawCourierStatus.isNotEmpty ||
        kuryeAdi.isNotEmpty;
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
          if (isPlatformCourier) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _gold.withValues(alpha: 0.18),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Kurye Durumu: ${_statusLabel(courierStatus)}',
                    style: const TextStyle(
                      color: _gold,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  if (kuryeAdi.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Kurye: $kuryeAdi',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                  if (kuryeTelefon.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Kurye Tel: $kuryeTelefon',
                      style: const TextStyle(
                        color: Colors.white60,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
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
          _buildSelectedAddonsList(data['selectedAddons']),
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
      body: FutureBuilder<bool>(
        future: _canManageRestaurantOrders(),
        builder: (context, accessSnapshot) {
          if (!accessSnapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: _gold),
            );
          }

          if (accessSnapshot.data != true) {
            return Center(
              child: Container(
                margin: const EdgeInsets.all(24),
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: _card,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: Colors.redAccent.withValues(alpha: 0.35),
                  ),
                ),
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.lock_outline_rounded,
                      color: Colors.redAccent,
                      size: 42,
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Bu restoranın siparişlerini yönetme yetkiniz yok.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Lütfen doğru restoran sahibi hesabıyla giriş yapın.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white60,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
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
          );
        },
      ),
    );
  }
}
