import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:sofrasofra_arena_v2/services/otomatik_kurye_atama_servisi.dart';

class SepetService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static String get _cartId {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null && user.uid.isNotEmpty) {
      return user.uid;
    }

    return 'guest_cart';
  }

  static const int _defaultMaxRetryCount = 5;

  static Future<void> sepeteEkle({
    required String urunId,
    required String urunAdi,
    required String dukkanAdi,
    required String kategori,
    required String img,
    required double fiyat,
    double? gelAlFiyat,
    double? goturFiyat,
    String teslimatTipi = 'gel_al',
    bool deliveryIncludedInPrice = false,
    bool feeIncludedInPrice = false,
    String? saticiId,
    String? dukkanId,
  }) async {
    final sepetRef = _firestore.collection('sepetler').doc(_cartId);
    final itemsRef = sepetRef.collection('items');
    debugPrint(
        'SEPET DEBUG cartId=$_cartId urunId=$urunId saticiId=$saticiId dukkanId=$dukkanId');
    final String finalSaticiId = _normalizeSellerId(
      saticiId ?? dukkanId ?? dukkanAdi,
    );

    final sellerSnap =
        await _firestore.collection('sellers').doc(finalSaticiId).get();

    final sellerData = sellerSnap.data() ?? {};

    final String rawSellerType =
        (sellerData['sellerType'] ?? '').toString().trim();

    final String kategoriKey = kategori.toLowerCase().trim();
    final String dukkanKey = dukkanAdi.toLowerCase().trim();

    final bool looksLikeChefSignature = kategoriKey.contains('şef') ||
        kategoriKey.contains('sef') ||
        kategoriKey.contains('usta') ||
        kategoriKey.contains('imza') ||
        dukkanKey.contains('şef') ||
        dukkanKey.contains('sef') ||
        dukkanKey.contains('imza');

    final String sellerType = rawSellerType.isNotEmpty
        ? rawSellerType
        : (looksLikeChefSignature ? 'chef_signature' : 'ev_lezzetleri');

    final String paymentChannel =
        sellerType == 'chef_signature' ? 'chef_signature_order' : 'ev_order';

    final String iyzicoCategory =
        sellerType == 'chef_signature' ? 'ChefSignature' : 'EvLezzetleri';

    final String orderSource =
        sellerType == 'chef_signature' ? 'chef_signature_dish' : 'ev_product';
    final List<String> teslimatModlari = _asStringList(
      sellerData['teslimatModlari'],
    );

    final bool platformKuryeAktif =
        _asBool(sellerData['platformKuryeAktif'], defaultValue: true);

    final bool saticiKuryeAktif =
        _asBool(sellerData['saticiKuryeAktif'], defaultValue: false);

    final bool gelAlAktif =
        _asBool(sellerData['gelAlAktif'], defaultValue: true);

    String deliveryMode =
        (sellerData['varsayilanTeslimatModu'] ?? 'platform_kurye').toString();

    if (teslimatModlari.isNotEmpty && !teslimatModlari.contains(deliveryMode)) {
      deliveryMode = teslimatModlari.first;
    }

    if (deliveryMode.trim().isEmpty) {
      if (platformKuryeAktif) {
        deliveryMode = 'platform_kurye';
      } else if (saticiKuryeAktif) {
        deliveryMode = 'satici_kuryesi';
      } else {
        deliveryMode = 'gel_al';
      }
    }
// Kullanıcının seçtiği teslimat tipi sepetin gerçek teslimat modunu belirler.
    if (teslimatTipi == 'gel_al') {
      deliveryMode = 'gel_al';
    } else if (teslimatTipi == 'gotur') {
      deliveryMode = platformKuryeAktif
          ? 'platform_kurye'
          : (saticiKuryeAktif ? 'satici_kuryesi' : 'platform_kurye');
    }
    final sepetSnap = await sepetRef.get();
    final sepetData = sepetSnap.data();

    final mevcutSepetSaticiId =
        (sepetData?['saticiId'] ?? '').toString().trim();

    if (mevcutSepetSaticiId.isNotEmpty &&
        mevcutSepetSaticiId != finalSaticiId) {
      throw Exception(
        'Aynı anda yalnızca tek satıcıdan sipariş verebilirsiniz.',
      );
    }

    final mevcutQuery =
        await itemsRef.where('urunId', isEqualTo: urunId).limit(1).get();

    final batch = _firestore.batch();

    batch.set(
      sepetRef,
      {
        'userId': _cartId,
        'dukkanId': finalSaticiId,
        'dukkanAd': dukkanAdi,
        'saticiId': finalSaticiId,
        'sellerType': sellerType,
        'paymentChannel': paymentChannel,
        'iyzicoCategory': iyzicoCategory,
        'orderSource': orderSource,
        'teslimatModlari': teslimatModlari,
        'deliveryMode': deliveryMode,
        'siparisTipi': deliveryMode == 'gel_al' ? 'gel_al' : 'teslimat',
        'platformKuryeAktif': platformKuryeAktif,
        'saticiKuryeAktif': saticiKuryeAktif,
        'gelAlAktif': gelAlAktif,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    if (mevcutQuery.docs.isNotEmpty) {
      final doc = mevcutQuery.docs.first;

      batch.update(doc.reference, {
        'urunAdi': urunAdi,
        'dukkanAdi': dukkanAdi,
        'dukkan': dukkanAdi,
        'kategori': kategori,
        'img': img,
        'fiyat': teslimatTipi == 'gotur'
            ? (goturFiyat ?? fiyat)
            : (gelAlFiyat ?? fiyat),
        'birimFiyat': teslimatTipi == 'gotur'
            ? (goturFiyat ?? fiyat)
            : (gelAlFiyat ?? fiyat),
        'gelAlFiyat': gelAlFiyat ?? fiyat,
        'goturFiyat': goturFiyat ?? fiyat,
        'teslimatTipi': teslimatTipi,
        'deliveryIncludedInPrice': deliveryIncludedInPrice,
        'feeIncludedInPrice': feeIncludedInPrice,
        'adet': 1,
        'saticiId': finalSaticiId,
        'addedAt': FieldValue.serverTimestamp(),
      });
    } else {
      final yeniDoc = itemsRef.doc(urunId);

      batch.set(yeniDoc, {
        'urunId': urunId,
        'urunAdi': urunAdi,
        'dukkanAdi': dukkanAdi,
        'dukkan': dukkanAdi,
        'kategori': kategori,
        'img': img,
        'fiyat': teslimatTipi == 'gotur'
            ? (goturFiyat ?? fiyat)
            : (gelAlFiyat ?? fiyat),
        'birimFiyat': teslimatTipi == 'gotur'
            ? (goturFiyat ?? fiyat)
            : (gelAlFiyat ?? fiyat),
        'gelAlFiyat': gelAlFiyat ?? fiyat,
        'goturFiyat': goturFiyat ?? fiyat,
        'teslimatTipi': teslimatTipi,
        'deliveryIncludedInPrice': deliveryIncludedInPrice,
        'feeIncludedInPrice': feeIncludedInPrice,
        'adet': 1,
        'saticiId': finalSaticiId,
        'addedAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
    await _sepetToplamlariniGuncelle();
  }

  static Future<void> sepetiBosalt() async {
    final sepetRef = _firestore.collection('sepetler').doc(_cartId);
    final itemsSnap = await sepetRef.collection('items').get();

    final batch = _firestore.batch();

    for (final itemDoc in itemsSnap.docs) {
      batch.delete(itemDoc.reference);
    }

    batch.set(
      sepetRef,
      {
        'userId': _cartId,
        'araToplam': 0,
        'teslimatUcreti': 0,
        'genelToplam': 0,
        'urunSayisi': 0,
        'deliveryMode': null,
        'siparisTipi': null,
        'sellerType': null,
        'paymentChannel': null,
        'iyzicoCategory': null,
        'orderSource': null,
        'teslimatModlari': <String>[],
        'platformKuryeAktif': null,
        'saticiKuryeAktif': null,
        'gelAlAktif': null,
        'saticiId': null,
        'dukkanId': null,
        'dukkanAd': null,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    await batch.commit();
  }

  static Future<String> siparisiTamamla({
    String musteriAd = 'Demo Müşteri',
    String musteriTelefon = '0555 000 00 00',
    String teslimatAdresi = 'Kadıköy / İstanbul',
    String sehir = 'istanbul',
    String ilce = 'kadikoy',
    String? not,
    double? lat,
    double? lng,
    String paymentMethod = 'cash',
    Map<String, dynamic>? finance,
  }) async {
    final sepetRef = _firestore.collection('sepetler').doc(_cartId);
    var sepetSnap = await sepetRef.get();

    if (!sepetSnap.exists) {
      throw Exception('Sepet bulunamadı.');
    }

// Sipariş oluşturmadan önce sepet toplamlarını son kez merkezi olarak güncelle.
    await _sepetToplamlariniGuncelle();

    sepetSnap = await sepetRef.get();
    final sepetData = sepetSnap.data() ?? {};
    final itemsSnap = await sepetRef.collection('items').get();

    if (itemsSnap.docs.isEmpty) {
      throw Exception('Sepet boş. Önce ürün ekleyin.');
    }

    final String saticiId = (sepetData['saticiId'] ?? '').toString().trim();
    final String dukkanAdi = (sepetData['dukkanAd'] ?? '').toString().trim();
    final String sellerType =
        (sepetData['sellerType'] ?? 'ev_lezzetleri').toString();
    final String paymentChannel = (sepetData['paymentChannel'] ??
            (sellerType == 'chef_signature'
                ? 'chef_signature_order'
                : 'ev_order'))
        .toString();

    final String iyzicoCategory = (sepetData['iyzicoCategory'] ??
            (sellerType == 'chef_signature' ? 'ChefSignature' : 'EvLezzetleri'))
        .toString();

    final String orderSource = (sepetData['orderSource'] ??
            (sellerType == 'chef_signature'
                ? 'chef_signature_dish'
                : 'ev_product'))
        .toString();
    final List<String> teslimatModlari = _asStringList(
      sepetData['teslimatModlari'],
    );

    final bool platformKuryeAktif =
        _asBool(sepetData['platformKuryeAktif'], defaultValue: true);

    final bool saticiKuryeAktif =
        _asBool(sepetData['saticiKuryeAktif'], defaultValue: false);

    final bool gelAlAktif =
        _asBool(sepetData['gelAlAktif'], defaultValue: true);

    final String deliveryMode =
        (sepetData['deliveryMode'] ?? 'platform_kurye').toString();

    final String siparisTipi =
        (sepetData['siparisTipi'] ?? 'teslimat').toString();

    final double araToplam = _asDouble(sepetData['araToplam']);
    final double teslimatUcreti = _asDouble(sepetData['teslimatUcreti']);
    final double genelToplam = _asDouble(sepetData['genelToplam']);
    final int urunSayisi = _asInt(sepetData['urunSayisi']);

    final String assignmentStatus =
        _assignmentStatusForDeliveryMode(deliveryMode);

    final String initialStatus = _initialStatusForDeliveryMode(deliveryMode);

    final orderRef = _firestore.collection('orders').doc();
    final sellerOrderRef = _firestore.collection('sellerOrders').doc();
    final timelineRef = _firestore.collection('orderTimeline').doc();

    final String siparisNo = orderRef.id;

    final batch = _firestore.batch();

    batch.set(orderRef, {
      'siparisNo': siparisNo,
      'userId': _cartId,
      'musteriAd': musteriAd,
      'musteriTelefon': musteriTelefon,
      'teslimatAdresi': teslimatAdresi,
      'adres': teslimatAdresi,
      'sehir': sehir.toLowerCase().trim(),
      'ilce': ilce.toLowerCase().trim(),
      'not': (not ?? '').trim(),
      'paymentMethod': paymentMethod,
      'paymentStatus': 'pending',
      'saticiId': saticiId,
      'saticiAdi': dukkanAdi,
      'dukkanId': saticiId,
      'dukkanAdi': dukkanAdi,
      'sellerType': sellerType,
      'paymentChannel': paymentChannel,
      'iyzicoCategory': iyzicoCategory,
      'orderSource': orderSource,
      'teslimatModlari': teslimatModlari,
      'deliveryMode': deliveryMode,
      'siparisTipi': siparisTipi,
      'platformKuryeAktif': platformKuryeAktif,
      'saticiKuryeAktif': saticiKuryeAktif,
      'gelAlAktif': gelAlAktif,

      // Assignment
      'assignmentStatus': assignmentStatus,
      'assignmentTryCount': 0,
      'assignedCourierId': null,
      'assignedCourierName': null,
      'courierAssignmentType': null,
      'courierAssignmentResult': null,
      'courierAssignmentTriggered': false,
      'courierAssignmentCheckedAt': null,
      'courierAssignmentError': null,
      'assignmentExpiresAt': null,
      'lastAssignmentAt': null,

      // Retry engine
      'retryCount': 0,
      'maxRetryCount': _defaultMaxRetryCount,
      'retryStatus': 'idle',
      'retryScheduledAt': null,
      'lastRetryAt': null,
      'lastRetryReason': null,
      'lastTriedCourierIds': <String>[],

      // Legacy / compatibility
      'triedCourierIds': <String>[],
      'reassignmentHistory': <Map<String, dynamic>>[],
      'assignmentLogs': <Map<String, dynamic>>[],

      // Seller courier legacy
      'sellerCourierId': null,
      'sellerCourierName': null,

      // Order status
      'status': 'awaiting_payment',
      'durum': 'awaiting_payment',
      'paymentProvider': 'iyzico',
      'iyzicoToken': null,
      'paymentConversationId': null,
      // Totals
      'araToplam': araToplam,
      'teslimatUcreti': teslimatUcreti,
      'genelToplam': genelToplam,
      'urunSayisi': urunSayisi,
// Finance
      'finance': finance ?? <String, dynamic>{},
      'productTotal': finance?['productTotal'] ?? araToplam,
      'deliveryFee': finance?['deliveryFee'] ?? teslimatUcreti,
      'customerTotalPayment': finance?['customerTotalPayment'] ?? genelToplam,
      'producerNetAmount': finance?['producerNetAmount'] ?? araToplam,
      'courierNetAmount': finance?['courierNetAmount'] ?? teslimatUcreti,
      'platformTotalRevenue': finance?['platformTotalRevenue'] ?? 0,
      'paymentProcessingFee': finance?['paymentProcessingFee'] ?? 0,
      'producerCommissionAmount': finance?['producerCommissionAmount'] ?? 0,
      'courierCommissionAmount': finance?['courierCommissionAmount'] ?? 0,
      // Location
      'lat': lat,
      'lng': lng,
      'meta': {
        'adres': {
          'acikAdres': teslimatAdresi,
          'telefon': musteriTelefon,
          'sehir': sehir,
          'ilce': ilce,
          'lat': lat,
          'lng': lng,
        },
      },

      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    batch.set(sellerOrderRef, {
      'orderId': orderRef.id,
      'siparisNo': siparisNo,
      'userId': _cartId,
      'saticiId': saticiId,
      'saticiAdi': dukkanAdi,
      'sellerType': sellerType,
      'paymentChannel': paymentChannel,
      'iyzicoCategory': iyzicoCategory,
      'orderSource': orderSource,
      'status': initialStatus,
      'durum': initialStatus,
      'deliveryMode': deliveryMode,
      'assignmentStatus': assignmentStatus,
      'araToplam': araToplam,
      'teslimatUcreti': teslimatUcreti,
      'genelToplam': genelToplam,
      'urunSayisi': urunSayisi,
      // Finance
      'finance': finance ?? <String, dynamic>{},
      'producerNetAmount': finance?['producerNetAmount'] ?? araToplam,
      'platformTotalRevenue': finance?['platformTotalRevenue'] ?? 0,
      'paymentProcessingFee': finance?['paymentProcessingFee'] ?? 0,
      'producerCommissionAmount': finance?['producerCommissionAmount'] ?? 0,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    for (final itemDoc in itemsSnap.docs) {
      final item = itemDoc.data();
      final sellerOrderItemRef =
          sellerOrderRef.collection('items').doc(itemDoc.id);

      batch.set(sellerOrderItemRef, {
        'urunId': item['urunId'],
        'urunAdi': item['urunAdi'],
        'dukkanAdi': item['dukkanAdi'],
        'dukkan': item['dukkan'],
        'kategori': item['kategori'],
        'img': item['img'],
        'fiyat': item['fiyat'],
        'birimFiyat': item['birimFiyat'],
        'adet': item['adet'],
        'saticiId': item['saticiId'],
        'saticiAdi': item['dukkanAdi'],
        'addedAt': item['addedAt'],
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    batch.set(timelineRef, {
      'orderId': orderRef.id,
      'siparisNo': siparisNo,
      'status': initialStatus,
      'actorType': 'system',
      'actorId': _cartId,
      'note': 'Sipariş oluşturuldu',
      'createdAt': FieldValue.serverTimestamp(),
    });

    for (final itemDoc in itemsSnap.docs) {
      batch.delete(itemDoc.reference);
    }

    batch.set(
      sepetRef,
      {
        'araToplam': 0,
        'teslimatUcreti': 0,
        'genelToplam': 0,
        'urunSayisi': 0,
        'deliveryMode': null,
        'siparisTipi': null,
        'sellerType': null,
        'paymentChannel': null,
        'iyzicoCategory': null,
        'orderSource': null,
        'teslimatModlari': <String>[],
        'platformKuryeAktif': null,
        'saticiKuryeAktif': null,
        'gelAlAktif': null,
        'saticiId': null,
        'dukkanId': null,
        'dukkanAd': null,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    await batch.commit();

    // 🔥 PLATFORM KURYE SİPARİŞLERİNDE OTOMATİK KURYE ATA
    if (deliveryMode == 'platform_kurye' && platformKuryeAktif) {
      await orderRef.set({
        'courierAssignmentTriggered': true,
        'courierAssignmentCheckedAt': FieldValue.serverTimestamp(),
        'courierAssignmentResult': 'started',
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      try {
        final assigned = await OtomatikKuryeAtamaServisi.sipariseKuryeAta(
          orderId: orderRef.id,
        );

        await orderRef.set({
          'courierAssignmentResult':
              assigned ? 'assigned_or_offer_sent' : 'not_assigned',
          'courierAssignmentCheckedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (e) {
        await orderRef.set({
          'courierAssignmentResult': 'error',
          'courierAssignmentError': e.toString(),
          'courierAssignmentCheckedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        debugPrint('Kurye atama hatası: $e');
      }
    } else {
      await orderRef.set({
        'courierAssignmentTriggered': false,
        'courierAssignmentResult': 'not_required_for_$deliveryMode',
        'courierAssignmentCheckedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    return orderRef.id;
  }

  static Future<void> _sepetToplamlariniGuncelle() async {
    final sepetRef = _firestore.collection('sepetler').doc(_cartId);
    final sepetSnap = await sepetRef.get();
    final sepetData = sepetSnap.data() ?? {};

    final itemsSnap = await sepetRef.collection('items').get();

    double araToplam = 0;
    int urunSayisi = 0;

    bool tumTeslimatlarFiyataDahil = itemsSnap.docs.isNotEmpty;
    bool tumIslemUcretleriFiyataDahil = itemsSnap.docs.isNotEmpty;

    for (final doc in itemsSnap.docs) {
      final data = doc.data();

      final fiyat = _asDouble(
        data['fiyat'] ?? data['birimFiyat'] ?? data['unitPrice'] ?? 0,
      );

      final adet = _asInt(data['adet'] ?? data['quantity'] ?? 1);
      final safeAdet = adet <= 0 ? 1 : adet;

      final deliveryIncluded =
          _asBool(data['deliveryIncludedInPrice'], defaultValue: false);

      final feeIncluded =
          _asBool(data['feeIncludedInPrice'], defaultValue: false);

      araToplam += fiyat * safeAdet;
      urunSayisi += safeAdet;

      if (!deliveryIncluded) {
        tumTeslimatlarFiyataDahil = false;
      }

      if (!feeIncluded) {
        tumIslemUcretleriFiyataDahil = false;
      }
    }

    final String deliveryMode =
        (sepetData['deliveryMode'] ?? 'platform_kurye').toString();

    final double estimatedDistanceKm = _asDouble(
      sepetData['estimatedDistanceKm'] ??
          sepetData['distanceKm'] ??
          sepetData['mesafeKm'] ??
          0,
    );

    final bool gelAlSiparisi = deliveryMode == 'gel_al';

    final double teslimatUcreti = urunSayisi == 0
        ? 0
        : gelAlSiparisi
            ? 0
            : tumTeslimatlarFiyataDahil
                ? 0
                : _hesaplaTeslimatUcreti(
                    deliveryMode: deliveryMode,
                    urunSayisi: urunSayisi,
                    estimatedDistanceKm: estimatedDistanceKm,
                  );

    final double genelToplam =
        urunSayisi == 0 ? 0 : (araToplam + teslimatUcreti);

    await sepetRef.set({
      'userId': _cartId,
      'araToplam': araToplam,
      'teslimatUcreti': teslimatUcreti,
      'genelToplam': genelToplam,
      'urunSayisi': urunSayisi,
      'deliveryIncludedInPrice': tumTeslimatlarFiyataDahil,
      'feeIncludedInPrice': tumIslemUcretleriFiyataDahil,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static String _assignmentStatusForDeliveryMode(String deliveryMode) {
    switch (deliveryMode) {
      case 'platform_kurye':
        return 'waiting_courier';
      case 'satici_kuryesi':
        return 'seller_assignment_required';
      case 'gel_al':
        return 'not_required';
      default:
        return 'waiting_courier';
    }
  }

  static String _initialStatusForDeliveryMode(String deliveryMode) {
    switch (deliveryMode) {
      case 'gel_al':
        return 'pending';
      case 'satici_kuryesi':
        return 'pending';
      case 'platform_kurye':
        return 'ready';
      default:
        return 'pending';
    }
  }

  static double _hesaplaTeslimatUcreti({
    required String deliveryMode,
    required int urunSayisi,
    double estimatedDistanceKm = 0,
  }) {
    if (urunSayisi == 0) return 0;

    // Sofrasofra güncel finans standardı:
    // Gel-Al ve Götür fiyatları üreticinin nihai fiyatıdır.
    // Kurye/teslimat bedeli üretici ile kurye arasındaki operasyondur.
    // Platform sepette müşteriye ayrıca kurye ücreti bindirmez.
    return 0;
  }

  static String _normalizeSellerId(String raw) {
    return raw
        .toLowerCase()
        .replaceAll('ı', 'i')
        .replaceAll('ş', 's')
        .replaceAll('ğ', 'g')
        .replaceAll('ç', 'c')
        .replaceAll('ö', 'o')
        .replaceAll('ü', 'u')
        .replaceAll(' ', '_')
        .trim();
  }

  static List<String> _asStringList(dynamic value) {
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    return [];
  }

  static bool _asBool(dynamic value, {bool defaultValue = false}) {
    if (value == null) return defaultValue;
    if (value is bool) return value;
    if (value is String) {
      final lower = value.toLowerCase().trim();
      if (lower == 'true') return true;
      if (lower == 'false') return false;
    }
    return defaultValue;
  }

  static int _asInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static double _asDouble(dynamic value) {
    if (value == null) return 0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();
    if (value is String) {
      return double.tryParse(value.replaceAll(',', '.')) ?? 0;
    }
    return 0;
  }
}
