import 'package:cloud_firestore/cloud_firestore.dart';

class KuryeTeslimServisi {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<void> teslimEt({
    required String orderId,
  }) async {
    final orderRef = _firestore.collection('orders').doc(orderId);

    await _firestore.runTransaction((transaction) async {
      final orderSnap = await transaction.get(orderRef);

      if (!orderSnap.exists) {
        throw Exception('Sipariş bulunamadı.');
      }

      final orderData = orderSnap.data() as Map<String, dynamic>;

      final String status = (orderData['status'] ?? orderData['durum'] ?? '')
          .toString()
          .trim()
          .toLowerCase();

      final String courierId =
          (orderData['assignedCourierId'] ?? '').toString().trim();

      final String courierName =
          (orderData['assignedCourierName'] ?? '').toString().trim();

      final String siparisNo =
          (orderData['siparisNo'] ?? orderId).toString().trim();

      if (courierId.isEmpty) {
        throw Exception('Bu siparişe atanmış kurye yok.');
      }

      if (status == 'delivered') {
        throw Exception('Bu sipariş zaten teslim edilmiş.');
      }

      final courierRef = _firestore.collection('couriers').doc(courierId);
      final courierSnap = await transaction.get(courierRef);

      if (!courierSnap.exists) {
        throw Exception('Atanmış kurye kaydı bulunamadı.');
      }

      final courierData = courierSnap.data() as Map<String, dynamic>;
      final int toplamTeslimat = _toInt(courierData['toplamTeslimat']);

      transaction.update(orderRef, {
        'status': 'delivered',
        'durum': 'delivered',
        'assignmentStatus': 'completed',
        'courierOfferStatus': 'accepted',
        'deliveryCompletedAt': FieldValue.serverTimestamp(),
        'deliveredAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      transaction.update(courierRef, {
        'aktifSiparis': 0,
        'toplamTeslimat': toplamTeslimat + 1,
        'currentOrderId': null,
        'availability': 'musait',
        'uygunlukDurumu': 'musait',
        'uygunluk': 'Müsait',
        'aktifMi': true,
        'isActive': true,
        'lastDeliveredAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      final timelineRef = _firestore.collection('orderTimeline').doc();

      transaction.set(timelineRef, {
        'orderId': orderId,
        'siparisNo': siparisNo,
        'status': 'delivered',
        'actorType': 'courier',
        'actorId': courierId,
        'actorName': courierName,
        'note': 'Sipariş teslim edildi',
        'createdAt': FieldValue.serverTimestamp(),
      });
    });
  }

  static int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }
}
