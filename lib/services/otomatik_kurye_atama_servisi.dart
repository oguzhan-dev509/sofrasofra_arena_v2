import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class OtomatikKuryeAtamaServisi {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
          'uygunluk': (data['uygunluk'] ?? data['uygunlukDurumu'] ?? 'Müsait')
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
    String normalize(String value) {
      return value
          .trim()
          .toLowerCase()
          .replaceAll('ı', 'i')
          .replaceAll('İ', 'i');
    }

    final normSehir = normalize(sehir);
    final normIlce = normalize(ilce);
    final normSaticiId = normalize(saticiId ?? '');
    final triedSet = triedCourierIds
        .map((e) => e.toString().trim())
        .where((e) => e.isNotEmpty)
        .toSet();

    // Daha esnek yaklaşım:
    // Firestore’da katı where yerine tüm courier kayıtlarını çekip memory içinde filtreliyoruz.
    final courierQuery = await _firestore.collection('couriers').get();

    if (courierQuery.docs.isEmpty) {
      debugPrint('Courier koleksiyonunda hiç kayıt yok.');
      return [];
    }

    bool aktifMi(Map<String, dynamic> data) {
      return data['aktifMi'] == true || data['isActive'] == true;
    }

    String courierSehir(Map<String, dynamic> data) {
      return normalize((data['sehir'] ?? data['city'] ?? '').toString());
    }

    String courierIlce(Map<String, dynamic> data) {
      return normalize((data['ilce'] ?? data['district'] ?? '').toString());
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

      final uygunluk = (data['uygunluk'] ??
              data['uygunlukDurumu'] ??
              data['availability'] ??
              '')
          .toString()
          .toLowerCase()
          .trim();

      final aktifSiparis = _toInt(data['aktifSiparis']);
      int maxAktifSiparis = _toInt(data['maxAktifSiparis'], defaultValue: 3);
      if (maxAktifSiparis <= 0) {
        maxAktifSiparis = 1;
      }

      final durumUygun = uygunluk == 'musait' ||
          uygunluk == 'müsait' ||
          uygunluk == 'available';
      return durumUygun && aktifSiparis < maxAktifSiparis;
    }

    bool saticiyaBagliMi(Map<String, dynamic> data) {
      final kuryeTipi =
          (data['kuryeTipi'] ?? '').toString().trim().toLowerCase();

      final sellerIdsRaw = data['sellerIds'];
      final sellerIds = sellerIdsRaw is List
          ? sellerIdsRaw
              .map((e) => normalize(e.toString()))
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
      final capacityScore = maxAktif == 0 ? 1.0 : (aktifSiparis / maxAktif);
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
          'Kurye var ama kapasite/uygunluk/lokasyon nedeniyle atanamadı.');
      return [];
    }

    // 1) Seller-linked öncelik
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

    // 2) Platform havuzu
    final platformKuryeleri =
        tumUygunKuryeler.where((doc) => platformKuryesiMi(doc.data())).toList();

    if (platformKuryeleri.isNotEmpty) {
      debugPrint(
        'Platform havuzu adayı bulundu: ${platformKuryeleri.length}',
      );
      return sirala(platformKuryeleri);
    }

    // 3) Çok kritik fallback:
    // Seller id çözülememiş olsa bile, uygun tüm kuryelerden seçim yap.
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
      final uygunKurye = await enUygunKuryeyiBul(
        sehir: sehir,
        ilce: ilce,
        saticiId: saticiId,
        saticiKuryeAktif: saticiKuryeAktif,
        orderLat: orderLat,
        orderLng: orderLng,
        triedCourierIds: triedCourierIds,
      );

      if (uygunKurye == null) {
        await _firestore.collection('orders').doc(orderId).set({
          'assignmentStatus': 'waiting_courier',
          'courierAssignmentType': 'seller_first_then_platform',
          'courierAssignmentResult': 'waiting_courier',
          'assignmentUpdatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        debugPrint('Siparişe otomatik kurye atanamadı: $orderId');
        return false;
      }

      final courierId = uygunKurye['courierId'].toString();
      final courierName = uygunKurye['adSoyad'].toString();
      final assignmentType =
          (uygunKurye['assignmentType'] ?? 'automatic').toString();
      final distanceKm = uygunKurye['distanceKm'];

      final courierRef = _firestore.collection('couriers').doc(courierId);
      final orderRef = _firestore.collection('orders').doc(orderId);

      await _firestore.runTransaction((transaction) async {
        final courierSnap = await transaction.get(courierRef);
        final orderSnap = await transaction.get(orderRef);

        if (!courierSnap.exists || !orderSnap.exists) {
          throw Exception('Kurye veya sipariş dokümanı bulunamadı.');
        }

        final orderData = orderSnap.data() as Map<String, dynamic>;
        final mevcutDurum = (orderData['assignmentStatus'] ?? '').toString();

        if (mevcutDurum == 'assigned') {
          debugPrint('Sipariş zaten atanmış: $orderId');
          return;
        }

        final courierData = courierSnap.data() as Map<String, dynamic>;
        final mevcutAktifSiparis = _toInt(courierData['aktifSiparis']);

        transaction.set(
          orderRef,
          {
            'assignedCourierId': courierId,
            'assignedCourierName': courierName,
            'assignmentStatus': 'assigned',
            'status': 'assigned',
            'assignmentAt': FieldValue.serverTimestamp(),
            'assignmentUpdatedAt': FieldValue.serverTimestamp(),
            'courierAssignmentType': assignmentType,
            'courierAssignmentResult': 'assigned',
            'courierOfferStatus': 'pending',
            'courierOfferedAt': FieldValue.serverTimestamp(),
            'courierRespondedAt': null,
            'courierRejectReason': null,
            'assignedCourierDistanceKm': distanceKm,
          },
          SetOptions(merge: true),
        );

        final yeniAktifSiparis =
            mevcutAktifSiparis > 0 ? mevcutAktifSiparis - 1 : 0;

        transaction.set(
          courierRef,
          {
            'aktifSiparis': yeniAktifSiparis,
            'uygunluk': yeniAktifSiparis == 0 ? 'Müsait' : 'Görevde',
            'updatedAt': FieldValue.serverTimestamp(),
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

      await _firestore.collection('orders').doc(orderId).set({
        'assignmentStatus': 'waiting_courier',
        'courierAssignmentType': 'seller_first_then_platform',
        'courierAssignmentResult': 'error',
        'assignmentUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

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

      String normalize(dynamic value) {
        return (value ?? '')
            .toString()
            .trim()
            .toLowerCase()
            .replaceAll('ı', 'i')
            .replaceAll('İ', 'i');
      }

      String sehir = normalize(orderData['sehir']);
      String ilce = normalize(orderData['ilce']);
      String saticiId = normalize(orderData['saticiId']);

      if (sehir.isEmpty || ilce.isEmpty) {
        final meta = orderData['meta'];
        if (meta is Map<String, dynamic>) {
          final adres = meta['adres'];
          if (adres is Map<String, dynamic>) {
            sehir = normalize(adres['sehir']);
            ilce = normalize(adres['ilce']);
          }
        }
      }

      if (sehir.isEmpty || ilce.isEmpty) {
        final adres = orderData['adres'];
        if (adres is Map<String, dynamic>) {
          sehir = normalize(adres['sehir']);
          ilce = normalize(adres['ilce']);
        }
      }

      if (saticiId.isEmpty) {
        saticiId = normalize(orderData['sellerId']);
      }
      if (saticiId.isEmpty) {
        saticiId = normalize(orderData['merchantId']);
      }

      if (saticiId.isEmpty) {
        final items = orderData['items'];
        if (items is List && items.isNotEmpty) {
          final firstItem = items.first;
          if (firstItem is Map<String, dynamic>) {
            saticiId = normalize(firstItem['saticiId']);
            if (saticiId.isEmpty) {
              saticiId = normalize(firstItem['sellerId']);
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

      final triedCourierIdsRaw = orderData['triedCourierIds'];
      final triedCourierIds = triedCourierIdsRaw is List
          ? triedCourierIdsRaw
              .map((e) => e.toString().trim())
              .where((e) => e.isNotEmpty)
              .toList()
          : <String>[];

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
            'statusUpdatedAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );

        transaction.set(
          courierRef,
          {
            'lastAcceptedAt': FieldValue.serverTimestamp(),
            'uygunluk': 'Görevde',
            'updatedAt': FieldValue.serverTimestamp(),
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

        final courierData = courierSnap.data() as Map<String, dynamic>;
        final mevcutAktifSiparis = _toInt(courierData['aktifSiparis']);

        final triedRaw = orderData['triedCourierIds'];
        final triedCourierIds = triedRaw is List
            ? triedRaw
                .map((e) => e.toString().trim())
                .where((e) => e.isNotEmpty)
                .toList()
            : <String>[];

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
            'triedCourierIds': triedCourierIds,
            'assignmentUpdatedAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );

        transaction.set(
          courierRef,
          {
            'aktifSiparis': mevcutAktifSiparis > 0 ? mevcutAktifSiparis - 1 : 0,
            'uygunluk': 'Görevde',
            'currentOrderId': null,
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      });

      await siparisiYenidenAtamayiDene(orderId);
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

      for (var doc in snapshot.docs) {
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
      final orderSnap = await firestore.collection('orders').doc(orderId).get();

      if (!orderSnap.exists) {
        debugPrint('sipariseKuryeAta: Sipariş bulunamadı. orderId=$orderId');
        return false;
      }

      final orderData = orderSnap.data() as Map<String, dynamic>;

      String normalize(dynamic value) {
        return (value ?? '')
            .toString()
            .trim()
            .toLowerCase()
            .replaceAll('ı', 'i')
            .replaceAll('İ', 'i');
      }

      String sehir = normalize(orderData['sehir']);
      String ilce = normalize(orderData['ilce']);
      String saticiId = normalize(orderData['saticiId']);

      if (sehir.isEmpty || ilce.isEmpty) {
        final meta = orderData['meta'];
        if (meta is Map<String, dynamic>) {
          final adres = meta['adres'];
          if (adres is Map<String, dynamic>) {
            sehir = normalize(adres['sehir']);
            ilce = normalize(adres['ilce']);
          }
        }
      }

      if (sehir.isEmpty || ilce.isEmpty) {
        final adres = orderData['adres'];
        if (adres is Map<String, dynamic>) {
          sehir = normalize(adres['sehir']);
          ilce = normalize(adres['ilce']);
        }
      }

      if (saticiId.isEmpty) {
        saticiId = normalize(orderData['sellerId']);
      }
      if (saticiId.isEmpty) {
        saticiId = normalize(orderData['merchantId']);
      }

      if (saticiId.isEmpty) {
        final items = orderData['items'];
        if (items is List && items.isNotEmpty) {
          final firstItem = items.first;
          if (firstItem is Map<String, dynamic>) {
            saticiId = normalize(firstItem['saticiId']);
            if (saticiId.isEmpty) {
              saticiId = normalize(firstItem['sellerId']);
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

      final triedCourierIdsRaw = orderData['triedCourierIds'];
      final triedCourierIds = triedCourierIdsRaw is List
          ? triedCourierIdsRaw
              .map((e) => e.toString().trim())
              .where((e) => e.isNotEmpty)
              .toList()
          : <String>[];

      debugPrint(
        'sipariseKuryeAta orderId=$orderId sehir=$sehir ilce=$ilce saticiId=$saticiId saticiKuryeAktif=$saticiKuryeAktif lat=$orderLat lng=$orderLng tried=${triedCourierIds.length}',
      );

      if (sehir.isEmpty || ilce.isEmpty) {
        await firestore.collection('orders').doc(orderId).set({
          'assignmentStatus': 'waiting_courier',
          'courierAssignmentType': 'seller_first_then_platform',
          'courierAssignmentResult': 'missing_location',
          'assignmentUpdatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        return false;
      }

      final servis = OtomatikKuryeAtamaServisi();
      return await servis.sipariseOtomatikKuryeAta(
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
      debugPrint('sipariseKuryeAta static hata: $e');
      return false;
    }
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
