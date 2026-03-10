import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';

class KuryeDispatchEngine {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Ana fonksiyon:
  /// Verilen sipariş için en yakın uygun kuryeyi bulur ve atar.
  Future<bool> assignNearestCourier({
    required String orderId,
  }) async {
    try {
      final orderRef = _firestore.collection('orders').doc(orderId);
      final orderSnap = await orderRef.get();

      if (!orderSnap.exists) {
        print('KuryeDispatchEngine: Sipariş bulunamadı -> $orderId');
        return false;
      }

      final orderData = orderSnap.data() as Map<String, dynamic>;

      final double? orderLat = _toDouble(orderData['lat']);
      final double? orderLng = _toDouble(orderData['lng']);

      if (orderLat == null || orderLng == null) {
        print('KuryeDispatchEngine: Sipariş konumu eksik -> $orderId');
        return false;
      }

      final String currentStatus = (orderData['status'] ?? '').toString();

      // Sadece uygun durumdaysa atama yap
      if (currentStatus.isNotEmpty &&
          currentStatus != 'pending' &&
          currentStatus != 'waiting_courier') {
        print(
          'KuryeDispatchEngine: Sipariş durumu kurye atamaya uygun değil -> $currentStatus',
        );
        return false;
      }

      final couriersQuery = await _firestore
          .collection('couriers')
          .where('online', isEqualTo: true)
          .where('activeOrder', isEqualTo: false)
          .get();

      if (couriersQuery.docs.isEmpty) {
        print('KuryeDispatchEngine: Uygun kurye bulunamadı.');
        await orderRef.update({
          'status': 'waiting_courier',
          'updatedAt': FieldValue.serverTimestamp(),
        });
        return false;
      }

      QueryDocumentSnapshot<Map<String, dynamic>>? nearestCourier;
      double nearestDistanceKm = double.infinity;

      for (final courierDoc in couriersQuery.docs) {
        final courierData = courierDoc.data();

        final double? courierLat = _toDouble(courierData['lat']);
        final double? courierLng = _toDouble(courierData['lng']);

        if (courierLat == null || courierLng == null) continue;

        final double distanceKm = _calculateDistanceKm(
          orderLat,
          orderLng,
          courierLat,
          courierLng,
        );

        if (distanceKm < nearestDistanceKm) {
          nearestDistanceKm = distanceKm;
          nearestCourier = courierDoc;
        }
      }

      if (nearestCourier == null) {
        print('KuryeDispatchEngine: Konumu uygun kurye bulunamadı.');
        await orderRef.update({
          'status': 'waiting_courier',
          'updatedAt': FieldValue.serverTimestamp(),
        });
        return false;
      }

      final courierId = nearestCourier.id;
      final courierData = nearestCourier.data();
      final courierName = (courierData['name'] ?? 'Kurye').toString();

      final courierRef = _firestore.collection('couriers').doc(courierId);
      final courierOrderRef = _firestore.collection('courier_orders').doc();

      await _firestore.runTransaction((transaction) async {
        final freshOrderSnap = await transaction.get(orderRef);
        final freshCourierSnap = await transaction.get(courierRef);

        if (!freshOrderSnap.exists || !freshCourierSnap.exists) {
          throw Exception('Sipariş veya kurye transaction sırasında kayboldu.');
        }

        final freshOrderData =
            freshOrderSnap.data() as Map<String, dynamic>? ?? {};
        final freshCourierData =
            freshCourierSnap.data() as Map<String, dynamic>? ?? {};

        final freshOrderStatus = (freshOrderData['status'] ?? '').toString();
        final courierOnline = freshCourierData['online'] == true;
        final courierActiveOrder = freshCourierData['activeOrder'] == true;

        if (freshOrderStatus != 'pending' &&
            freshOrderStatus != 'waiting_courier') {
          throw Exception('Sipariş artık kurye atamaya uygun değil.');
        }

        if (!courierOnline || courierActiveOrder) {
          throw Exception('Seçilen kurye artık uygun değil.');
        }

        transaction.update(orderRef, {
          'assignedCourierId': courierId,
          'assignedCourierName': courierName,
          'courierAssignedAt': FieldValue.serverTimestamp(),
          'courierDistanceKm': nearestDistanceKm,
          'status': 'courier_assigned',
          'updatedAt': FieldValue.serverTimestamp(),
        });

        transaction.update(courierRef, {
          'activeOrder': true,
          'currentOrderId': orderId,
          'lastAssignedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        transaction.set(courierOrderRef, {
          'orderId': orderId,
          'courierId': courierId,
          'courierName': courierName,
          'status': 'assigned',
          'distanceKm': nearestDistanceKm,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });

      print(
        'KuryeDispatchEngine: Kurye atandı -> $courierName ($courierId), mesafe: ${nearestDistanceKm.toStringAsFixed(2)} km',
      );

      return true;
    } catch (e) {
      print('KuryeDispatchEngine HATA: $e');
      return false;
    }
  }

  /// Kurye siparişi kabul ettiğinde çağır.
  Future<void> courierAcceptOrder({
    required String orderId,
    required String courierId,
  }) async {
    try {
      final orderRef = _firestore.collection('orders').doc(orderId);
      final courierOrderQuery = await _firestore
          .collection('courier_orders')
          .where('orderId', isEqualTo: orderId)
          .where('courierId', isEqualTo: courierId)
          .limit(1)
          .get();

      await orderRef.update({
        'status': 'courier_accepted',
        'courierAcceptedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (courierOrderQuery.docs.isNotEmpty) {
        await courierOrderQuery.docs.first.reference.update({
          'status': 'accepted',
          'acceptedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      print('KuryeDispatchEngine: Kurye siparişi kabul etti.');
    } catch (e) {
      print('KuryeDispatchEngine courierAcceptOrder HATA: $e');
    }
  }

  /// Sipariş teslim edilince veya iptal edilince kuryeyi boşa çıkar.
  Future<void> releaseCourier({
    required String orderId,
    required String courierId,
    String newOrderStatus = 'delivered',
  }) async {
    try {
      final orderRef = _firestore.collection('orders').doc(orderId);
      final courierRef = _firestore.collection('couriers').doc(courierId);

      final courierOrderQuery = await _firestore
          .collection('courier_orders')
          .where('orderId', isEqualTo: orderId)
          .where('courierId', isEqualTo: courierId)
          .limit(1)
          .get();

      await _firestore.runTransaction((transaction) async {
        transaction.update(orderRef, {
          'status': newOrderStatus,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        transaction.update(courierRef, {
          'activeOrder': false,
          'currentOrderId': null,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        if (courierOrderQuery.docs.isNotEmpty) {
          transaction.update(courierOrderQuery.docs.first.reference, {
            'status': newOrderStatus,
            'completedAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      });

      print('KuryeDispatchEngine: Kurye serbest bırakıldı.');
    } catch (e) {
      print('KuryeDispatchEngine releaseCourier HATA: $e');
    }
  }

  double _calculateDistanceKm(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    const double earthRadiusKm = 6371;

    final dLat = _degToRad(lat2 - lat1);
    final dLng = _degToRad(lng2 - lng1);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degToRad(lat1)) *
            cos(_degToRad(lat2)) *
            sin(dLng / 2) *
            sin(dLng / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadiusKm * c;
  }

  double _degToRad(double deg) {
    return deg * pi / 180;
  }

  double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}
