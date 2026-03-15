import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class OtomatikKuryeAtamaServisi {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<Map<String, dynamic>?> enUygunKuryeyiBul({
    required String sehir,
    required String ilce,
  }) async {
    try {
      String normalize(String value) {
        return value
            .trim()
            .toLowerCase()
            .replaceAll('ı', 'i')
            .replaceAll('İ', 'i');
      }

      final normSehir = normalize(sehir);
      final normIlce = normalize(ilce);

      final courierQuery = await _firestore
          .collection('couriers')
          .where('aktifMi', isEqualTo: true)
          .where('sehir', isEqualTo: normSehir)
          .where('ilce', isEqualTo: normIlce)
          .get();

      if (courierQuery.docs.isEmpty) {
        debugPrint('Uygun kurye bulunamadı: şehir/ilçe eşleşmesi yok.');
        return null;
      }

      final uygunBelgeler = courierQuery.docs.where((doc) {
        final data = doc.data();

        final uygunluk =
            (data['uygunluk'] ?? '').toString().toLowerCase().trim();
        final aktifSiparis = _toInt(data['aktifSiparis']);
        final maxAktifSiparis =
            _toInt(data['maxAktifSiparis'], defaultValue: 3);

        final uygunMu = uygunluk == 'görevde' ||
            uygunluk == 'musait' ||
            uygunluk == 'müsait' ||
            uygunluk == 'available';

        return uygunMu && aktifSiparis < maxAktifSiparis;
      }).toList();

      if (uygunBelgeler.isEmpty) {
        debugPrint('Kurye var ama kapasite/uygunluk nedeniyle atanamadı.');
        return null;
      }

      uygunBelgeler.sort((a, b) {
        final aData = a.data();
        final bData = b.data();

        final aAktifSiparis = _toInt(aData['aktifSiparis']);
        final bAktifSiparis = _toInt(bData['aktifSiparis']);

        if (aAktifSiparis != bAktifSiparis) {
          return aAktifSiparis.compareTo(bAktifSiparis);
        }

        final aRating = _toDouble(aData['rating']);
        final bRating = _toDouble(bData['rating']);

        return bRating.compareTo(aRating);
      });

      final secilen = uygunBelgeler.first;
      final data = secilen.data();

      return {
        'courierId': secilen.id,
        'adSoyad': (data['adSoyad'] ?? 'Kurye').toString(),
        'telefon': (data['telefon'] ?? '').toString(),
        'aktifSiparis': _toInt(data['aktifSiparis']),
        'rating': _toDouble(data['rating']),
      };
    } catch (e) {
      debugPrint('enUygunKuryeyiBul hata: $e');
      return null;
    }
  }

  Future<bool> sipariseOtomatikKuryeAta({
    required String orderId,
    required String sehir,
    required String ilce,
  }) async {
    try {
      final uygunKurye = await enUygunKuryeyiBul(
        sehir: sehir,
        ilce: ilce,
      );

      if (uygunKurye == null) {
        await _firestore.collection('orders').doc(orderId).set({
          'assignmentStatus': 'unassigned',
          'courierAssignmentType': 'automatic',
          'assignmentUpdatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        debugPrint('Siparişe otomatik kurye atanamadı: $orderId');
        return false;
      }

      final courierId = uygunKurye['courierId'].toString();
      final courierName = uygunKurye['adSoyad'].toString();

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
              'assignmentAt': FieldValue.serverTimestamp(),
              'courierAssignmentType': 'automatic',
            },
            SetOptions(merge: true));

        transaction.set(
            courierRef,
            {
              'aktifSiparis': mevcutAktifSiparis + 1,
              'updatedAt': FieldValue.serverTimestamp(),
            },
            SetOptions(merge: true));
      });

      debugPrint(
          'Kurye otomatik atandı. orderId=$orderId courierId=$courierId');
      return true;
    } catch (e) {
      debugPrint('sipariseOtomatikKuryeAta hata: $e');

      await _firestore.collection('orders').doc(orderId).set({
        'assignmentStatus': 'unassigned',
        'courierAssignmentType': 'automatic',
        'assignmentUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      return false;
    }
  }

  // ESKİ DOSYALARLA UYUMLU STATIC WRAPPER
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

      // Eski şema desteği: meta.adres.sehir / ilce
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

      // Alternatif adres map desteği
      if (sehir.isEmpty || ilce.isEmpty) {
        final adres = orderData['adres'];
        if (adres is Map<String, dynamic>) {
          sehir = normalize(adres['sehir']);
          ilce = normalize(adres['ilce']);
        }
      }

      debugPrint(
        'sipariseKuryeAta orderId=$orderId sehir=$sehir ilce=$ilce',
      );

      if (sehir.isEmpty || ilce.isEmpty) {
        debugPrint(
            'sipariseKuryeAta: sehir / ilce bulunamadi. orderId=$orderId');

        await firestore.collection('orders').doc(orderId).set({
          'assignmentStatus': 'unassigned',
          'courierAssignmentType': 'automatic',
          'assignmentUpdatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        return false;
      }

      final servis = OtomatikKuryeAtamaServisi();
      return await servis.sipariseOtomatikKuryeAta(
        orderId: orderId,
        sehir: sehir,
        ilce: ilce,
      );
    } catch (e) {
      debugPrint('sipariseKuryeAta static hata: $e');
      return false;
    }
  }

  static int _toInt(dynamic value, {int defaultValue = 0}) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is double) return value.toInt();
    return int.tryParse(value.toString()) ?? defaultValue;
  }

  static double _toDouble(dynamic value, {double defaultValue = 0}) {
    if (value == null) return defaultValue;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString()) ?? defaultValue;
  }
}
