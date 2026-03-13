import 'package:cloud_firestore/cloud_firestore.dart';

class SepetService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const String _userId = 'demo_user';

  static Future<void> sepeteEkle({
    required String urunId,
    required String urunAdi,
    required String dukkanAdi,
    required String kategori,
    required String img,
    required double fiyat,
    String? saticiId,
    String? dukkanId,
  }) async {
    final sepetRef = _firestore.collection('sepetler').doc(_userId);
    final itemsRef = sepetRef.collection('items');

    final String finalSaticiId = _normalizeSellerId(
      saticiId ?? dukkanId ?? dukkanAdi,
    );

    final sellerSnap =
        await _firestore.collection('sellers').doc(finalSaticiId).get();

    final sellerData = sellerSnap.data() ?? {};

    final String sellerType =
        (sellerData['sellerType'] ?? 'ev_lezzetleri').toString();

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
        'userId': _userId,
        'dukkanId': finalSaticiId,
        'dukkanAd': dukkanAdi,
        'saticiId': finalSaticiId,
        'sellerType': sellerType,
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
      final data = doc.data();
      final mevcutAdet = _asInt(data['adet']);

      batch.update(doc.reference, {
        'urunAdi': urunAdi,
        'dukkanAdi': dukkanAdi,
        'dukkan': dukkanAdi,
        'kategori': kategori,
        'img': img,
        'fiyat': fiyat,
        'birimFiyat': fiyat,
        'adet': mevcutAdet + 1,
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
        'fiyat': fiyat,
        'birimFiyat': fiyat,
        'adet': 1,
        'saticiId': finalSaticiId,
        'addedAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
    await _sepetToplamlariniGuncelle();
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
  }) async {
    final sepetRef = _firestore.collection('sepetler').doc(_userId);
    final sepetSnap = await sepetRef.get();

    if (!sepetSnap.exists) {
      throw Exception('Sepet bulunamadı.');
    }

    final sepetData = sepetSnap.data() ?? {};
    final itemsSnap = await sepetRef.collection('items').get();

    if (itemsSnap.docs.isEmpty) {
      throw Exception('Sepet boş. Önce ürün ekleyin.');
    }

    final String saticiId = (sepetData['saticiId'] ?? '').toString().trim();
    final String dukkanAdi = (sepetData['dukkanAd'] ?? '').toString().trim();
    final String sellerType =
        (sepetData['sellerType'] ?? 'ev_lezzetleri').toString();
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

    final String assignmentStatus = _assignmentStatusForDeliveryMode(
      deliveryMode,
    );

    final String initialStatus = _initialStatusForDeliveryMode(
      deliveryMode,
    );

    final orderRef = _firestore.collection('orders').doc();
    final sellerOrderRef = _firestore.collection('sellerOrders').doc();
    final timelineRef = _firestore.collection('orderTimeline').doc();

    final String siparisNo = orderRef.id;

    final batch = _firestore.batch();

    batch.set(orderRef, {
      'siparisNo': siparisNo,
      'userId': _userId,
      'musteriAd': musteriAd,
      'musteriTelefon': musteriTelefon,
      'teslimatAdresi': teslimatAdresi,
      'adres': teslimatAdresi,
      'sehir': sehir.toLowerCase().trim(),
      'ilce': ilce.toLowerCase().trim(),
      'not': (not ?? '').trim(),
      'saticiId': saticiId,
      'saticiAd': dukkanAdi,
      'dukkanId': saticiId,
      'dukkanAdi': dukkanAdi,
      'sellerType': sellerType,
      'teslimatModlari': teslimatModlari,
      'deliveryMode': deliveryMode,
      'siparisTipi': siparisTipi,
      'platformKuryeAktif': platformKuryeAktif,
      'saticiKuryeAktif': saticiKuryeAktif,
      'gelAlAktif': gelAlAktif,
      'assignmentStatus': assignmentStatus,
      'assignedCourierId': null,
      'assignedCourierName': null,
      'sellerCourierId': null,
      'sellerCourierName': null,
      'status': initialStatus,
      'durum': initialStatus,
      'araToplam': araToplam,
      'teslimatUcreti': teslimatUcreti,
      'genelToplam': genelToplam,
      'urunSayisi': urunSayisi,
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
      'userId': _userId,
      'saticiId': saticiId,
      'saticiAd': dukkanAdi,
      'status': initialStatus,
      'durum': initialStatus,
      'deliveryMode': deliveryMode,
      'assignmentStatus': assignmentStatus,
      'araToplam': araToplam,
      'teslimatUcreti': teslimatUcreti,
      'genelToplam': genelToplam,
      'urunSayisi': urunSayisi,
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
        'addedAt': item['addedAt'],
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    batch.set(timelineRef, {
      'orderId': orderRef.id,
      'siparisNo': siparisNo,
      'status': initialStatus,
      'actorType': 'system',
      'actorId': _userId,
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
        'teslimatModlari': [],
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

    return orderRef.id;
  }

  static Future<void> _sepetToplamlariniGuncelle() async {
    final sepetRef = _firestore.collection('sepetler').doc(_userId);
    final sepetSnap = await sepetRef.get();
    final sepetData = sepetSnap.data() ?? {};

    final itemsSnap = await sepetRef.collection('items').get();

    double araToplam = 0;
    int urunSayisi = 0;

    for (final doc in itemsSnap.docs) {
      final data = doc.data();
      final fiyat = _asDouble(
        data['fiyat'] ?? data['birimFiyat'] ?? data['unitPrice'] ?? 0,
      );
      final adet = _asInt(data['adet'] ?? data['quantity'] ?? 1);

      araToplam += fiyat * adet;
      urunSayisi += 1;
    }

    final String deliveryMode =
        (sepetData['deliveryMode'] ?? 'platform_kurye').toString();

    final double teslimatUcreti = _hesaplaTeslimatUcreti(
      deliveryMode: deliveryMode,
      urunSayisi: urunSayisi,
    );

    final double genelToplam =
        urunSayisi == 0 ? 0 : (araToplam + teslimatUcreti);

    await sepetRef.set({
      'userId': _userId,
      'araToplam': araToplam,
      'teslimatUcreti': teslimatUcreti,
      'genelToplam': genelToplam,
      'urunSayisi': urunSayisi,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static String _assignmentStatusForDeliveryMode(String deliveryMode) {
    switch (deliveryMode) {
      case 'platform_kurye':
        return 'unassigned';
      case 'satici_kuryesi':
        return 'seller_assignment_required';
      case 'gel_al':
        return 'not_required';
      default:
        return 'unassigned';
    }
  }

  static String _initialStatusForDeliveryMode(String deliveryMode) {
    switch (deliveryMode) {
      case 'gel_al':
        return 'pending';
      case 'satici_kuryesi':
        return 'pending';
      case 'platform_kurye':
        return 'pending';
      default:
        return 'pending';
    }
  }

  static double _hesaplaTeslimatUcreti({
    required String deliveryMode,
    required int urunSayisi,
  }) {
    if (urunSayisi == 0) return 0;

    if (deliveryMode == 'gel_al') {
      return 0;
    }

    return 25;
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
