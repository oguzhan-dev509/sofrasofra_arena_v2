import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'package:sofrasofra_arena_v2/services/otomatik_kurye_atama_servisi.dart';

class SellerOrderService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<void> updateOrderStatus({
    required String sellerOrderId,
    required String orderId,
    required String siparisNo,
    required String status,
    required String saticiId,
    int? preparationMinutes,
    String? rejectionReason,
  }) async {
    final sellerOrderRef =
        _firestore.collection('sellerOrders').doc(sellerOrderId);

    final orderRef = _firestore.collection('orders').doc(orderId);

    final timelineRef = _firestore.collection('orderTimeline').doc();

    final batch = _firestore.batch();
    final sellerOrderUpdates = <String, dynamic>{
      'status': status,
      'durum': status,
      'statusUpdatedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    final orderUpdates = <String, dynamic>{
      'status': status,
      'durum': status,
      'statusUpdatedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    final timelineData = <String, dynamic>{
      'orderId': orderId,
      'siparisNo': siparisNo,
      'status': status,
      'actorType': 'seller',
      'actorId': saticiId,
      'createdAt': FieldValue.serverTimestamp(),
    };
    if (status == 'preparing' &&
        preparationMinutes != null &&
        preparationMinutes > 0) {
      final estimatedReadyAt = Timestamp.fromDate(
        DateTime.now().add(
          Duration(minutes: preparationMinutes),
        ),
      );

      sellerOrderUpdates.addAll({
        'acceptedAt': FieldValue.serverTimestamp(),
        'preparationMinutes': preparationMinutes,
        'estimatedReadyAt': estimatedReadyAt,
        'rejectionReason': FieldValue.delete(),
        'rejectedAt': FieldValue.delete(),
      });

      orderUpdates.addAll({
        'acceptedAt': FieldValue.serverTimestamp(),
        'preparationMinutes': preparationMinutes,
        'estimatedReadyAt': estimatedReadyAt,
        'rejectionReason': FieldValue.delete(),
        'rejectedAt': FieldValue.delete(),
      });

      timelineData.addAll({
        'preparationMinutes': preparationMinutes,
        'estimatedReadyAt': estimatedReadyAt,
        'note': 'Sipariş kabul edildi. Tahmini hazırlama süresi: '
            '$preparationMinutes dakika.',
      });
    }

    if (status == 'rejected') {
      final cleanReason = (rejectionReason ?? '').trim();

      sellerOrderUpdates.addAll({
        'rejectedAt': FieldValue.serverTimestamp(),
        'rejectionReason': cleanReason.isEmpty ? 'Belirtilmedi' : cleanReason,
      });

      orderUpdates.addAll({
        'rejectedAt': FieldValue.serverTimestamp(),
        'rejectionReason': cleanReason.isEmpty ? 'Belirtilmedi' : cleanReason,
      });

      timelineData.addAll({
        'rejectionReason': cleanReason.isEmpty ? 'Belirtilmedi' : cleanReason,
        'note': 'Sipariş restoran tarafından reddedildi.',
      });
    }

    /// sellerOrders status
    batch.update(sellerOrderRef, sellerOrderUpdates);
    batch.update(orderRef, orderUpdates);
    batch.set(timelineRef, timelineData);

    await batch.commit();

    // Üretici/satıcı "Hazır" dediğinde platform kurye atamasını başlat.
    // Böylece kurye, yemek hazırlanmadan önce siparişi görmez.
    if (status == 'ready') {
      await _startCourierAssignmentAfterVendorReady(orderRef, orderId);
    }
  }

  static Future<void> _startCourierAssignmentAfterVendorReady(
    DocumentReference<Map<String, dynamic>> orderRef,
    String orderId,
  ) async {
    try {
      final orderSnap = await orderRef.get();

      if (!orderSnap.exists) {
        debugPrint(
          'SellerOrderService: ready sonrası sipariş bulunamadı: $orderId',
        );
        return;
      }

      final orderData = orderSnap.data() ?? <String, dynamic>{};

      final deliveryMode = (orderData['deliveryMode'] ?? '').toString().trim();
      final platformKuryeAktif = orderData['platformKuryeAktif'] == true;

      final assignmentStatus =
          (orderData['assignmentStatus'] ?? '').toString().trim();

      final assignedCourierId =
          (orderData['assignedCourierId'] ?? '').toString().trim();

      final bool alreadyAssigned = assignedCourierId.isNotEmpty ||
          assignmentStatus == 'assigned' ||
          assignmentStatus == 'offer_sent' ||
          assignmentStatus == 'completed';

      if (deliveryMode != 'platform_kurye' ||
          !platformKuryeAktif ||
          alreadyAssigned) {
        return;
      }

      await orderRef.set({
        'assignmentStatus': 'waiting_courier',
        'courierAssignmentTriggered': true,
        'courierAssignmentCheckedAt': FieldValue.serverTimestamp(),
        'courierAssignmentResult': 'started_after_vendor_ready',
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      final assigned = await OtomatikKuryeAtamaServisi.sipariseKuryeAta(
        orderId: orderId,
      );

      await orderRef.set({
        'courierAssignmentResult':
            assigned ? 'assigned_or_offer_sent' : 'not_assigned_after_ready',
        'courierAssignmentCheckedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint(
        'SellerOrderService ready sonrası kurye atama hatası: $e',
      );

      await orderRef.set({
        'courierAssignmentResult': 'error_after_vendor_ready',
        'courierAssignmentError': e.toString(),
        'courierAssignmentCheckedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }
}
