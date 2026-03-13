import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';

class OtomatikKuryeAtamaServisi {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<bool> sipariseKuryeAta({
    required String orderId,
  }) async {
    final orderRef = _firestore.collection('orders').doc(orderId);

    // 1) Siparişi önce normal şekilde oku
    final orderSnap = await orderRef.get();

    if (!orderSnap.exists) {
      throw Exception('Sipariş bulunamadı.');
    }

    final orderData = orderSnap.data() as Map<String, dynamic>;

    final String assignmentStatus = _norm(orderData['assignmentStatus']);
    final String currentStatus = _norm(orderData['status']);

    if (assignmentStatus == 'assigned') {
      throw Exception('Bu sipariş zaten atanmış.');
    }

    if (assignmentStatus == 'completed' || currentStatus == 'delivered') {
      throw Exception('Bu sipariş zaten tamamlanmış.');
    }

    final String sehir = _norm(orderData['sehir']);
    final String ilce = _norm(orderData['ilce']);

    final double? orderLat = _toDouble(orderData['lat']);
    final double? orderLng = _toDouble(orderData['lng']);

    if (sehir.isEmpty || ilce.isEmpty) {
      throw Exception('Siparişte şehir / ilçe bilgisi eksik.');
    }

    if (orderLat == null || orderLng == null) {
      throw Exception('Sipariş konum bilgisi eksik.');
    }

    // 2) Uygun kuryeleri transaction dışında topla
    final couriersQuery = await _firestore
        .collection('couriers')
        .where('aktifMi', isEqualTo: true)
        .get();

    if (couriersQuery.docs.isEmpty) {
      return false;
    }

    QueryDocumentSnapshot<Map<String, dynamic>>? enUygunKurye;
    double? enKisaMesafeKm;

    for (final courierDoc in couriersQuery.docs) {
      final courier = courierDoc.data();

      final String courierSehir = _norm(courier['sehir']);
      final String courierIlce = _norm(courier['ilce']);
      final String uygunluk = _norm(courier['uygunluk']);

      if (courierSehir != sehir) continue;
      if (courierIlce != ilce) continue;

      if (uygunluk != 'musait' && uygunluk != 'müsait') continue;

      final double? courierLat = _toDouble(courier['lat']);
      final double? courierLng = _toDouble(courier['lng']);

      if (courierLat == null || courierLng == null) continue;

      final double mesafeKm = _mesafeHesaplaKm(
        orderLat,
        orderLng,
        courierLat,
        courierLng,
      );

      if (enKisaMesafeKm == null || mesafeKm < enKisaMesafeKm) {
        enKisaMesafeKm = mesafeKm;
        enUygunKurye = courierDoc;
      }
    }

    if (enUygunKurye == null) {
      return false;
    }

    final secilenKuryeData = enUygunKurye.data();
    final String courierId = enUygunKurye.id;
    final String courierName =
        (secilenKuryeData['adSoyad'] ?? 'Kurye').toString().trim();
    final String courierPhone =
        (secilenKuryeData['telefon'] ?? '').toString().trim();

    final courierRef = _firestore.collection('couriers').doc(courierId);

    // 3) Yazma işlemini transaction içinde güvenli yap
    return _firestore.runTransaction((transaction) async {
      final freshOrderSnap = await transaction.get(orderRef);
      final freshCourierSnap = await transaction.get(courierRef);

      if (!freshOrderSnap.exists) {
        throw Exception('Sipariş bulunamadı.');
      }

      if (!freshCourierSnap.exists) {
        throw Exception('Kurye bulunamadı.');
      }

      final freshOrderData = freshOrderSnap.data() as Map<String, dynamic>;
      final freshCourierData = freshCourierSnap.data() as Map<String, dynamic>;

      final String freshAssignmentStatus =
          _norm(freshOrderData['assignmentStatus']);
      final String freshStatus = _norm(freshOrderData['status']);

      if (freshAssignmentStatus == 'assigned') {
        throw Exception('Bu sipariş başka bir işlemde atanmış.');
      }

      if (freshAssignmentStatus == 'completed' || freshStatus == 'delivered') {
        throw Exception('Bu sipariş zaten tamamlanmış.');
      }

      final String freshUygunluk = _norm(freshCourierData['uygunluk']);
      if (freshUygunluk != 'musait' && freshUygunluk != 'müsait') {
        throw Exception('Seçilen kurye artık müsait değil.');
      }

      final int mevcutAktifSiparis = _toInt(freshCourierData['aktifSiparis']);

      transaction.update(orderRef, {
        'assignedCourierId': courierId,
        'assignedCourierName': courierName,
        'courierPhone': courierPhone,
        'assignmentAt': FieldValue.serverTimestamp(),
        'assignmentStatus': 'assigned',
        'courierAssignmentType': 'automatic',
        'status': 'on_the_way',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      transaction.update(courierRef, {
        'aktifSiparis': mevcutAktifSiparis + 1,
        'uygunluk': 'Görevde',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return true;
    });
  }

  static Future<int> atanmamisSiparisleriTaraVeAta() async {
    final query = await _firestore
        .collection('orders')
        .where('assignmentStatus', isEqualTo: 'unassigned')
        .get();

    int basariliAtamaSayisi = 0;

    for (final doc in query.docs) {
      try {
        final bool sonuc = await sipariseKuryeAta(orderId: doc.id);
        if (sonuc) {
          basariliAtamaSayisi++;
        }
      } catch (_) {
        // diğer siparişlere devam
      }
    }

    return basariliAtamaSayisi;
  }

  static String _norm(dynamic value) {
    if (value == null) return '';
    return value.toString().trim().toLowerCase();
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString());
  }

  static int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }

  static double _mesafeHesaplaKm(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double dunyaYaricapiKm = 6371.0;

    final double dLat = _dereceyiRadyanaCevir(lat2 - lat1);
    final double dLon = _dereceyiRadyanaCevir(lon2 - lon1);

    final double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_dereceyiRadyanaCevir(lat1)) *
            cos(_dereceyiRadyanaCevir(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return dunyaYaricapiKm * c;
  }

  static double _dereceyiRadyanaCevir(double derece) {
    return derece * pi / 180.0;
  }
}
