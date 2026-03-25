import 'package:cloud_firestore/cloud_firestore.dart';
import 'otomatik_kurye_atama_servisi.dart';

class KuryeYanitServisi {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<void> kabulEt({
    required String orderId,
    required String courierId,
  }) async {
    final orderRef = _firestore.collection('orders').doc(orderId);
    final courierRef = _firestore.collection('couriers').doc(courierId);

    await _firestore.runTransaction((tx) async {
      final orderSnap = await tx.get(orderRef);
      final courierSnap = await tx.get(courierRef);

      if (!orderSnap.exists) {
        throw Exception('Sipariş bulunamadı.');
      }
      if (!courierSnap.exists) {
        throw Exception('Kurye bulunamadı.');
      }

      final orderData = orderSnap.data() as Map<String, dynamic>;

      final String assignedCourierId =
          (orderData['assignedCourierId'] ?? '').toString().trim();

      final String offerStatus = (orderData['courierOfferStatus'] ?? '')
          .toString()
          .trim()
          .toLowerCase();

      if (assignedCourierId != courierId) {
        throw Exception('Bu sipariş bu kuryeye ait değil.');
      }

      if (offerStatus == 'accepted') {
        return;
      }

      tx.update(orderRef, {
        'status': 'on_the_way',
        'durum': 'on_the_way',
        'assignmentStatus': 'assigned',
        'courierOfferStatus': 'accepted',
        'courierRespondedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      tx.update(courierRef, {
        'uygunluk': 'Görevde',
        'uygunlukDurumu': 'gorevde',
        'availability': 'gorevde',
        'lastAcceptedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  static Future<void> reddet({
    required String orderId,
    required String courierId,
    String? reason,
  }) async {
    final orderRef = _firestore.collection('orders').doc(orderId);
    final courierRef = _firestore.collection('couriers').doc(courierId);

    await _firestore.runTransaction((tx) async {
      final orderSnap = await tx.get(orderRef);
      final courierSnap = await tx.get(courierRef);

      if (!orderSnap.exists) {
        throw Exception('Sipariş bulunamadı.');
      }
      if (!courierSnap.exists) {
        throw Exception('Kurye bulunamadı.');
      }

      final orderData = orderSnap.data() as Map<String, dynamic>;
      final courierData = courierSnap.data() as Map<String, dynamic>;

      final String assignedCourierId =
          (orderData['assignedCourierId'] ?? '').toString().trim();

      if (assignedCourierId != courierId) {
        throw Exception('Bu sipariş bu kuryeye ait değil.');
      }

      final int aktifSiparis = _toInt(courierData['aktifSiparis']);
      final int yeniAktifSiparis = aktifSiparis > 0 ? aktifSiparis - 1 : 0;

      tx.update(orderRef, {
        'status': 'ready',
        'durum': 'ready',
        'assignmentStatus': 'rejected',
        'courierOfferStatus': 'rejected',
        'courierRespondedAt': FieldValue.serverTimestamp(),
        'courierRejectReason': (reason ?? 'Kurye reddetti').trim(),
        'assignedCourierId': null,
        'assignedCourierName': null,
        'updatedAt': FieldValue.serverTimestamp(),
        'lastTriedCourierIds': FieldValue.arrayUnion([courierId]),
        'triedCourierIds': FieldValue.arrayUnion([courierId]),
      });

      tx.update(courierRef, {
        'aktifSiparis': yeniAktifSiparis,
        'currentOrderId': null,
        'uygunluk': yeniAktifSiparis == 0 ? 'Müsait' : 'Görevde',
        'uygunlukDurumu': yeniAktifSiparis == 0 ? 'musait' : 'gorevde',
        'availability': yeniAktifSiparis == 0 ? 'musait' : 'gorevde',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });

    await _retryAtama(orderId: orderId);
  }

  static Future<void> _retryAtama({
    required String orderId,
  }) async {
    final orderRef = _firestore.collection('orders').doc(orderId);

    final orderSnap = await orderRef.get();
    if (!orderSnap.exists) return;

    final data = orderSnap.data() as Map<String, dynamic>;

    final int retryCount = _toInt(data['retryCount']);
    final int maxRetryCount = _toInt(
      data['maxRetryCount'],
      defaultValue: 3,
    );

    if (retryCount >= maxRetryCount) {
      await orderRef.update({
        'assignmentStatus': 'failed',
        'retryStatus': 'exhausted',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return;
    }

    await orderRef.update({
      'retryCount': retryCount + 1,
      'retryStatus': 'retrying',
      'lastRetryAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await OtomatikKuryeAtamaServisi.sipariseKuryeAta(
      orderId: orderId,
    );
  }

  static int _toInt(dynamic value, {int defaultValue = 0}) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? defaultValue;
  }
}
