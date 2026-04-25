import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class OtomatikKuryeAtamaServisi {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const int _retryDelaySeconds = 10;
  static const int _defaultMaxRetryCount = 5;

  Future<Map<String, dynamic>?> enUygunKuryeyiBul({
    required String sehir,
    required String ilce,
    String? saticiId,
    bool saticiKuryeAktif = true,
    double? orderLat,
    double? orderLng,
    List<String> triedCourierIds = const [],
  }) async {
    try {
      final adaylar = await enYakinKuryeleriGetir(
        sehir: sehir,
        ilce: ilce,
        saticiId: saticiId,
        saticiKuryeAktif: saticiKuryeAktif,
        orderLat: orderLat,
        orderLng: orderLng,
        triedCourierIds: triedCourierIds,
        limit: 1,
      );

      if (adaylar.isEmpty) {
        debugPrint('enUygunKuryeyiBul: uygun aday yok.');
        return null;
      }

      return adaylar.first;
    } catch (e) {
      debugPrint('enUygunKuryeyiBul hata: $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> enYakinKuryeleriGetir({
    required String sehir,
    required String ilce,
    String? saticiId,
    bool saticiKuryeAktif = true,
    double? orderLat,
    double? orderLng,
    List<String> triedCourierIds = const [],
    int limit = 3,
  }) async {
    try {
      final adayBelgeler = await _adayKuryeleriGetir(
        sehir: sehir,
        ilce: ilce,
        saticiId: saticiId,
        saticiKuryeAktif: saticiKuryeAktif,
        orderLat: orderLat,
        orderLng: orderLng,
        triedCourierIds: triedCourierIds,
      );

      if (adayBelgeler.isEmpty) {
        return [];
      }

      final secilenler = adayBelgeler.take(limit).map((doc) {
        final data = doc.data();
        final distanceKm = _courierDistanceKm(
          data: data,
          orderLat: orderLat,
          orderLng: orderLng,
        );

        final kuryeTipi =
            (data['kuryeTipi'] ?? '').toString().trim().toLowerCase();

        final assignmentType =
            kuryeTipi == 'satici_bagli' ? 'seller_linked' : 'platform_pool';

        return {
          'courierId': doc.id,
          'kuryeId': doc.id,
          'id': doc.id,
          'adSoyad': (data['adSoyad'] ?? data['ad'] ?? 'Kurye').toString(),
          'kuryeAdi': (data['adSoyad'] ?? data['ad'] ?? 'Kurye').toString(),
          'ad': (data['adSoyad'] ?? data['ad'] ?? 'Kurye').toString(),
          'telefon': (data['telefon'] ?? '').toString(),
          'aktifSiparis': _toInt(data['aktifSiparis']),
          'maxAktifSiparis': (() {
            int v = _toInt(data['maxAktifSiparis'], defaultValue: 3);
            if (v <= 0) v = 1;
            return v;
          })(),
          'rating': _toDouble(data['rating']) ?? 0.0,
          'distanceKm': distanceKm,
          'mesafeKm': distanceKm,
          'assignmentType': assignmentType,
          'kuryeTipi': kuryeTipi,
          'aracTipi': (data['aracTipi'] ?? '').toString(),
          'sehir': (data['sehir'] ?? data['city'] ?? '').toString(),
          'ilce': (data['ilce'] ?? data['district'] ?? '').toString(),
          'uygunluk': (data['uygunluk'] ??
                  data['uygunlukDurumu'] ??
                  data['availability'] ??
                  'Müsait')
              .toString(),
        };
      }).toList();

      debugPrint(
        'enYakinKuryeleriGetir: ${secilenler.length} aday döndü.',
      );

      return secilenler;
    } catch (e) {
      debugPrint('enYakinKuryeleriGetir hata: $e');
      return [];
    }
  }

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>>
      _adayKuryeleriGetir({
    required String sehir,
    required String ilce,
    String? saticiId,
    bool saticiKuryeAktif = true,
    double? orderLat,
    double? orderLng,
    List<String> triedCourierIds = const [],
  }) async {
    final normSehir = _normalize(sehir);
    final normIlce = _normalize(ilce);
    final normSaticiId = _normalize(saticiId ?? '');

    final triedSet = triedCourierIds
        .map((e) => e.toString().trim())
        .where((e) => e.isNotEmpty)
        .toSet();

    final courierQuery = await _firestore.collection('couriers').get();

    if (courierQuery.docs.isEmpty) {
      debugPrint('Courier koleksiyonunda hiç kayıt yok.');
      return [];
    }

    bool aktifMi(Map<String, dynamic> data) {
      return data['aktifMi'] == true || data['isActive'] == true;
    }

    String courierSehir(Map<String, dynamic> data) {
      return _normalize((data['sehir'] ?? data['city'] ?? '').toString());
    }

    String courierIlce(Map<String, dynamic> data) {
      return _normalize((data['ilce'] ?? data['district'] ?? '').toString());
    }

    bool konumEslesiyor(Map<String, dynamic> data) {
      final cSehir = courierSehir(data);
      final cIlce = courierIlce(data);

      return cSehir == normSehir && cIlce == normIlce;
    }

    bool uygunMu(String courierId, Map<String, dynamic> data) {
      if (triedSet.contains(courierId)) {
        return false;
      }

      if (!aktifMi(data)) {
        return false;
      }

      if (!konumEslesiyor(data)) {
        return false;
      }

      final availabilityRaw =
          (data['availability'] ?? '').toString().toLowerCase().trim();
      final uygunlukDurumuRaw =
          (data['uygunlukDurumu'] ?? '').toString().toLowerCase().trim();
      final uygunlukRaw =
          (data['uygunluk'] ?? '').toString().toLowerCase().trim();

      final aktifSiparis = _toInt(data['aktifSiparis']);
      int maxAktifSiparis = _toInt(data['maxAktifSiparis'], defaultValue: 3);
      if (maxAktifSiparis <= 0) {
        maxAktifSiparis = 1;
      }

      bool isAvailableValue(String v) {
        return v == 'musait' || v == 'müsait' || v == 'available';
      }

      bool isBusyValue(String v) {
        return v == 'gorevde' || v == 'görevde' || v == 'busy';
      }

// Öncelik:
// 1) availability
// 2) uygunlukDurumu
// 3) uygunluk
      bool durumUygun;
      if (availabilityRaw.isNotEmpty) {
        durumUygun = isAvailableValue(availabilityRaw);
      } else if (uygunlukDurumuRaw.isNotEmpty) {
        durumUygun = isAvailableValue(uygunlukDurumuRaw);
      } else if (uygunlukRaw.isNotEmpty) {
        durumUygun = isAvailableValue(uygunlukRaw);
      } else {
        durumUygun = false;
      }

// Güvenlik:
// Eğer aktifSiparis kapasiteyi doldurmuşsa yine uygun sayma.
      final kapasiteUygun = aktifSiparis < maxAktifSiparis;

// Sadece eski 'uygunluk' alanı Görevde diye kuryeyi eleme.
// Çünkü sende gerçek canlı durum availability / uygunlukDurumu içinde tutuluyor.
      // TEST STABİLİZASYON
      return true;
    }

    bool saticiyaBagliMi(Map<String, dynamic> data) {
      final kuryeTipi =
          (data['kuryeTipi'] ?? '').toString().trim().toLowerCase();

      final sellerIdsRaw = data['sellerIds'];
      final sellerIds = sellerIdsRaw is List
          ? sellerIdsRaw
              .map((e) => _normalize(e.toString()))
              .where((e) => e.isNotEmpty)
              .toList()
          : <String>[];

      return kuryeTipi == 'satici_bagli' &&
          normSaticiId.isNotEmpty &&
          sellerIds.contains(normSaticiId);
    }

    bool platformKuryesiMi(Map<String, dynamic> data) {
      final kuryeTipi =
          (data['kuryeTipi'] ?? '').toString().trim().toLowerCase();

      return kuryeTipi.isEmpty ||
          kuryeTipi == 'platform' ||
          kuryeTipi == 'platform_havuzu' ||
          kuryeTipi == 'genel';
    }

    double hesaplaSkor(Map<String, dynamic> data) {
      final distance = _courierDistanceKm(
            data: data,
            orderLat: orderLat,
            orderLng: orderLng,
          ) ??
          50.0;

      final aktifSiparis = _toInt(data['aktifSiparis']);
      int maxAktif = _toInt(data['maxAktifSiparis'], defaultValue: 3);
      if (maxAktif <= 0) {
        maxAktif = 1;
      }
      final rating = _toDouble(data['rating']) ?? 0.0;

      final distanceScore = distance / 10.0;
      final capacityScore = aktifSiparis / maxAktif;
      final ratingScore = (5.0 - rating) / 5.0;

      return (distanceScore * 0.50) +
          (capacityScore * 0.25) +
          (ratingScore * 0.25);
    }

    List<QueryDocumentSnapshot<Map<String, dynamic>>> sirala(
      List<QueryDocumentSnapshot<Map<String, dynamic>>> liste,
    ) {
      liste.sort((a, b) {
        final skorA = hesaplaSkor(a.data());
        final skorB = hesaplaSkor(b.data());
        return skorA.compareTo(skorB);
      });

      return liste;
    }

    final tumUygunKuryeler =
        courierQuery.docs.where((doc) => uygunMu(doc.id, doc.data())).toList();

    if (tumUygunKuryeler.isEmpty) {
      debugPrint(
        'Kurye var ama kapasite/uygunluk/lokasyon nedeniyle atanamadı.',
      );
      return [];
    }

    if (saticiKuryeAktif && normSaticiId.isNotEmpty) {
      final saticiBagliKuryeler =
          tumUygunKuryeler.where((doc) => saticiyaBagliMi(doc.data())).toList();

      if (saticiBagliKuryeler.isNotEmpty) {
        debugPrint(
          'Seller-linked aday bulundu: ${saticiBagliKuryeler.length}',
        );
        return sirala(saticiBagliKuryeler);
      }
    }

    final platformKuryeleri =
        tumUygunKuryeler.where((doc) => platformKuryesiMi(doc.data())).toList();

    if (platformKuryeleri.isNotEmpty) {
      debugPrint(
        'Platform havuzu adayı bulundu: ${platformKuryeleri.length}',
      );
      return sirala(platformKuryeleri);
    }

    debugPrint(
      'Seller/platform ayrımı eşleşmedi. Fallback olarak tüm uygun kuryeler kullanılacak: ${tumUygunKuryeler.length}',
    );
    return sirala(tumUygunKuryeler);
  }

  Future<bool> sipariseOtomatikKuryeAta({
    required String orderId,
    required String sehir,
    required String ilce,
    String? saticiId,
    bool saticiKuryeAktif = true,
    double? orderLat,
    double? orderLng,
    List<String> triedCourierIds = const [],
  }) async {
    try {
      final orderRef = _firestore.collection('orders').doc(orderId);
      final orderSnap = await orderRef.get();

      if (!orderSnap.exists) {
        debugPrint('sipariseOtomatikKuryeAta: sipariş bulunamadı. $orderId');
        return false;
      }

      final orderData = orderSnap.data() as Map<String, dynamic>;

      final mergedTriedCourierIds = <String>{
        ..._extractTriedCourierIds(orderData),
        ...triedCourierIds.where((e) => e.trim().isNotEmpty),
      }.toList();

      await orderRef.set({
        'retryCount': _toInt(orderData['retryCount']),
        'maxRetryCount': _toInt(orderData['maxRetryCount'],
            defaultValue: _defaultMaxRetryCount),
        'retryStatus': (orderData['retryStatus'] ?? 'idle').toString(),
        'retryScheduledAt': orderData['retryScheduledAt'],
        'lastRetryAt': orderData['lastRetryAt'],
        'lastRetryReason': orderData['lastRetryReason'],
        'lastTriedCourierIds': mergedTriedCourierIds,
        'triedCourierIds': mergedTriedCourierIds,
        'assignmentLogs': orderData['assignmentLogs'] ?? [],
      }, SetOptions(merge: true));

      final uygunKurye = await enUygunKuryeyiBul(
        sehir: sehir,
        ilce: ilce,
        saticiId: saticiId,
        saticiKuryeAktif: saticiKuryeAktif,
        orderLat: orderLat,
        orderLng: orderLng,
        triedCourierIds: mergedTriedCourierIds,
      );

      if (uygunKurye == null) {
        await _scheduleRetryForOrder(
          orderId: orderId,
          existingOrderData: orderData,
          reason: 'no_available_courier',
          extraFields: {
            'courierAssignmentType': 'seller_first_then_platform',
            'courierAssignmentResult': 'no_courier_found',
            'assignmentUpdatedAt': FieldValue.serverTimestamp(),
          },
        );

        debugPrint('Siparişe otomatik kurye atanamadı: $orderId');
        return false;
      }

      final courierId = uygunKurye['courierId'].toString().trim();
      final courierName = uygunKurye['adSoyad'].toString().trim();
      final assignmentType =
          (uygunKurye['assignmentType'] ?? 'automatic').toString();
      final distanceKm = uygunKurye['distanceKm'];

      final courierRef = _firestore.collection('couriers').doc(courierId);

      await _firestore.runTransaction((transaction) async {
        final courierSnap = await transaction.get(courierRef);
        final latestOrderSnap = await transaction.get(orderRef);

        if (!courierSnap.exists || !latestOrderSnap.exists) {
          throw Exception('Kurye veya sipariş dokümanı bulunamadı.');
        }

        final latestOrderData = latestOrderSnap.data() as Map<String, dynamic>;
        final mevcutDurum =
            (latestOrderData['assignmentStatus'] ?? '').toString().trim();

        if (mevcutDurum == 'assigned') {
          debugPrint('Sipariş zaten atanmış: $orderId');
          return;
        }

        final courierData = courierSnap.data() as Map<String, dynamic>;
        final mevcutAktifSiparis = _toInt(courierData['aktifSiparis']);
        int maxAktifSiparis =
            _toInt(courierData['maxAktifSiparis'], defaultValue: 3);
        if (maxAktifSiparis <= 0) {
          maxAktifSiparis = 1;
        }

        final yeniAktifSiparis = mevcutAktifSiparis + 1;

        transaction.set(
          orderRef,
          {
            'assignedCourierId': courierId,
            'assignedCourierName': courierName,
            'assignmentStatus': 'assigned',
            'status': 'on_the_way',
            'assignmentAt': FieldValue.serverTimestamp(),
            'assignmentUpdatedAt': FieldValue.serverTimestamp(),
            'courierAssignmentType': assignmentType,
            'courierAssignmentResult': 'assigned',
            'courierOfferStatus': 'pending',
            'courierOfferedAt': FieldValue.serverTimestamp(),
            'courierRespondedAt': null,
            'courierRejectReason': null,
            'assignedCourierDistanceKm': distanceKm,
            'retryStatus': 'idle',
            'retryScheduledAt': null,
            'lastRetryReason': null,
            'lastTriedCourierIds': FieldValue.arrayUnion([courierId]),
            'triedCourierIds': FieldValue.arrayUnion([courierId]),
            'updatedAt': FieldValue.serverTimestamp(),
            'assignmentLogs': FieldValue.arrayUnion([
              {
                'type': 'assigned',
                'courierId': courierId,
                'courierName': courierName,
                'assignmentType': assignmentType,
                'distanceKm': distanceKm,
                'at': DateTime.now().toIso8601String(),
              }
            ]),
          },
          SetOptions(merge: true),
        );

        transaction.set(
          courierRef,
          {
            'aktifSiparis': yeniAktifSiparis,
            'currentOrderId': orderId,
            'lastAssignedAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),

            // Tekil aktiflik alanlarını eşitle
            'aktifMi': true,
            'isActive': true,

            // Canlı görev durumu: sipariş atanmışsa kurye görevde kabul edilir
            'availability': 'gorevde',
            'uygunlukDurumu': 'gorevde',
            'uygunluk': 'Görevde',
          },
          SetOptions(merge: true),
        );
      });

      debugPrint(
        'Kurye otomatik atandı. orderId=$orderId courierId=$courierId type=$assignmentType distanceKm=${distanceKm?.toString() ?? '-'}',
      );
      return true;
    } catch (e) {
      debugPrint('sipariseOtomatikKuryeAta hata: $e');

      final orderRef = _firestore.collection('orders').doc(orderId);
      final orderSnap = await orderRef.get();

      if (orderSnap.exists) {
        final orderData = orderSnap.data() as Map<String, dynamic>;
        await _scheduleRetryForOrder(
          orderId: orderId,
          existingOrderData: orderData,
          reason: 'assignment_exception',
          extraFields: {
            'courierAssignmentType': 'seller_first_then_platform',
            'courierAssignmentResult': 'error',
            'assignmentUpdatedAt': FieldValue.serverTimestamp(),
          },
        );
      } else {
        await orderRef.set({
          'assignmentStatus': 'waiting_courier',
          'courierAssignmentType': 'seller_first_then_platform',
          'courierAssignmentResult': 'error',
          'assignmentUpdatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      return false;
    }
  }

  Future<bool> siparisiYenidenAtamayiDene(String orderId) async {
    try {
      final orderSnap =
          await _firestore.collection('orders').doc(orderId).get();

      if (!orderSnap.exists) {
        debugPrint('siparisiYenidenAtamayiDene: sipariş bulunamadı');
        return false;
      }

      final orderData = orderSnap.data() as Map<String, dynamic>;

      String sehir = _normalize(orderData['sehir']);
      String ilce = _normalize(orderData['ilce']);
      String saticiId = _normalize(orderData['saticiId']);

      if (sehir.isEmpty || ilce.isEmpty) {
        final meta = orderData['meta'];
        if (meta is Map<String, dynamic>) {
          final adres = meta['adres'];
          if (adres is Map<String, dynamic>) {
            sehir = _normalize(adres['sehir']);
            ilce = _normalize(adres['ilce']);
          }
        }
      }

      if (sehir.isEmpty || ilce.isEmpty) {
        final adres = orderData['adres'];
        if (adres is Map<String, dynamic>) {
          sehir = _normalize(adres['sehir']);
          ilce = _normalize(adres['ilce']);
        }
      }

      if (saticiId.isEmpty) {
        saticiId = _normalize(orderData['sellerId']);
      }
      if (saticiId.isEmpty) {
        saticiId = _normalize(orderData['merchantId']);
      }

      if (saticiId.isEmpty) {
        final items = orderData['items'];
        if (items is List && items.isNotEmpty) {
          final firstItem = items.first;
          if (firstItem is Map<String, dynamic>) {
            saticiId = _normalize(firstItem['saticiId']);
            if (saticiId.isEmpty) {
              saticiId = _normalize(firstItem['sellerId']);
            }
          }
        }
      }

      bool saticiKuryeAktif = true;
      final rawSaticiKuryeAktif = orderData['saticiKuryeAktif'];
      if (rawSaticiKuryeAktif is bool) {
        saticiKuryeAktif = rawSaticiKuryeAktif;
      }

      final latLng = _extractLatLngFromMaps(orderData);
      final orderLat = _toDouble(orderData['lat']) ?? latLng['lat'];
      final orderLng = _toDouble(orderData['lng']) ?? latLng['lng'];

      final triedCourierIds = _extractTriedCourierIds(orderData);

      await _firestore.collection('orders').doc(orderId).set({
        'assignmentTryCount': FieldValue.increment(1),
        'assignmentUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      return await sipariseOtomatikKuryeAta(
        orderId: orderId,
        sehir: sehir,
        ilce: ilce,
        saticiId: saticiId,
        saticiKuryeAktif: saticiKuryeAktif,
        orderLat: orderLat,
        orderLng: orderLng,
        triedCourierIds: triedCourierIds,
      );
    } catch (e) {
      debugPrint('siparisiYenidenAtamayiDene hata: $e');
      return false;
    }
  }

  Future<bool> kuryeTeklifiKabulEt({
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

        final orderData = orderSnap.data() as Map<String, dynamic>;
        final assignedCourierId =
            (orderData['assignedCourierId'] ?? '').toString().trim();

        if (assignedCourierId != courierId) {
          throw Exception('Bu sipariş bu kuryeye atanmış görünmüyor.');
        }

        transaction.set(
          orderRef,
          {
            'courierOfferStatus': 'accepted',
            'courierRespondedAt': FieldValue.serverTimestamp(),
            'status': 'on_the_way',
            'assignmentStatus': 'assigned',
            'retryStatus': 'idle',
            'retryScheduledAt': null,
            'statusUpdatedAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
            'assignmentLogs': FieldValue.arrayUnion([
              {
                'type': 'offer_accepted',
                'courierId': courierId,
                'at': DateTime.now().toIso8601String(),
              }
            ]),
          },
          SetOptions(merge: true),
        );

        transaction.set(
          courierRef,
          {
            'lastAcceptedAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
            'aktifMi': true,
            'isActive': true,
            'availability': 'gorevde',
            'uygunlukDurumu': 'gorevde',
            'uygunluk': 'Görevde',
          },
          SetOptions(merge: true),
        );
      });

      return true;
    } catch (e) {
      debugPrint('kuryeTeklifiKabulEt hata: $e');
      return false;
    }
  }

  Future<bool> kuryeTeklifiReddet({
    required String orderId,
    required String courierId,
    String? reason,
  }) async {
    try {
      final orderRef = _firestore.collection('orders').doc(orderId);
      final courierRef = _firestore.collection('couriers').doc(courierId);

      Map<String, dynamic>? orderDataForRetry;

      await _firestore.runTransaction((transaction) async {
        final orderSnap = await transaction.get(orderRef);
        final courierSnap = await transaction.get(courierRef);

        if (!orderSnap.exists || !courierSnap.exists) {
          throw Exception('Sipariş veya kurye bulunamadı.');
        }

        final orderData = orderSnap.data() as Map<String, dynamic>;
        orderDataForRetry = orderData;

        final assignedCourierId =
            (orderData['assignedCourierId'] ?? '').toString().trim();

        if (assignedCourierId != courierId) {
          throw Exception('Bu sipariş bu kuryeye atanmış görünmüyor.');
        }

        final courierData = courierSnap.data() as Map<String, dynamic>;
        final mevcutAktifSiparis = _toInt(courierData['aktifSiparis']);
        final yeniAktifSiparis =
            mevcutAktifSiparis > 0 ? mevcutAktifSiparis - 1 : 0;

        final triedCourierIds = _extractTriedCourierIds(orderData);
        if (!triedCourierIds.contains(courierId)) {
          triedCourierIds.add(courierId);
        }

        transaction.set(
          orderRef,
          {
            'courierOfferStatus': 'rejected',
            'courierRespondedAt': FieldValue.serverTimestamp(),
            'courierRejectReason': (reason ?? '').trim(),
            'assignmentStatus': 'waiting_courier',
            'assignedCourierId': null,
            'assignedCourierName': null,
            'lastTriedCourierIds': triedCourierIds,
            'triedCourierIds': triedCourierIds,
            'assignmentUpdatedAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
            'assignmentLogs': FieldValue.arrayUnion([
              {
                'type': 'offer_rejected',
                'courierId': courierId,
                'reason': (reason ?? '').trim(),
                'at': DateTime.now().toIso8601String(),
              }
            ]),
          },
          SetOptions(merge: true),
        );

        transaction.set(
          courierRef,
          {
            'aktifSiparis': yeniAktifSiparis,
            'currentOrderId': null,
            'availability': yeniAktifSiparis == 0 ? 'musait' : 'gorevde',
            'uygunlukDurumu': yeniAktifSiparis == 0 ? 'musait' : 'gorevde',
            'uygunluk': yeniAktifSiparis == 0 ? 'Müsait' : 'Görevde',
            'aktifMi': true,
            'isActive': true,
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      });

      if (orderDataForRetry != null) {
        final retryOrderData = Map<String, dynamic>.from(orderDataForRetry!);
        final triedCourierIds = _extractTriedCourierIds(retryOrderData);
        if (!triedCourierIds.contains(courierId)) {
          triedCourierIds.add(courierId);
        }
        retryOrderData['lastTriedCourierIds'] = triedCourierIds;
        retryOrderData['triedCourierIds'] = triedCourierIds;

        await _scheduleRetryForOrder(
          orderId: orderId,
          existingOrderData: retryOrderData,
          reason: (reason ?? '').trim().isEmpty
              ? 'courier_rejected'
              : 'courier_rejected_${(reason ?? '').trim()}',
          extraFields: {
            'courierAssignmentType': 'seller_first_then_platform',
            'courierAssignmentResult': 'courier_rejected',
            'assignmentUpdatedAt': FieldValue.serverTimestamp(),
          },
        );
      }

      return true;
    } catch (e) {
      debugPrint('kuryeTeklifiReddet hata: $e');
      return false;
    }
  }

  Future<void> timeoutKontrolVeYenidenAta({
    Duration timeout = const Duration(seconds: 20),
  }) async {
    try {
      final now = DateTime.now();

      final snapshot = await _firestore
          .collection('orders')
          .where('courierOfferStatus', isEqualTo: 'pending')
          .get();

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final orderId = doc.id;

        final offeredAt = data['courierOfferedAt'];
        if (offeredAt is! Timestamp) continue;

        final offeredTime = offeredAt.toDate();
        final fark = now.difference(offeredTime);

        if (fark >= timeout) {
          final courierId = (data['assignedCourierId'] ?? '').toString().trim();
          if (courierId.isEmpty) continue;

          debugPrint('⏱️ Timeout: $orderId → $courierId teklif süresi doldu');

          await kuryeTeklifiReddet(
            orderId: orderId,
            courierId: courierId,
            reason: 'timeout',
          );
        }
      }
    } catch (e) {
      debugPrint('timeoutKontrol hata: $e');
    }
  }

  static Future<bool> sipariseKuryeAta({
    required String orderId,
  }) async {
    try {
      final firestore = FirebaseFirestore.instance;
      final orderRef = firestore.collection('orders').doc(orderId);
      final orderSnap = await orderRef.get();

      if (!orderSnap.exists) {
        debugPrint('sipariseKuryeAta: Sipariş bulunamadı. orderId=$orderId');
        return false;
      }

      await orderRef.set({
        'courierAssignmentTriggered': true,
        'courierAssignmentCheckedAt': FieldValue.serverTimestamp(),
        'assignmentUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      final orderData = orderSnap.data() as Map<String, dynamic>;

      String sehir = _normalize(orderData['sehir']);
      String ilce = _normalize(orderData['ilce']);
      String saticiId = _normalize(orderData['saticiId']);

      if (sehir.isEmpty || ilce.isEmpty) {
        final meta = orderData['meta'];
        if (meta is Map<String, dynamic>) {
          final adres = meta['adres'];
          if (adres is Map<String, dynamic>) {
            sehir = _normalize(adres['sehir']);
            ilce = _normalize(adres['ilce']);
          }
        }
      }

      if (sehir.isEmpty || ilce.isEmpty) {
        final adres = orderData['adres'];
        if (adres is Map<String, dynamic>) {
          sehir = _normalize(adres['sehir']);
          ilce = _normalize(adres['ilce']);
        }
      }

      if (saticiId.isEmpty) {
        saticiId = _normalize(orderData['sellerId']);
      }
      if (saticiId.isEmpty) {
        saticiId = _normalize(orderData['merchantId']);
      }

      if (saticiId.isEmpty) {
        final items = orderData['items'];
        if (items is List && items.isNotEmpty) {
          final firstItem = items.first;
          if (firstItem is Map<String, dynamic>) {
            saticiId = _normalize(firstItem['saticiId']);
            if (saticiId.isEmpty) {
              saticiId = _normalize(firstItem['sellerId']);
            }
          }
        }
      }

      bool saticiKuryeAktif = true;
      final rawSaticiKuryeAktif = orderData['saticiKuryeAktif'];
      if (rawSaticiKuryeAktif is bool) {
        saticiKuryeAktif = rawSaticiKuryeAktif;
      }

      final latLng = _extractLatLngFromMaps(orderData);
      final orderLat = _toDouble(orderData['lat']) ?? latLng['lat'];
      final orderLng = _toDouble(orderData['lng']) ?? latLng['lng'];

      final triedCourierIds = _extractTriedCourierIds(orderData);

      debugPrint(
        'sipariseKuryeAta orderId=$orderId sehir=$sehir ilce=$ilce saticiId=$saticiId saticiKuryeAktif=$saticiKuryeAktif lat=$orderLat lng=$orderLng tried=${triedCourierIds.length}',
      );

      if (sehir.isEmpty || ilce.isEmpty) {
        await orderRef.set({
          'assignmentStatus': 'waiting_courier',
          'courierAssignmentType': 'seller_first_then_platform',
          'courierAssignmentResult': 'missing_location',
          'courierAssignmentError': 'Sehir veya ilce eksik',
          'assignmentUpdatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        return false;
      }

      final servis = OtomatikKuryeAtamaServisi();
      final result = await servis.sipariseOtomatikKuryeAta(
        orderId: orderId,
        sehir: sehir,
        ilce: ilce,
        saticiId: saticiId,
        saticiKuryeAktif: saticiKuryeAktif,
        orderLat: orderLat,
        orderLng: orderLng,
        triedCourierIds: triedCourierIds,
      );

      await orderRef.set({
        'courierAssignmentResult':
            result ? 'assigned_or_processed' : 'deferred',
        'assignmentUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      return result;
    } catch (e) {
      await FirebaseFirestore.instance.collection('orders').doc(orderId).set({
        'courierAssignmentTriggered': true,
        'courierAssignmentResult': 'error',
        'courierAssignmentError': e.toString(),
        'assignmentUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      debugPrint('sipariseKuryeAta static hata: $e');
      return false;
    }
  }

  Future<void> _scheduleRetryForOrder({
    required String orderId,
    required Map<String, dynamic> existingOrderData,
    required String reason,
    Map<String, dynamic>? extraFields,
  }) async {
    final orderRef = _firestore.collection('orders').doc(orderId);

    final retryCount = _toInt(existingOrderData['retryCount']);
    final maxRetryCount = _toInt(
      existingOrderData['maxRetryCount'],
      defaultValue: _defaultMaxRetryCount,
    );

    if (retryCount >= maxRetryCount) {
      await orderRef.set({
        'assignmentStatus': 'manual_review_required',
        'retryStatus': 'exhausted',
        'retryScheduledAt': null,
        'lastRetryReason': 'max_retry_exceeded',
        'assignmentUpdatedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'assignmentLogs': FieldValue.arrayUnion([
          {
            'type': 'retry_exhausted',
            'reason': 'max_retry_exceeded',
            'at': DateTime.now().toIso8601String(),
          }
        ]),
        ...?extraFields,
      }, SetOptions(merge: true));
      return;
    }

    final scheduledAt =
        DateTime.now().add(const Duration(seconds: _retryDelaySeconds));

    await orderRef.set({
      'assignmentStatus': 'retry_scheduled',
      'retryStatus': 'scheduled',
      'retryScheduledAt': Timestamp.fromDate(scheduledAt),
      'lastRetryReason': reason,
      'maxRetryCount': maxRetryCount,
      'assignmentUpdatedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'assignmentLogs': FieldValue.arrayUnion([
        {
          'type': 'retry_scheduled',
          'reason': reason,
          'retryCount': retryCount,
          'scheduledFor': scheduledAt.toIso8601String(),
          'at': DateTime.now().toIso8601String(),
        }
      ]),
      ...?extraFields,
    }, SetOptions(merge: true));
  }

  static List<String> _extractTriedCourierIds(Map<String, dynamic> orderData) {
    final result = <String>{};

    final tried1 = orderData['triedCourierIds'];
    if (tried1 is List) {
      for (final item in tried1) {
        final value = item.toString().trim();
        if (value.isNotEmpty) result.add(value);
      }
    }

    final tried2 = orderData['lastTriedCourierIds'];
    if (tried2 is List) {
      for (final item in tried2) {
        final value = item.toString().trim();
        if (value.isNotEmpty) result.add(value);
      }
    }

    final assignedCourierId =
        (orderData['assignedCourierId'] ?? '').toString().trim();
    if (assignedCourierId.isNotEmpty) {
      result.add(assignedCourierId);
    }

    return result.toList();
  }

  static String _normalize(dynamic value) {
    return (value ?? '')
        .toString()
        .trim()
        .toLowerCase()
        .replaceAll('ı', 'i')
        .replaceAll('İ', 'i');
  }

  static Map<String, double?> _extractLatLngFromMaps(
    Map<String, dynamic> data,
  ) {
    double? lat = _toDouble(data['lat']);
    double? lng = _toDouble(data['lng']);

    if (lat != null && lng != null) {
      return {'lat': lat, 'lng': lng};
    }

    final meta = data['meta'];
    if (meta is Map<String, dynamic>) {
      final adres = meta['adres'];
      if (adres is Map<String, dynamic>) {
        lat ??= _toDouble(adres['lat']);
        lng ??= _toDouble(adres['lng']);
      }
    }

    final adres = data['adres'];
    if (adres is Map<String, dynamic>) {
      lat ??= _toDouble(adres['lat']);
      lng ??= _toDouble(adres['lng']);
    }

    return {'lat': lat, 'lng': lng};
  }

  static double? _courierDistanceKm({
    required Map<String, dynamic> data,
    required double? orderLat,
    required double? orderLng,
  }) {
    if (orderLat == null || orderLng == null) return null;

    final courierLat = _toDouble(data['lat']);
    final courierLng = _toDouble(data['lng']);

    if (courierLat == null || courierLng == null) return null;

    return _distanceKm(orderLat, orderLng, courierLat, courierLng);
  }

  static double _distanceKm(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    const earthRadiusKm = 6371.0;

    final dLat = _degToRad(lat2 - lat1);
    final dLng = _degToRad(lng2 - lng1);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degToRad(lat1)) *
            math.cos(_degToRad(lat2)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusKm * c;
  }

  static double _degToRad(double degree) {
    return degree * (math.pi / 180.0);
  }

  static int _toInt(dynamic value, {int defaultValue = 0}) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is double) return value.toInt();
    return int.tryParse(value.toString()) ?? defaultValue;
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString());
  }
}
