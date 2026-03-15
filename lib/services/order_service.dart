import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'otomatik_kurye_atama_servisi.dart';

class OrderItemInput {
  final String urunId;
  final String urunAdi;
  final String saticiId;
  final int adet;
  final double fiyat;
  final String? gorselUrl;
  final String? kategori;
  final Map<String, dynamic>? extra;

  const OrderItemInput({
    required this.urunId,
    required this.urunAdi,
    required this.saticiId,
    required this.adet,
    required this.fiyat,
    this.gorselUrl,
    this.kategori,
    this.extra,
  });

  double get toplam => _roundMoneyStatic(fiyat * adet);

  Map<String, dynamic> toMap() {
    return {
      'urunId': urunId,
      'urunAdi': urunAdi,
      'saticiId': saticiId,
      'adet': adet,
      'fiyat': fiyat,
      'toplam': toplam,
      'gorselUrl': gorselUrl,
      'kategori': kategori,
      'extra': extra ?? {},
    };
  }

  static double _roundMoneyStatic(double value) {
    return double.parse(value.toStringAsFixed(2));
  }
}

class OrderCreateInput {
  final String kullaniciId;
  final String kullaniciAdi;
  final String? kullaniciTelefon;
  final String sehir;
  final String ilce;
  final double? lat;
  final double? lng;
  final String? adres;
  final String? not;
  final List<OrderItemInput> items;

  const OrderCreateInput({
    required this.kullaniciId,
    required this.kullaniciAdi,
    this.kullaniciTelefon,
    required this.sehir,
    required this.ilce,
    this.lat,
    this.lng,
    this.adres,
    this.not,
    required this.items,
  });
}

class OrderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final OtomatikKuryeAtamaServisi _otomatikKuryeAtamaServisi =
      OtomatikKuryeAtamaServisi();

  Future<String> siparisOlustur(OrderCreateInput input) async {
    try {
      if (input.items.isEmpty) {
        throw Exception('Sipariş kalemi boş olamaz.');
      }

      final itemMaps = input.items.map((e) => e.toMap()).toList();
      final toplamTutar = _roundMoney(
        input.items.fold<double>(0, (sum, item) => sum + item.toplam),
      );

      final docRef = _firestore.collection('orders').doc();

      final siparisData = <String, dynamic>{
        'orderId': docRef.id,
        'kullaniciId': input.kullaniciId,
        'kullaniciAdi': input.kullaniciAdi,
        'kullaniciTelefon': input.kullaniciTelefon ?? '',
        'adres': input.adres ?? '',
        'not': input.not ?? '',
        'sehir': input.sehir.toLowerCase().trim(),
        'ilce': input.ilce.toLowerCase().trim(),
        'lat': input.lat,
        'lng': input.lng,
        'items': itemMaps,
        'toplamTutar': toplamTutar,
        'status': 'pending',
        'assignmentStatus': 'searching',
        'courierAssignmentType': 'automatic',
        'assignedCourierId': null,
        'assignedCourierName': null,
        'assignmentAt': null,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await docRef.set(siparisData);

      final atamaBasarili =
          await _otomatikKuryeAtamaServisi.sipariseOtomatikKuryeAta(
        orderId: docRef.id,
        sehir: input.sehir,
        ilce: input.ilce,
      );

      if (!atamaBasarili) {
        debugPrint('Sipariş oluşturuldu ama otomatik kurye atanamadı.');
      }

      return docRef.id;
    } catch (e) {
      debugPrint('siparisOlustur hata: $e');
      rethrow;
    }
  }

  Future<void> siparisDurumGuncelle({
    required String orderId,
    required String yeniDurum,
  }) async {
    try {
      final orderRef = _firestore.collection('orders').doc(orderId);
      final orderSnap = await orderRef.get();

      if (!orderSnap.exists) {
        throw Exception('Sipariş bulunamadı.');
      }

      final orderData = orderSnap.data() as Map<String, dynamic>;
      final eskiDurum = (orderData['status'] ?? '').toString();
      final assignedCourierId =
          (orderData['assignedCourierId'] ?? '').toString().trim();

      await orderRef.set({
        'status': yeniDurum,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      final teslimEdildiMi = yeniDurum == 'delivered';
      final dahaOnceTeslimDegilMi = eskiDurum != 'delivered';

      if (teslimEdildiMi &&
          dahaOnceTeslimDegilMi &&
          assignedCourierId.isNotEmpty) {
        final courierRef =
            _firestore.collection('couriers').doc(assignedCourierId);

        await _firestore.runTransaction((transaction) async {
          final courierSnap = await transaction.get(courierRef);

          if (!courierSnap.exists) return;

          final courierData = courierSnap.data() as Map<String, dynamic>;
          final aktifSiparis = _toInt(courierData['aktifSiparis']);
          final toplamTeslimat = _toInt(courierData['toplamTeslimat']);

          transaction.set(
              courierRef,
              {
                'aktifSiparis': aktifSiparis > 0 ? aktifSiparis - 1 : 0,
                'toplamTeslimat': toplamTeslimat + 1,
                'updatedAt': FieldValue.serverTimestamp(),
              },
              SetOptions(merge: true));
        });
      }
    } catch (e) {
      debugPrint('siparisDurumGuncelle hata: $e');
      rethrow;
    }
  }

  Future<void> siparisiManuelKuryeyeAta({
    required String orderId,
    required String courierId,
    required String courierName,
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

        final orderData = orderSnap.data() as Map<String, dynamic>;
        final eskiCourierId =
            (orderData['assignedCourierId'] ?? '').toString().trim();
        final zatenAssigned =
            (orderData['assignmentStatus'] ?? '').toString() == 'assigned';

        if (zatenAssigned && eskiCourierId == courierId) {
          return;
        }

        final courierData = courierSnap.data() as Map<String, dynamic>;
        final aktifSiparis = _toInt(courierData['aktifSiparis']);

        transaction.set(
            orderRef,
            {
              'assignedCourierId': courierId,
              'assignedCourierName': courierName,
              'assignmentStatus': 'assigned',
              'assignmentAt': FieldValue.serverTimestamp(),
              'courierAssignmentType': 'manual',
              'updatedAt': FieldValue.serverTimestamp(),
            },
            SetOptions(merge: true));

        transaction.set(
            courierRef,
            {
              'aktifSiparis': aktifSiparis + 1,
              'updatedAt': FieldValue.serverTimestamp(),
            },
            SetOptions(merge: true));
      });
    } catch (e) {
      debugPrint('siparisiManuelKuryeyeAta hata: $e');
      rethrow;
    }
  }

  double _roundMoney(double value) {
    return double.parse(value.toStringAsFixed(2));
  }

  static int _toInt(dynamic value, {int defaultValue = 0}) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is double) return value.toInt();
    return int.tryParse(value.toString()) ?? defaultValue;
  }
}
