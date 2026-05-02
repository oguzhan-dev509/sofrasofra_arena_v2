import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class KuryeDispatchEngine {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<bool> assignNearestCourier({
    required String orderId,
  }) async {
    try {
      final orderRef = _firestore.collection('orders').doc(orderId);
      final orderSnap = await orderRef.get();

      if (!orderSnap.exists) return false;

      final orderData = orderSnap.data() as Map<String, dynamic>;

      final double? orderLat = _toDouble(orderData['lat']);
      final double? orderLng = _toDouble(orderData['lng']);

      if (orderLat == null || orderLng == null) return false;

      final String orderSehir =
          (orderData['sehir'] ?? '').toString().toLowerCase().trim();

      final String orderIlce =
          (orderData['ilce'] ?? '').toString().toLowerCase().trim();

      final couriersQuery = await _firestore
          .collection('couriers')
          .where('aktifMi', isEqualTo: true)
          .get();

      if (couriersQuery.docs.isEmpty) {
        await orderRef.set({
          'status': 'waiting_courier',
          'assignmentStatus': 'waiting_courier',
        }, SetOptions(merge: true));
        return false;
      }

      QueryDocumentSnapshot<Map<String, dynamic>>? nearestCourier;
      double nearestDistance = double.infinity;

      for (final doc in couriersQuery.docs) {
        final data = doc.data();

        final String courierSehir =
            (data['sehir'] ?? '').toString().toLowerCase();

        final String courierIlce =
            (data['ilce'] ?? '').toString().toLowerCase();

        // 🔥 ŞEHİR FİLTRE
        if (courierSehir != orderSehir) continue;

        // 🔥 İLÇE FİLTRE (opsiyonel ama güçlü)
        if (orderIlce.isNotEmpty && courierIlce != orderIlce) continue;

        final String uygunluk =
            (data['uygunluk'] ?? '').toString().toLowerCase();

        if (!(uygunluk == 'müsait' || uygunluk == 'musait')) continue;

        int aktifSiparis = _toInt(data['aktifSiparis']);
        int maxAktif = _toInt(data['maxAktifSiparis'], defaultValue: 2);

        if (aktifSiparis >= maxAktif) continue;

        final double? lat = _toDouble(data['lat']);
        final double? lng = _toDouble(data['lng']);

        if (lat == null || lng == null) continue;

        final dist = _distance(orderLat, orderLng, lat, lng);

        if (dist < nearestDistance) {
          nearestDistance = dist;
          nearestCourier = doc;
        }
      }

      if (nearestCourier == null) {
        await orderRef.set({
          'status': 'waiting_courier',
          'assignmentStatus': 'waiting_courier',
        }, SetOptions(merge: true));
        return false;
      }

      final courierId = nearestCourier.id;

      final courierRef = _firestore.collection('couriers').doc(courierId);

      await _firestore.runTransaction((tx) async {
        final orderSnap = await tx.get(orderRef);
        final courierSnap = await tx.get(courierRef);

        if (!orderSnap.exists || !courierSnap.exists) return;

        final courier = courierSnap.data() as Map<String, dynamic>;

        int aktif = _toInt(courier['aktifSiparis']);

        tx.set(
            orderRef,
            {
              'assignedCourierId': courierId,
              'assignedCourierName': courier['adSoyad'] ?? 'Kurye',
              'assignmentStatus': 'assigned',
              'status': 'on_the_way',
              'courierDistanceKm': nearestDistance,
            },
            SetOptions(merge: true));

        tx.set(
            courierRef,
            {
              'aktifSiparis': aktif + 1,
              'uygunluk': 'Görevde',
              'currentOrderId': orderId,
            },
            SetOptions(merge: true));
      });

      debugPrint("Kurye atandı ✔");
      return true;
    } catch (e) {
      debugPrint("Dispatch HATA: $e");
      return false;
    }
  }

  Future<void> releaseCourier({
    required String orderId,
    required String courierId,
  }) async {
    final orderRef = _firestore.collection('orders').doc(orderId);
    final courierRef = _firestore.collection('couriers').doc(courierId);

    await _firestore.runTransaction((tx) async {
      final courierSnap = await tx.get(courierRef);
      if (!courierSnap.exists) return;

      final data = courierSnap.data() as Map<String, dynamic>;

      int aktif = _toInt(data['aktifSiparis']);
      int yeni = aktif > 0 ? aktif - 1 : 0;

      tx.set(
          orderRef,
          {
            'status': 'delivered',
          },
          SetOptions(merge: true));

      tx.set(
          courierRef,
          {
            'aktifSiparis': yeni,
            'uygunluk': yeni == 0 ? 'Müsait' : 'Görevde',
          },
          SetOptions(merge: true));
    });
  }

  double _distance(double lat1, double lng1, double lat2, double lng2) {
    const r = 6371;
    final dLat = _rad(lat2 - lat1);
    final dLng = _rad(lng2 - lng1);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_rad(lat1)) * cos(_rad(lat2)) * sin(dLng / 2) * sin(dLng / 2);

    return r * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  double _rad(double d) => d * pi / 180;

  int _toInt(dynamic v, {int defaultValue = 0}) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return defaultValue;
  }

  double? _toDouble(dynamic v) {
    if (v is double) return v;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }
}
