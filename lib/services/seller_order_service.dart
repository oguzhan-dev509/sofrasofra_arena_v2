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
  }) async {
    final sellerOrderRef =
        _firestore.collection('sellerOrders').doc(sellerOrderId);

    final orderRef = _firestore.collection('orders').doc(orderId);

    final timelineRef = _firestore.collection('orderTimeline').doc();

    final batch = _firestore.batch();

    /// sellerOrders status
    batch.update(sellerOrderRef, {
      'status': status,
      'statusUpdatedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    /// ana order status
    batch.update(orderRef, {
      'status': status,
      'durum': status,
      'statusUpdatedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    /// timeline event
    batch.set(timelineRef, {
      'orderId': orderId,
      'siparisNo': siparisNo,
      'status': status,
      'actorType': 'seller',
      'actorId': saticiId,
      'createdAt': FieldValue.serverTimestamp(),
    });

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
