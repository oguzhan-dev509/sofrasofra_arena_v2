import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class OtomatikYenidenAtamaServisi {
  final FirebaseFirestore _firestore;

  final Duration teklifTimeout;
  final int maxDeneme;
  final Duration retryDelay;

  OtomatikYenidenAtamaServisi({
    FirebaseFirestore? firestore,
    this.teklifTimeout = const Duration(seconds: 30),
    this.maxDeneme = 5,
    this.retryDelay = const Duration(seconds: 10),
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _orders =>
      _firestore.collection('orders');

  CollectionReference<Map<String, dynamic>> get _couriers =>
      _firestore.collection('couriers');

  Future<void> ilkAtamayiBaslat({
    required String orderId,
  }) async {
    try {
      await _kuryeAtaVeyaYenidenDene(
        orderId: orderId,
        oncekiKuryeId: null,
      );
    } catch (e, st) {
      debugPrint('ilkAtamayiBaslat hata: $e');
      debugPrint('$st');
    }
  }

  Future<void> timeoutKontrolVeYenidenAta({
    required String orderId,
  }) async {
    try {
      final orderSnap = await _orders.doc(orderId).get();
      if (!orderSnap.exists) return;

      final order = orderSnap.data()!;
      final assignmentStatus = (order['assignmentStatus'] ?? '').toString();
      final status = (order['status'] ?? '').toString();

      if (_siparisKapaliMi(status)) return;
      if (assignmentStatus != 'offer_sent') return;

      final expiresAtRaw = order['assignmentExpiresAt'];
      if (expiresAtRaw is! Timestamp) return;

      final expiresAt = expiresAtRaw.toDate();
      final now = DateTime.now();

      if (now.isBefore(expiresAt)) return;

      final assignedCourierId =
          (order['assignedCourierId'] ?? '').toString().trim();

      await _handleTimeout(
        orderId: orderId,
        timedOutCourierId: assignedCourierId.isEmpty ? null : assignedCourierId,
      );
    } catch (e, st) {
      debugPrint('timeoutKontrolVeYenidenAta hata: $e');
      debugPrint('$st');
    }
  }

  Future<void> kuryeKabulEtti({
    required String orderId,
    required String courierId,
  }) async {
    final orderRef = _orders.doc(orderId);

    await _firestore.runTransaction((tx) async {
      final orderSnap = await tx.get(orderRef);
      if (!orderSnap.exists) {
        throw Exception('Sipariş bulunamadı');
      }

      final order = orderSnap.data()!;
      final assignedCourierId =
          (order['assignedCourierId'] ?? '').toString().trim();
      final assignmentStatus = (order['assignmentStatus'] ?? '').toString();
      final status = (order['status'] ?? '').toString();

      if (_siparisKapaliMi(status)) {
        throw Exception('Sipariş artık işlem yapılamaz durumda');
      }

      if (assignedCourierId != courierId) {
        throw Exception('Bu sipariş bu kuryeye atanmış görünmüyor');
      }

      if (assignmentStatus != 'offer_sent' && assignmentStatus != 'assigned') {
        throw Exception('Sipariş kabul edilebilir durumda değil');
      }

      tx.update(orderRef, {
        'assignmentStatus': 'assigned',
        'courierAssignmentType': 'automatic',
        'acceptedAt': FieldValue.serverTimestamp(),
        'retryStatus': 'idle',
        'retryScheduledAt': null,
        'updatedAt': FieldValue.serverTimestamp(),
        'assignmentLogs': FieldValue.arrayUnion([
          {
            'type': 'offer_accepted',
            'courierId': courierId,
            'at': DateTime.now().toIso8601String(),
          }
        ]),
      });

      final courierRef = _couriers.doc(courierId);
      final courierSnap = await tx.get(courierRef);
      if (courierSnap.exists) {
        tx.update(courierRef, {
          'lastAcceptedAt': FieldValue.serverTimestamp(),
          'uygunluk': 'Görevde',
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    });
  }

  Future<void> kuryeReddetti({
    required String orderId,
    required String courierId,
  }) async {
    try {
      await _handleReject(
        orderId: orderId,
        rejectingCourierId: courierId,
      );
    } catch (e, st) {
      debugPrint('kuryeReddetti hata: $e');
      debugPrint('$st');
    }
  }

  Future<void> teslimEdildi({
    required String orderId,
  }) async {
    final orderRef = _orders.doc(orderId);

    await _firestore.runTransaction((tx) async {
      final orderSnap = await tx.get(orderRef);
      if (!orderSnap.exists) return;

      final order = orderSnap.data()!;
      final courierId = (order['assignedCourierId'] ?? '').toString().trim();

      tx.update(orderRef, {
        'status': 'delivered',
        'durum': 'delivered',
        'assignmentStatus': 'completed',
        'deliveredAt': FieldValue.serverTimestamp(),
        'retryStatus': 'idle',
        'retryScheduledAt': null,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (courierId.isNotEmpty) {
        final courierRef = _couriers.doc(courierId);
        final courierSnap = await tx.get(courierRef);
        if (courierSnap.exists) {
          final courier = courierSnap.data()!;
          final aktifSiparis = _toInt(courier['aktifSiparis'], defaultValue: 0);
          final yeniAktifSiparis = max(0, aktifSiparis - 1);

          tx.update(courierRef, {
            'aktifSiparis': yeniAktifSiparis,
            'toplamTeslimat':
                _toInt(courier['toplamTeslimat'], defaultValue: 0) + 1,
            'lastDeliveredAt': FieldValue.serverTimestamp(),
            'uygunluk': yeniAktifSiparis > 0 ? 'Görevde' : 'Müsait',
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      }
    });
  }

  Future<void> siparisIptalEdildi({
    required String orderId,
  }) async {
    final orderRef = _orders.doc(orderId);

    await _firestore.runTransaction((tx) async {
      final orderSnap = await tx.get(orderRef);
      if (!orderSnap.exists) return;

      final order = orderSnap.data()!;
      final courierId = (order['assignedCourierId'] ?? '').toString().trim();
      final assignmentStatus = (order['assignmentStatus'] ?? '').toString();

      tx.update(orderRef, {
        'status': 'cancelled',
        'durum': 'cancelled',
        'assignmentStatus': 'cancelled',
        'retryStatus': 'idle',
        'retryScheduledAt': null,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (courierId.isNotEmpty &&
          (assignmentStatus == 'offer_sent' ||
              assignmentStatus == 'assigned')) {
        final courierRef = _couriers.doc(courierId);
        final courierSnap = await tx.get(courierRef);
        if (courierSnap.exists) {
          final courier = courierSnap.data()!;
          final aktifSiparis = _toInt(courier['aktifSiparis'], defaultValue: 0);
          final yeniAktifSiparis = max(0, aktifSiparis - 1);

          tx.update(courierRef, {
            'aktifSiparis': yeniAktifSiparis,
            'uygunluk': yeniAktifSiparis > 0 ? 'Görevde' : 'Müsait',
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      }
    });
  }

  Future<void> processScheduledRetries() async {
    try {
      final now = Timestamp.now();

      final snapshot = await _orders
          .where('assignmentStatus', isEqualTo: 'retry_scheduled')
          .where('retryStatus', isEqualTo: 'scheduled')
          .where('retryScheduledAt', isLessThanOrEqualTo: now)
          .limit(20)
          .get();

      for (final doc in snapshot.docs) {
        await _kuryeAtaVeyaYenidenDene(
          orderId: doc.id,
          oncekiKuryeId: null,
        );
      }
    } catch (e, st) {
      debugPrint('processScheduledRetries hata: $e');
      debugPrint('$st');
    }
  }

  Future<void> _handleTimeout({
    required String orderId,
    required String? timedOutCourierId,
  }) async {
    final orderRef = _orders.doc(orderId);

    await _firestore.runTransaction((tx) async {
      final orderSnap = await tx.get(orderRef);
      if (!orderSnap.exists) return;

      final order = orderSnap.data()!;
      final currentAssignmentStatus =
          (order['assignmentStatus'] ?? '').toString();
      final status = (order['status'] ?? '').toString();

      if (currentAssignmentStatus != 'offer_sent') return;
      if (_siparisKapaliMi(status)) return;

      if (timedOutCourierId != null && timedOutCourierId.isNotEmpty) {
        final courierRef = _couriers.doc(timedOutCourierId);
        final courierSnap = await tx.get(courierRef);
        if (courierSnap.exists) {
          final courier = courierSnap.data()!;
          final aktifSiparis = _toInt(courier['aktifSiparis'], defaultValue: 0);
          final yeniAktifSiparis = max(0, aktifSiparis - 1);

          tx.update(courierRef, {
            'aktifSiparis': yeniAktifSiparis,
            'uygunluk': yeniAktifSiparis > 0 ? 'Görevde' : 'Müsait',
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      }

      final history = _historyFrom(order['reassignmentHistory']);
      history.add({
        'type': 'timeout',
        'courierId': timedOutCourierId,
        'at': Timestamp.now(),
      });

      final triedCourierIds = _stringListFrom(order['triedCourierIds']);
      if (timedOutCourierId != null &&
          timedOutCourierId.isNotEmpty &&
          !triedCourierIds.contains(timedOutCourierId)) {
        triedCourierIds.add(timedOutCourierId);
      }

      tx.update(orderRef, {
        'assignedCourierId': null,
        'assignedCourierName': null,
        'assignmentStatus': 'waiting_courier',
        'assignmentExpiresAt': null,
        'lastAssignmentAt': FieldValue.serverTimestamp(),
        'reassignmentHistory': history,
        'triedCourierIds': triedCourierIds,
        'lastTriedCourierIds': triedCourierIds,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });

    await _kuryeAtaVeyaYenidenDene(
      orderId: orderId,
      oncekiKuryeId: timedOutCourierId,
    );
  }

  Future<void> _handleReject({
    required String orderId,
    required String rejectingCourierId,
  }) async {
    final orderRef = _orders.doc(orderId);

    await _firestore.runTransaction((tx) async {
      final orderSnap = await tx.get(orderRef);
      if (!orderSnap.exists) return;

      final order = orderSnap.data()!;
      final assignedCourierId =
          (order['assignedCourierId'] ?? '').toString().trim();
      final status = (order['status'] ?? '').toString();

      if (_siparisKapaliMi(status)) return;
      if (assignedCourierId != rejectingCourierId) return;

      final courierRef = _couriers.doc(rejectingCourierId);
      final courierSnap = await tx.get(courierRef);
      if (courierSnap.exists) {
        final courier = courierSnap.data()!;
        final aktifSiparis = _toInt(courier['aktifSiparis'], defaultValue: 0);
        final yeniAktifSiparis = max(0, aktifSiparis - 1);

        tx.update(courierRef, {
          'aktifSiparis': yeniAktifSiparis,
          'uygunluk': yeniAktifSiparis > 0 ? 'Görevde' : 'Müsait',
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      final history = _historyFrom(order['reassignmentHistory']);
      history.add({
        'type': 'rejected',
        'courierId': rejectingCourierId,
        'at': Timestamp.now(),
      });

      final triedCourierIds = _stringListFrom(order['triedCourierIds']);
      if (!triedCourierIds.contains(rejectingCourierId)) {
        triedCourierIds.add(rejectingCourierId);
      }

      tx.update(orderRef, {
        'assignedCourierId': null,
        'assignedCourierName': null,
        'assignmentStatus': 'waiting_courier',
        'assignmentExpiresAt': null,
        'reassignmentHistory': history,
        'triedCourierIds': triedCourierIds,
        'lastTriedCourierIds': triedCourierIds,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });

    await _kuryeAtaVeyaYenidenDene(
      orderId: orderId,
      oncekiKuryeId: rejectingCourierId,
    );
  }

  Future<void> _kuryeAtaVeyaYenidenDene({
    required String orderId,
    required String? oncekiKuryeId,
  }) async {
    final orderRef = _orders.doc(orderId);
    final orderSnap = await orderRef.get();
    if (!orderSnap.exists) return;

    final order = orderSnap.data()!;
    final status = (order['status'] ?? '').toString();
    final assignmentStatus = (order['assignmentStatus'] ?? '').toString();

    if (_siparisKapaliMi(status)) return;
    if (assignmentStatus == 'assigned' || assignmentStatus == 'completed') {
      return;
    }

    final assignmentTryCount =
        _toInt(order['assignmentTryCount'], defaultValue: 0);

    if (assignmentTryCount >= maxDeneme) {
      await orderRef.update({
        'assignmentStatus': 'manual_review_required',
        'retryStatus': 'exhausted',
        'retryScheduledAt': null,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return;
    }

    final sehir = _normalize(order['sehir']);
    final ilce = _normalize(order['ilce']);

    final latLng = _extractLatLng(order);
    final siparisLat = latLng['lat'];
    final siparisLng = latLng['lng'];

    if (sehir == null ||
        ilce == null ||
        siparisLat == null ||
        siparisLng == null) {
      await orderRef.update({
        'assignmentStatus': 'invalid_order_location',
        'retryStatus': 'idle',
        'retryScheduledAt': null,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return;
    }

    final triedCourierIds = _mergedTriedCourierIds(order);
    final oncekiHaric = <String>{
      ...triedCourierIds,
      if (oncekiKuryeId != null && oncekiKuryeId.isNotEmpty) oncekiKuryeId,
    };

    final courierQuery = await _couriers
        .where('aktifMi', isEqualTo: true)
        .where('sehir', isEqualTo: sehir)
        .where('ilce', isEqualTo: ilce)
        .get();

    final uygunKuryeler = courierQuery.docs.where((doc) {
      final data = doc.data();
      final courierId = doc.id;
      if (oncekiHaric.contains(courierId)) return false;

      final aktifSiparis = _toInt(data['aktifSiparis'], defaultValue: 0);
      int maxAktifSiparis = _toInt(data['maxAktifSiparis'], defaultValue: 1);
      if (maxAktifSiparis <= 0) maxAktifSiparis = 1;

      final lat = _toDouble(data['lat']);
      final lng = _toDouble(data['lng']);

      if (aktifSiparis >= maxAktifSiparis) return false;
      if (lat == null || lng == null) return false;
      if (!_courierMusaitMi(data)) return false;

      return true;
    }).map((doc) {
      final data = doc.data();
      final lat = _toDouble(data['lat'])!;
      final lng = _toDouble(data['lng'])!;
      final distanceKm = _distanceKm(
        siparisLat,
        siparisLng,
        lat,
        lng,
      );

      return _CourierCandidate(
        id: doc.id,
        name: (data['adSoyad'] ?? data['ad'] ?? 'Kurye').toString(),
        distanceKm: distanceKm,
        aktifSiparis: _toInt(data['aktifSiparis'], defaultValue: 0),
        rating: _toDouble(data['rating']) ?? 0,
      );
    }).toList();

    uygunKuryeler.sort((a, b) {
      final mesafe = a.distanceKm.compareTo(b.distanceKm);
      if (mesafe != 0) return mesafe;

      final aktif = a.aktifSiparis.compareTo(b.aktifSiparis);
      if (aktif != 0) return aktif;

      return b.rating.compareTo(a.rating);
    });

    if (uygunKuryeler.isEmpty) {
      await _scheduleRetry(orderId: orderId, currentOrder: order);
      return;
    }

    final secilenKurye = uygunKuryeler.first;
    final courierRef = _couriers.doc(secilenKurye.id);

    try {
      await _firestore.runTransaction((tx) async {
        final freshOrderSnap = await tx.get(orderRef);
        if (!freshOrderSnap.exists) return;

        final freshOrder = freshOrderSnap.data()!;
        final freshAssignmentStatus =
            (freshOrder['assignmentStatus'] ?? 'waiting_courier').toString();
        final freshStatus = (freshOrder['status'] ?? '').toString();

        if (_siparisKapaliMi(freshStatus)) return;
        if (freshAssignmentStatus == 'assigned' ||
            freshAssignmentStatus == 'completed') {
          return;
        }

        final courierSnap = await tx.get(courierRef);
        if (!courierSnap.exists) {
          throw Exception('Seçilen kurye bulunamadı');
        }

        final courier = courierSnap.data()!;
        final aktifSiparis = _toInt(courier['aktifSiparis'], defaultValue: 0);
        int maxAktifSiparis =
            _toInt(courier['maxAktifSiparis'], defaultValue: 1);
        if (maxAktifSiparis <= 0) maxAktifSiparis = 1;

        if (aktifSiparis >= maxAktifSiparis) {
          throw Exception('Kurye kapasitesi dolmuş');
        }

        if (!_courierMusaitMi(courier)) {
          throw Exception('Kurye artık müsait değil');
        }

        final newTryCount =
            _toInt(freshOrder['assignmentTryCount'], defaultValue: 0) + 1;

        final triedCourierIds = _mergedTriedCourierIds(freshOrder);
        if (!triedCourierIds.contains(secilenKurye.id)) {
          triedCourierIds.add(secilenKurye.id);
        }

        final history = _historyFrom(freshOrder['reassignmentHistory']);
        history.add({
          'type': 'offer_sent',
          'courierId': secilenKurye.id,
          'courierName': secilenKurye.name,
          'distanceKm': secilenKurye.distanceKm,
          'at': Timestamp.now(),
        });

        final yeniAktifSiparis = aktifSiparis + 1;
        final yeniUygunluk =
            yeniAktifSiparis >= maxAktifSiparis ? 'Görevde' : 'Müsait';

        tx.update(courierRef, {
          'aktifSiparis': yeniAktifSiparis,
          'uygunluk': yeniUygunluk,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        tx.update(orderRef, {
          'assignedCourierId': secilenKurye.id,
          'assignedCourierName': secilenKurye.name,
          'assignmentStatus': 'offer_sent',
          'courierAssignmentType': 'automatic',
          'assignmentTryCount': newTryCount,
          'lastAssignmentAt': FieldValue.serverTimestamp(),
          'assignmentExpiresAt': Timestamp.fromDate(
            DateTime.now().add(teklifTimeout),
          ),
          'retryStatus': 'idle',
          'retryScheduledAt': null,
          'triedCourierIds': triedCourierIds,
          'lastTriedCourierIds': triedCourierIds,
          'reassignmentHistory': history,
          'updatedAt': FieldValue.serverTimestamp(),
          'assignmentLogs': FieldValue.arrayUnion([
            {
              'type': 'offer_sent',
              'courierId': secilenKurye.id,
              'courierName': secilenKurye.name,
              'distanceKm': secilenKurye.distanceKm,
              'at': DateTime.now().toIso8601String(),
            }
          ]),
        });
      });
    } catch (e, st) {
      debugPrint('_kuryeAtaVeyaYenidenDene transaction hata: $e');
      debugPrint('$st');
      final refreshed = await orderRef.get();
      if (refreshed.exists) {
        await _scheduleRetry(orderId: orderId, currentOrder: refreshed.data()!);
      }
    }
  }

  Future<void> _scheduleRetry({
    required String orderId,
    required Map<String, dynamic> currentOrder,
  }) async {
    final orderRef = _orders.doc(orderId);

    final status = (currentOrder['status'] ?? '').toString();
    final assignmentStatus =
        (currentOrder['assignmentStatus'] ?? '').toString();

    if (_siparisKapaliMi(status)) return;
    if (assignmentStatus == 'assigned' || assignmentStatus == 'completed') {
      return;
    }

    final tryCount =
        _toInt(currentOrder['assignmentTryCount'], defaultValue: 0);

    if (tryCount >= maxDeneme) {
      await orderRef.update({
        'assignmentStatus': 'manual_review_required',
        'retryStatus': 'exhausted',
        'retryScheduledAt': null,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return;
    }

    final scheduledAt = DateTime.now().add(retryDelay);

    await orderRef.set({
      'assignmentStatus': 'retry_scheduled',
      'retryStatus': 'scheduled',
      'retryScheduledAt': Timestamp.fromDate(scheduledAt),
      'courierAssignmentType': 'automatic',
      'lastRetryReason': 'no_available_courier',
      'updatedAt': FieldValue.serverTimestamp(),
      'assignmentLogs': FieldValue.arrayUnion([
        {
          'type': 'retry_scheduled',
          'scheduledFor': scheduledAt.toIso8601String(),
          'tryCount': tryCount,
          'at': DateTime.now().toIso8601String(),
        }
      ]),
    }, SetOptions(merge: true));
  }

  static bool _courierMusaitMi(Map<String, dynamic> data) {
    final availabilityRaw =
        (data['availability'] ?? '').toString().toLowerCase().trim();
    final uygunlukDurumuRaw =
        (data['uygunlukDurumu'] ?? '').toString().toLowerCase().trim();
    final uygunlukRaw =
        (data['uygunluk'] ?? '').toString().toLowerCase().trim();

    bool isAvailable(String v) {
      return v == 'musait' || v == 'müsait' || v == 'available';
    }

    if (availabilityRaw.isNotEmpty) return isAvailable(availabilityRaw);
    if (uygunlukDurumuRaw.isNotEmpty) return isAvailable(uygunlukDurumuRaw);
    if (uygunlukRaw.isNotEmpty) return isAvailable(uygunlukRaw);

    return false;
  }

  static List<String> _stringListFrom(dynamic value) {
    if (value is List) {
      return value
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    return <String>[];
  }

  static List<Map<String, dynamic>> _historyFrom(dynamic value) {
    if (value is List) {
      return value.map((e) {
        if (e is Map) {
          return Map<String, dynamic>.from(e);
        }
        return <String, dynamic>{};
      }).toList();
    }
    return <Map<String, dynamic>>[];
  }

  static List<String> _mergedTriedCourierIds(Map<String, dynamic> order) {
    final result = <String>{};

    for (final id in _stringListFrom(order['triedCourierIds'])) {
      result.add(id);
    }
    for (final id in _stringListFrom(order['lastTriedCourierIds'])) {
      result.add(id);
    }

    final assignedCourierId =
        (order['assignedCourierId'] ?? '').toString().trim();
    if (assignedCourierId.isNotEmpty) {
      result.add(assignedCourierId);
    }

    return result.toList();
  }

  static Map<String, double?> _extractLatLng(Map<String, dynamic> order) {
    double? lat = _toDouble(order['lat']);
    double? lng = _toDouble(order['lng']);

    if (lat != null && lng != null) {
      return {'lat': lat, 'lng': lng};
    }

    final meta = order['meta'];
    if (meta is Map<String, dynamic>) {
      final adres = meta['adres'];
      if (adres is Map<String, dynamic>) {
        lat ??= _toDouble(adres['lat']);
        lng ??= _toDouble(adres['lng']);
      }
    }

    final adres = order['adres'];
    if (adres is Map<String, dynamic>) {
      lat ??= _toDouble(adres['lat']);
      lng ??= _toDouble(adres['lng']);
    }

    return {'lat': lat, 'lng': lng};
  }

  static bool _siparisKapaliMi(String status) {
    return status == 'delivered' ||
        status == 'cancelled' ||
        status == 'on_the_way';
  }

  static int _toInt(dynamic value, {int defaultValue = 0}) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? defaultValue;
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  static String? _normalize(dynamic value) {
    if (value == null) return null;
    final s = value
        .toString()
        .trim()
        .toLowerCase()
        .replaceAll('ı', 'i')
        .replaceAll('İ', 'i');
    if (s.isEmpty) return null;
    return s;
  }

  static double _distanceKm(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const earthRadiusKm = 6371.0;

    final dLat = _degToRad(lat2 - lat1);
    final dLon = _degToRad(lon2 - lon1);

    final a = pow(sin(dLat / 2), 2).toDouble() +
        cos(_degToRad(lat1)) *
            cos(_degToRad(lat2)) *
            pow(sin(dLon / 2), 2).toDouble();

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadiusKm * c;
  }

  static double _degToRad(double deg) => deg * pi / 180.0;
}

class _CourierCandidate {
  final String id;
  final String name;
  final double distanceKm;
  final int aktifSiparis;
  final double rating;

  _CourierCandidate({
    required this.id,
    required this.name,
    required this.distanceKm,
    required this.aktifSiparis,
    required this.rating,
  });
}
