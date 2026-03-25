import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../modules/kurye_model.dart';

class KuryeAtamaOnerisi {
  final KuryeModel kurye;
  final double score;
  final double distanceKm;
  final bool sameCity;
  final bool sameDistrict;

  KuryeAtamaOnerisi({
    required this.kurye,
    required this.score,
    required this.distanceKm,
    required this.sameCity,
    required this.sameDistrict,
  });
}

class KuryeService {
  final FirebaseFirestore _firestore;

  KuryeService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _couriersRef =>
      _firestore.collection('couriers');

  CollectionReference<Map<String, dynamic>> get _ordersRef =>
      _firestore.collection('orders');

  CollectionReference<Map<String, dynamic>> get _assignmentQueueRef =>
      _firestore.collection('kuryeAtamaKuyrugu');

  CollectionReference<Map<String, dynamic>> get _sellerOrdersRef =>
      _firestore.collection('sellerOrders');

  Future<List<KuryeModel>> tumKuryeleriGetir() async {
    final snapshot = await _couriersRef.get();

    return snapshot.docs
        .map((doc) => KuryeModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  Stream<List<KuryeModel>> tumKuryeleriDinle() {
    return _couriersRef.snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) => KuryeModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  Future<List<KuryeModel>> musaitKuryeleriGetir() async {
    final tumu = await tumKuryeleriGetir();
    return tumu.where((k) => k.canTakeOrder).toList();
  }

  Future<List<KuryeAtamaOnerisi>> siparisIcinKuryeOnerileriGetir({
    required Map<String, dynamic> orderData,
    int limit = 8,
  }) async {
    final musaitKuryeler = await musaitKuryeleriGetir();

    final orderLat = _toDouble(orderData['lat']);
    final orderLng = _toDouble(orderData['lng']);
    final orderSehir = _readString(orderData['sehir']);
    final orderIlce = _readString(orderData['ilce']);

    final List<KuryeAtamaOnerisi> oneriler = [];

    for (final kurye in musaitKuryeler) {
      double distanceKm = 9999;

      if (orderLat != null &&
          orderLng != null &&
          kurye.lat != null &&
          kurye.lng != null) {
        distanceKm = calculateDistanceKm(
          orderLat,
          orderLng,
          kurye.lat!,
          kurye.lng!,
        );
      } else {
        if (orderSehir.isNotEmpty &&
            kurye.sehir.isNotEmpty &&
            orderSehir.toLowerCase() == kurye.sehir.toLowerCase()) {
          distanceKm = 15;
        }

        if (orderIlce.isNotEmpty &&
            kurye.ilce.isNotEmpty &&
            orderIlce.toLowerCase() == kurye.ilce.toLowerCase()) {
          distanceKm = 5;
        }
      }

      final sameCity = orderSehir.isNotEmpty &&
          kurye.sehir.isNotEmpty &&
          orderSehir.toLowerCase() == kurye.sehir.toLowerCase();

      final sameDistrict = orderIlce.isNotEmpty &&
          kurye.ilce.isNotEmpty &&
          orderIlce.toLowerCase() == kurye.ilce.toLowerCase();

      final score = calculateCourierScore(
        distanceKm: distanceKm,
        activeOrderCount: kurye.activeOrderCount,
        rating: kurye.rating,
        sameCity: sameCity,
        sameDistrict: sameDistrict,
      );

      oneriler.add(
        KuryeAtamaOnerisi(
          kurye: kurye,
          score: score,
          distanceKm: distanceKm,
          sameCity: sameCity,
          sameDistrict: sameDistrict,
        ),
      );
    }

    oneriler.sort((a, b) => b.score.compareTo(a.score));
    return oneriler.take(limit).toList();
  }

  Future<void> kuryeAta({
    required String orderId,
    required KuryeModel kurye,
    String assignmentType = 'manual_suggestion',
  }) async {
    await _firestore.runTransaction((transaction) async {
      final orderRef = _ordersRef.doc(orderId);
      final courierRef = _couriersRef.doc(kurye.id);

      final orderSnap = await transaction.get(orderRef);
      final courierSnap = await transaction.get(courierRef);

      if (!orderSnap.exists) {
        throw Exception('Sipariş bulunamadı.');
      }

      if (!courierSnap.exists) {
        throw Exception('Kurye bulunamadı.');
      }

      final orderData = orderSnap.data() ?? {};
      final currentCourierData = courierSnap.data() ?? {};

      final currentKurye =
          KuryeModel.fromMap(currentCourierData, courierSnap.id);

      if (!currentKurye.canTakeOrder) {
        throw Exception('Kurye şu anda müsait değil.');
      }

      transaction.update(orderRef, {
        'courierId': currentKurye.id,
        'courierName': currentKurye.ad,
        'courierPhone': currentKurye.telefon,
        'courierAssignedAt': FieldValue.serverTimestamp(),
        'courierAssignmentType': assignmentType,
        'courierAssignmentStatus': 'assigned',
        'updatedAt': FieldValue.serverTimestamp(),
        'status': orderData['status'] == 'pending'
            ? 'courier_assigned'
            : (orderData['status'] ?? 'courier_assigned'),
      });

      transaction.update(courierRef, {
        'activeOrderCount': currentKurye.activeOrderCount + 1,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<Map<String, dynamic>?> bekleyenKuryeAtamasiniOtomatikYap({
    required String queueId,
  }) async {
    final queueRef = _assignmentQueueRef.doc(queueId);

    return _firestore
        .runTransaction<Map<String, dynamic>?>((transaction) async {
      final queueSnap = await transaction.get(queueRef);

      if (!queueSnap.exists) {
        throw Exception('Kurye atama kuyruğu kaydı bulunamadı.');
      }

      final queueData = queueSnap.data() ?? {};

      final String queueStatus = _readString(queueData['status']);
      final String atamaDurumu = _readString(queueData['kuryeAtamaDurumu']);
      final String orderId = _readString(queueData['orderId']);
      final String sellerOrderId = _readString(queueData['sellerOrderId']);

      if (queueStatus != 'waiting_assignment' || atamaDurumu != 'beklemede') {
        return {
          'success': false,
          'reason': 'queue_not_waiting',
          'queueId': queueId,
        };
      }

      if (orderId.isEmpty) {
        throw Exception('Queue kaydında orderId eksik.');
      }

      final orderRef = _ordersRef.doc(orderId);
      final orderSnap = await transaction.get(orderRef);

      if (!orderSnap.exists) {
        throw Exception('Ana sipariş bulunamadı.');
      }

      final orderData = orderSnap.data() ?? {};

      final List<KuryeAtamaOnerisi> oneriler =
          await siparisIcinKuryeOnerileriGetir(orderData: orderData, limit: 1);

      if (oneriler.isEmpty) {
        transaction.update(queueRef, {
          'kuryeAtamaDurumu': 'kurye_bulunamadi',
          'status': 'no_courier_found',
          'updatedAt': FieldValue.serverTimestamp(),
        });

        return {
          'success': false,
          'reason': 'no_courier_found',
          'queueId': queueId,
          'orderId': orderId,
        };
      }

      final enIyiOneri = oneriler.first;
      final kurye = enIyiOneri.kurye;

      final courierRef = _couriersRef.doc(kurye.id);
      final courierSnap = await transaction.get(courierRef);

      if (!courierSnap.exists) {
        transaction.update(queueRef, {
          'kuryeAtamaDurumu': 'kurye_bulunamadi',
          'status': 'no_courier_found',
          'updatedAt': FieldValue.serverTimestamp(),
        });

        return {
          'success': false,
          'reason': 'courier_doc_missing',
          'queueId': queueId,
          'orderId': orderId,
        };
      }

      final courierData = courierSnap.data() ?? {};
      final currentKurye = KuryeModel.fromMap(courierData, courierSnap.id);

      if (!currentKurye.canTakeOrder) {
        transaction.update(queueRef, {
          'kuryeAtamaDurumu': 'kurye_musait_degildi',
          'status': 'retry_required',
          'updatedAt': FieldValue.serverTimestamp(),
        });

        return {
          'success': false,
          'reason': 'courier_not_available',
          'queueId': queueId,
          'orderId': orderId,
        };
      }

      transaction.update(orderRef, {
        'courierId': currentKurye.id,
        'courierName': currentKurye.ad,
        'courierPhone': currentKurye.telefon,
        'courierAssignedAt': FieldValue.serverTimestamp(),
        'courierAssignmentType': 'auto_queue_assignment',
        'courierAssignmentStatus': 'assigned',
        'updatedAt': FieldValue.serverTimestamp(),
        'status': orderData['status'] == 'pending'
            ? 'courier_assigned'
            : (orderData['status'] ?? 'courier_assigned'),
      });

      if (sellerOrderId.isNotEmpty) {
        final sellerOrderRef = _sellerOrdersRef.doc(sellerOrderId);

        transaction.update(sellerOrderRef, {
          'courierId': currentKurye.id,
          'courierName': currentKurye.ad,
          'courierPhone': currentKurye.telefon,
          'courierAssignedAt': FieldValue.serverTimestamp(),
          'courierAssignmentType': 'auto_queue_assignment',
          'courierAssignmentStatus': 'assigned',
          'updatedAt': FieldValue.serverTimestamp(),
          'status': 'courier_assigned',
          'durum': 'kurye_atandi',
        });
      }

      transaction.update(queueRef, {
        'kuryeId': currentKurye.id,
        'kuryeAdi': currentKurye.ad,
        'atanmaZamani': FieldValue.serverTimestamp(),
        'kuryeAtamaDurumu': 'atandi',
        'status': 'assigned',
        'assignmentType': 'auto_queue_assignment',
        'assignmentScore': enIyiOneri.score,
        'assignmentDistanceKm': enIyiOneri.distanceKm,
        'sameCity': enIyiOneri.sameCity,
        'sameDistrict': enIyiOneri.sameDistrict,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      transaction.update(courierRef, {
        'activeOrderCount': currentKurye.activeOrderCount + 1,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return {
        'success': true,
        'queueId': queueId,
        'orderId': orderId,
        'sellerOrderId': sellerOrderId,
        'courierId': currentKurye.id,
        'courierName': currentKurye.ad,
        'score': enIyiOneri.score,
        'distanceKm': enIyiOneri.distanceKm,
      };
    });
  }

  Future<List<Map<String, dynamic>>> bekleyenAtamalariTopluIsle({
    int limit = 10,
  }) async {
    final snapshot = await _assignmentQueueRef
        .where('status', isEqualTo: 'waiting_assignment')
        .where('kuryeAtamaDurumu', isEqualTo: 'beklemede')
        .limit(limit)
        .get();

    final List<Map<String, dynamic>> sonuc = [];

    for (final doc in snapshot.docs) {
      try {
        final result = await bekleyenKuryeAtamasiniOtomatikYap(queueId: doc.id);

        if (result != null) {
          sonuc.add(result);
        }
      } catch (e) {
        sonuc.add({
          'success': false,
          'queueId': doc.id,
          'reason': 'exception',
          'message': e.toString(),
        });
      }
    }

    return sonuc;
  }

  Future<void> kuryeDurumGuncelle({
    required String courierId,
    bool? isActive,
    bool? isAvailable,
    int? activeOrderCount,
  }) async {
    final updateData = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (isActive != null) {
      updateData['isActive'] = isActive;
    }

    if (isAvailable != null) {
      updateData['isAvailable'] = isAvailable;
    }

    if (activeOrderCount != null) {
      updateData['activeOrderCount'] = activeOrderCount;
    }

    await _couriersRef.doc(courierId).update(updateData);
  }

  Future<void> yeniKuryeEkle(KuryeModel kurye) async {
    await _couriersRef.doc(kurye.id).set({
      ...kurye.toMap(),
      'createdAt': kurye.createdAt ?? FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> kuryeGuncelle(KuryeModel kurye) async {
    await _couriersRef.doc(kurye.id).update({
      ...kurye.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> siparisTeslimEdildigindeKuryeBosalt({
    required String courierId,
  }) async {
    final ref = _couriersRef.doc(courierId);
    final snap = await ref.get();

    if (!snap.exists) return;

    final kurye = KuryeModel.fromMap(snap.data()!, snap.id);
    final yeniAdet = max(0, kurye.activeOrderCount - 1);

    await ref.update({
      'activeOrderCount': yeniAdet,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static double calculateCourierScore({
    required double distanceKm,
    required int activeOrderCount,
    required double rating,
    required bool sameCity,
    required bool sameDistrict,
  }) {
    double score = 100;

    if (distanceKm < 2) {
      score += 35;
    } else if (distanceKm < 5) {
      score += 24;
    } else if (distanceKm < 10) {
      score += 15;
    } else if (distanceKm < 20) {
      score += 8;
    } else {
      score -= min(distanceKm, 60);
    }

    if (sameCity) score += 12;
    if (sameDistrict) score += 20;

    score -= activeOrderCount * 8;
    score += rating * 4;

    return score;
  }

  static double calculateDistanceKm(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadiusKm = 6371;

    final dLat = _degToRad(lat2 - lat1);
    final dLon = _degToRad(lon2 - lon1);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degToRad(lat1)) *
            cos(_degToRad(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadiusKm * c;
  }

  static double _degToRad(double deg) => deg * pi / 180;

  static String _readString(dynamic value) {
    if (value == null) return '';
    return value.toString().trim();
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }
}
