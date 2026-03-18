import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class KuryeDispatchEngine {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Yeni modele uyumlu en yakın kurye atama
  Future<bool> assignNearestCourier({
    required String orderId,
  }) async {
    try {
      final orderRef = _firestore.collection('orders').doc(orderId);
      final orderSnap = await orderRef.get();

      if (!orderSnap.exists) {
        debugPrint('KuryeDispatchEngine: Sipariş bulunamadı -> $orderId');
        return false;
      }

      final orderData = orderSnap.data() as Map<String, dynamic>;

      final double? orderLat = _toDouble(orderData['lat']);
      final double? orderLng = _toDouble(orderData['lng']);

      if (orderLat == null || orderLng == null) {
        debugPrint('KuryeDispatchEngine: Sipariş konumu eksik -> $orderId');
        return false;
      }

      final String currentStatus =
          (orderData['status'] ?? '').toString().trim().toLowerCase();

      if (currentStatus.isNotEmpty &&
          currentStatus != 'pending' &&
          currentStatus != 'ready' &&
          currentStatus != 'waiting_courier') {
        debugPrint(
          'KuryeDispatchEngine: Sipariş durumu kurye atamaya uygun değil -> $currentStatus',
        );
        return false;
      }

      final couriersQuery = await _firestore.collection('couriers').get();

      if (couriersQuery.docs.isEmpty) {
        debugPrint('KuryeDispatchEngine: Hiç kurye kaydı yok.');
        await orderRef.set({
          'status': 'waiting_courier',
          'assignmentStatus': 'waiting_courier',
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        return false;
      }

      QueryDocumentSnapshot<Map<String, dynamic>>? nearestCourier;
      double nearestDistanceKm = double.infinity;

      for (final courierDoc in couriersQuery.docs) {
        final courierData = courierDoc.data();

        final bool aktifMi =
            courierData['aktifMi'] == true || courierData['isActive'] == true;

        if (!aktifMi) continue;

        final String uygunluk = (courierData['uygunluk'] ??
                courierData['uygunlukDurumu'] ??
                courierData['availability'] ??
                '')
            .toString()
            .trim()
            .toLowerCase();

        final bool musait = uygunluk == 'musait' ||
            uygunluk == 'müsait' ||
            uygunluk == 'available';

        if (!musait) continue;

        int aktifSiparis = _toInt(courierData['aktifSiparis']);
        int maxAktifSiparis =
            _toInt(courierData['maxAktifSiparis'], defaultValue: 2);

        if (maxAktifSiparis <= 0) {
          maxAktifSiparis = 1;
        }

        if (aktifSiparis >= maxAktifSiparis) continue;

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
        debugPrint('KuryeDispatchEngine: Uygun kurye bulunamadı.');
        await orderRef.set({
          'status': 'waiting_courier',
          'assignmentStatus': 'waiting_courier',
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        return false;
      }

      final courierId = nearestCourier.id;
      final courierData = nearestCourier.data();
      final courierName =
          (courierData['adSoyad'] ?? courierData['ad'] ?? 'Kurye').toString();

      final courierRef = _firestore.collection('couriers').doc(courierId);

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

        final freshOrderStatus =
            (freshOrderData['status'] ?? '').toString().trim().toLowerCase();

        final bool courierAktif = freshCourierData['aktifMi'] == true ||
            freshCourierData['isActive'] == true;

        final String courierUygunluk = (freshCourierData['uygunluk'] ??
                freshCourierData['uygunlukDurumu'] ??
                freshCourierData['availability'] ??
                '')
            .toString()
            .trim()
            .toLowerCase();

        int mevcutAktifSiparis = _toInt(freshCourierData['aktifSiparis']);
        int maxAktifSiparis =
            _toInt(freshCourierData['maxAktifSiparis'], defaultValue: 2);

        if (maxAktifSiparis <= 0) {
          maxAktifSiparis = 1;
        }

        final bool courierMusait = courierUygunluk == 'musait' ||
            courierUygunluk == 'müsait' ||
            courierUygunluk == 'available';

        if (freshOrderStatus != 'pending' &&
            freshOrderStatus != 'ready' &&
            freshOrderStatus != 'waiting_courier') {
          throw Exception('Sipariş artık kurye atamaya uygun değil.');
        }

        if (!courierAktif || !courierMusait) {
          throw Exception('Seçilen kurye artık uygun değil.');
        }

        if (mevcutAktifSiparis >= maxAktifSiparis) {
          throw Exception('Seçilen kurye kapasite sınırına ulaştı.');
        }

        transaction.set(
            orderRef,
            {
              'assignedCourierId': courierId,
              'assignedCourierName': courierName,
              'assignmentAt': FieldValue.serverTimestamp(),
              'assignmentStatus': 'assigned',
              'courierAssignmentType': 'dispatch_engine',
              'courierDistanceKm': nearestDistanceKm,
              'status': 'on_the_way',
              'updatedAt': FieldValue.serverTimestamp(),
            },
            SetOptions(merge: true));

        transaction.set(
            courierRef,
            {
              'aktifSiparis': mevcutAktifSiparis + 1,
              'uygunluk': 'Görevde',
              'lastAssignedAt': FieldValue.serverTimestamp(),
              'updatedAt': FieldValue.serverTimestamp(),
            },
            SetOptions(merge: true));
      });

      debugPrint(
        'KuryeDispatchEngine: Kurye atandı -> $courierName ($courierId), mesafe: ${nearestDistanceKm.toStringAsFixed(2)} km',
      );

      return true;
    } catch (e) {
      debugPrint('KuryeDispatchEngine HATA: $e');
      return false;
    }
  }

  /// Kurye siparişi kabul ettiğinde
  Future<void> courierAcceptOrder({
    required String orderId,
    required String courierId,
  }) async {
    try {
      final orderRef = _firestore.collection('orders').doc(orderId);
      final courierRef = _firestore.collection('couriers').doc(courierId);

      await _firestore.runTransaction((transaction) async {
        final orderSnap = await transaction.get(orderRef);
        final courierSnap = await transaction.get(courierRef);

        if (!orderSnap.exists || !courierSnap.exists) {
          throw Exception('Sipariş veya kurye bulunamadı.');
        }

        transaction.set(
            orderRef,
            {
              'courierOfferStatus': 'accepted',
              'courierAcceptedAt': FieldValue.serverTimestamp(),
              'status': 'on_the_way',
              'assignmentStatus': 'assigned',
              'updatedAt': FieldValue.serverTimestamp(),
            },
            SetOptions(merge: true));

        transaction.set(
            courierRef,
            {
              'lastAcceptedAt': FieldValue.serverTimestamp(),
              'uygunluk': 'Görevde',
              'updatedAt': FieldValue.serverTimestamp(),
            },
            SetOptions(merge: true));
      });

      debugPrint('KuryeDispatchEngine: Kurye siparişi kabul etti.');
    } catch (e) {
      debugPrint('KuryeDispatchEngine courierAcceptOrder HATA: $e');
    }
  }

  /// Sipariş teslim edilince veya iptal edilince kuryeyi gerçekten serbest bırak
  Future<void> releaseCourier({
    required String orderId,
    required String courierId,
    String newOrderStatus = 'delivered',
  }) async {
    try {
      final orderRef = _firestore.collection('orders').doc(orderId);
      final courierRef = _firestore.collection('couriers').doc(courierId);

      await _firestore.runTransaction((transaction) async {
        final orderSnap = await transaction.get(orderRef);
        final courierSnap = await transaction.get(courierRef);

        if (!orderSnap.exists) {
          throw Exception('Sipariş bulunamadı.');
        }

        if (!courierSnap.exists) {
          throw Exception('Kurye bulunamadı.');
        }

        final courierData = courierSnap.data() as Map<String, dynamic>;

        int aktifSiparis = _toInt(courierData['aktifSiparis']);
        final int toplamTeslimat =
            _toInt(courierData['toplamTeslimat'], defaultValue: 0);

        final int yeniAktifSiparis = aktifSiparis > 0 ? aktifSiparis - 1 : 0;

        final Map<String, dynamic> orderUpdate = {
          'status': newOrderStatus,
          'updatedAt': FieldValue.serverTimestamp(),
        };

        if (newOrderStatus == 'delivered') {
          orderUpdate['assignmentStatus'] = 'completed';
          orderUpdate['deliveredAt'] = FieldValue.serverTimestamp();
        } else if (newOrderStatus == 'cancelled') {
          orderUpdate['assignmentStatus'] = 'cancelled';
        }

        transaction.set(
            orderRef,
            {
              ...orderUpdate,
              'courierOfferStatus': null,
            },
            SetOptions(merge: true));

        transaction.set(
            courierRef,
            {
              'aktifSiparis': yeniAktifSiparis,
              'uygunluk': yeniAktifSiparis == 0 ? 'Müsait' : 'Görevde',
              'lastDeliveredAt': FieldValue.serverTimestamp(),
              'toplamTeslimat': newOrderStatus == 'delivered'
                  ? toplamTeslimat + 1
                  : toplamTeslimat,
              'updatedAt': FieldValue.serverTimestamp(),
            },
            SetOptions(merge: true));
      });

      debugPrint('KuryeDispatchEngine: Kurye serbest bırakıldı.');
    } catch (e) {
      debugPrint('KuryeDispatchEngine releaseCourier HATA: $e');
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

  int _toInt(dynamic value, {int defaultValue = 0}) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? defaultValue;
    return defaultValue;
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
