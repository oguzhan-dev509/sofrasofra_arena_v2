import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';

class AiKuryeDagitimMotoru {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Ana fonksiyon:
  /// Sipariş için en uygun kuryeyi AI skoruna göre bulur ve atar.
  Future<bool> assignBestCourier({
    required String orderId,
  }) async {
    try {
      final orderRef = _firestore.collection('orders').doc(orderId);
      final orderSnap = await orderRef.get();

      if (!orderSnap.exists) {
        print('AiKuryeDagitimMotoru: Sipariş bulunamadı -> $orderId');
        return false;
      }

      final orderData = orderSnap.data() as Map<String, dynamic>;

      final orderLat = _toDouble(orderData['lat']);
      final orderLng = _toDouble(orderData['lng']);

      if (orderLat == null || orderLng == null) {
        print('AiKuryeDagitimMotoru: Sipariş lat/lng eksik -> $orderId');
        return false;
      }

      final status = (orderData['status'] ?? '').toString();
      if (status.isNotEmpty &&
          status != 'pending' &&
          status != 'waiting_courier') {
        print('AiKuryeDagitimMotoru: Sipariş durumu uygun değil -> $status');
        return false;
      }

      final restaurantPrepMinutes =
          _toDouble(orderData['hazirlamaSuresiDakika']) ??
              _toDouble(orderData['restaurantPrepMinutes']) ??
              20.0;

      final trafficLevel = _normalizeTrafficLevel(
        orderData['trafikSeviyesi'] ?? orderData['trafficLevel'],
      );

      final courierQuery = await _firestore
          .collection('couriers')
          .where('online', isEqualTo: true)
          .where('activeOrder', isEqualTo: false)
          .get();

      if (courierQuery.docs.isEmpty) {
        await orderRef.update({
          'status': 'waiting_courier',
          'updatedAt': FieldValue.serverTimestamp(),
        });
        print('AiKuryeDagitimMotoru: Uygun kurye yok.');
        return false;
      }

      _CourierAiScore? bestCourier;

      for (final doc in courierQuery.docs) {
        final courierData = doc.data();

        final courierLat = _toDouble(courierData['lat']);
        final courierLng = _toDouble(courierData['lng']);
        if (courierLat == null || courierLng == null) continue;

        final distanceKm = _calculateDistanceKm(
          orderLat,
          orderLng,
          courierLat,
          courierLng,
        );

        final performanceScore = _normalizePerformanceScore(courierData);
        final speedScore = _normalizeSpeedScore(courierData);
        final acceptanceScore = _normalizeAcceptanceScore(courierData);
        final workloadScore = _normalizeWorkloadScore(courierData);

        final trafficPenalty = _trafficPenalty(trafficLevel);
        final prepBonus = _prepBonus(restaurantPrepMinutes, distanceKm);

        final distanceScore = _distanceScore(distanceKm);

        final totalScore = (distanceScore * 0.35) +
            (performanceScore * 0.20) +
            (speedScore * 0.15) +
            (acceptanceScore * 0.10) +
            (workloadScore * 0.10) +
            (prepBonus * 0.10) -
            trafficPenalty;

        final candidate = _CourierAiScore(
          courierId: doc.id,
          courierName: (courierData['name'] ?? 'Kurye').toString(),
          distanceKm: distanceKm,
          totalScore: totalScore,
          distanceScore: distanceScore,
          performanceScore: performanceScore,
          speedScore: speedScore,
          acceptanceScore: acceptanceScore,
          workloadScore: workloadScore,
          prepBonus: prepBonus,
          trafficPenalty: trafficPenalty,
        );

        if (bestCourier == null ||
            candidate.totalScore > bestCourier.totalScore) {
          bestCourier = candidate;
        }
      }

      if (bestCourier == null) {
        await orderRef.update({
          'status': 'waiting_courier',
          'updatedAt': FieldValue.serverTimestamp(),
        });
        print('AiKuryeDagitimMotoru: Skorlanabilir kurye bulunamadı.');
        return false;
      }

      final courierRef =
          _firestore.collection('couriers').doc(bestCourier.courierId);
      final courierOrderRef = _firestore.collection('courier_orders').doc();

      await _firestore.runTransaction((tx) async {
        final freshOrderSnap = await tx.get(orderRef);
        final freshCourierSnap = await tx.get(courierRef);

        if (!freshOrderSnap.exists || !freshCourierSnap.exists) {
          throw Exception(
              'Transaction sırasında sipariş veya kurye bulunamadı.');
        }

        final freshOrderData =
            freshOrderSnap.data() as Map<String, dynamic>? ?? {};
        final freshCourierData =
            freshCourierSnap.data() as Map<String, dynamic>? ?? {};

        final freshStatus = (freshOrderData['status'] ?? '').toString();
        final courierOnline = freshCourierData['online'] == true;
        final courierActiveOrder = freshCourierData['activeOrder'] == true;

        if (freshStatus != 'pending' && freshStatus != 'waiting_courier') {
          throw Exception('Sipariş artık atama için uygun değil.');
        }

        if (!courierOnline || courierActiveOrder) {
          throw Exception('Seçilen kurye artık uygun değil.');
        }

        tx.update(orderRef, {
          'assignedCourierId': bestCourier!.courierId,
          'assignedCourierName': bestCourier.courierName,
          'courierAssignedAt': FieldValue.serverTimestamp(),
          'courierDistanceKm': bestCourier.distanceKm,
          'aiDispatchScore': bestCourier.totalScore,
          'aiDispatchMeta': {
            'distanceScore': bestCourier.distanceScore,
            'performanceScore': bestCourier.performanceScore,
            'speedScore': bestCourier.speedScore,
            'acceptanceScore': bestCourier.acceptanceScore,
            'workloadScore': bestCourier.workloadScore,
            'prepBonus': bestCourier.prepBonus,
            'trafficPenalty': bestCourier.trafficPenalty,
          },
          'trafficLevelUsed': trafficLevel,
          'restaurantPrepMinutesUsed': restaurantPrepMinutes,
          'status': 'courier_assigned',
          'updatedAt': FieldValue.serverTimestamp(),
        });

        tx.update(courierRef, {
          'activeOrder': true,
          'currentOrderId': orderId,
          'lastAssignedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        tx.set(courierOrderRef, {
          'orderId': orderId,
          'courierId': bestCourier.courierId,
          'courierName': bestCourier.courierName,
          'status': 'assigned',
          'distanceKm': bestCourier.distanceKm,
          'aiDispatchScore': bestCourier.totalScore,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });

      print(
        'AiKuryeDagitimMotoru: En iyi kurye atandı -> ${bestCourier.courierName}, skor: ${bestCourier.totalScore.toStringAsFixed(3)}',
      );

      return true;
    } catch (e) {
      print('AiKuryeDagitimMotoru HATA: $e');
      return false;
    }
  }

  double _calculateDistanceKm(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    const double earthRadiusKm = 6371.0;

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

  double _degToRad(double deg) => deg * pi / 180.0;

  double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  /// Trafik seviyesi 0.0 - 1.0 arası normalize edilir.
  double _normalizeTrafficLevel(dynamic value) {
    if (value == null) return 0.3;

    if (value is String) {
      final v = value.toLowerCase().trim();
      if (v == 'low' || v == 'dusuk') return 0.2;
      if (v == 'medium' || v == 'orta') return 0.5;
      if (v == 'high' || v == 'yuksek') return 0.9;
    }

    final parsed = _toDouble(value);
    if (parsed == null) return 0.3;

    if (parsed > 1) {
      return (parsed / 100).clamp(0.0, 1.0);
    }

    return parsed.clamp(0.0, 1.0);
  }

  /// Performans puanı: 0.0 - 1.0
  /// Varsayılan olarak rating, completedOrders, cancelRate gibi alanlara bakar.
  double _normalizePerformanceScore(Map<String, dynamic> courierData) {
    final rating = _toDouble(courierData['rating']) ?? 4.5;
    final completedOrders = _toDouble(courierData['completedOrders']) ?? 0;
    final cancelRate = _toDouble(courierData['cancelRate']) ?? 0.05;

    final ratingScore = (rating / 5.0).clamp(0.0, 1.0);
    final experienceScore = (completedOrders / 500).clamp(0.0, 1.0);
    final cancelPenalty = cancelRate.clamp(0.0, 1.0);

    final score = (ratingScore * 0.6) +
        (experienceScore * 0.3) +
        ((1 - cancelPenalty) * 0.1);

    return score.clamp(0.0, 1.0);
  }

  /// Ortalama teslimat hızı: düşük dakika daha iyidir.
  double _normalizeSpeedScore(Map<String, dynamic> courierData) {
    final avgDeliveryMinutes =
        _toDouble(courierData['avgDeliveryMinutes']) ?? 30.0;

    if (avgDeliveryMinutes <= 15) return 1.0;
    if (avgDeliveryMinutes >= 60) return 0.1;

    final normalized = 1 - ((avgDeliveryMinutes - 15) / 45);
    return normalized.clamp(0.1, 1.0);
  }

  /// Kabul oranı: 0.0 - 1.0
  double _normalizeAcceptanceScore(Map<String, dynamic> courierData) {
    final acceptanceRate = _toDouble(courierData['acceptanceRate']) ?? 0.85;

    if (acceptanceRate > 1) {
      return (acceptanceRate / 100).clamp(0.0, 1.0);
    }

    return acceptanceRate.clamp(0.0, 1.0);
  }

  /// Kurye son dönemde ne kadar yüklü? düşükse daha iyi.
  double _normalizeWorkloadScore(Map<String, dynamic> courierData) {
    final todayCompleted = _toDouble(courierData['todayCompletedOrders']) ?? 0;

    if (todayCompleted <= 2) return 1.0;
    if (todayCompleted >= 15) return 0.2;

    final normalized = 1 - ((todayCompleted - 2) / 13);
    return normalized.clamp(0.2, 1.0);
  }

  /// Mesafe puanı: yakına daha yüksek skor
  double _distanceScore(double distanceKm) {
    if (distanceKm <= 1) return 1.0;
    if (distanceKm >= 12) return 0.05;

    final normalized = 1 - ((distanceKm - 1) / 11);
    return normalized.clamp(0.05, 1.0);
  }

  /// Trafik kötüleştikçe skordan düşer.
  double _trafficPenalty(double trafficLevel) {
    return (trafficLevel * 0.15).clamp(0.0, 0.15);
  }

  /// Hazırlama süresi uzunsa biraz daha uzakta ama güçlü kurye seçimini tolere eder.
  double _prepBonus(double prepMinutes, double distanceKm) {
    if (prepMinutes >= 25 && distanceKm <= 4) return 0.10;
    if (prepMinutes >= 20 && distanceKm <= 3) return 0.07;
    if (prepMinutes >= 15 && distanceKm <= 2) return 0.04;
    return 0.0;
  }
}

class _CourierAiScore {
  final String courierId;
  final String courierName;
  final double distanceKm;
  final double totalScore;
  final double distanceScore;
  final double performanceScore;
  final double speedScore;
  final double acceptanceScore;
  final double workloadScore;
  final double prepBonus;
  final double trafficPenalty;

  _CourierAiScore({
    required this.courierId,
    required this.courierName,
    required this.distanceKm,
    required this.totalScore,
    required this.distanceScore,
    required this.performanceScore,
    required this.speedScore,
    required this.acceptanceScore,
    required this.workloadScore,
    required this.prepBonus,
    required this.trafficPenalty,
  });
}
