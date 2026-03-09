import 'package:cloud_firestore/cloud_firestore.dart';

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
  }
}
