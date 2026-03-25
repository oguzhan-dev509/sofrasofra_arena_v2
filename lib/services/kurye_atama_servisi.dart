import 'package:cloud_firestore/cloud_firestore.dart';

class KuryeAtamaSonucu {
  final bool success;
  final String message;

  const KuryeAtamaSonucu({
    required this.success,
    required this.message,
  });
}

class KuryeAtamaServisi {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<KuryeAtamaSonucu> kuryeAta(String orderId) async {
    try {
      return await _db.runTransaction<KuryeAtamaSonucu>((transaction) async {
        final orderRef = _db.collection('orders').doc(orderId);
        final orderDoc = await transaction.get(orderRef);

        if (!orderDoc.exists) {
          return const KuryeAtamaSonucu(
            success: false,
            message: 'Sipariş bulunamadı.',
          );
        }

        final orderData = orderDoc.data();
        if (orderData == null) {
          return const KuryeAtamaSonucu(
            success: false,
            message: 'Sipariş verisi boş geldi.',
          );
        }

        final String currentStatus = (orderData['assignmentStatus'] ?? '')
            .toString()
            .trim()
            .toLowerCase();

        final String sehir =
            (orderData['sehir'] ?? '').toString().trim().toLowerCase();
        final String ilce =
            (orderData['ilce'] ?? '').toString().trim().toLowerCase();

        if (sehir.isEmpty || ilce.isEmpty) {
          return const KuryeAtamaSonucu(
            success: false,
            message: 'Siparişte şehir veya ilçe eksik.',
          );
        }

        // KRİTİK KORUMA:
        // Sipariş zaten atanmışsa ikinci kez atama yapma.
        if (currentStatus == 'assigned' ||
            orderData['assignedCourierId'] != null) {
          final mevcutKurye =
              (orderData['assignedCourierName'] ?? 'Kurye').toString();
          return KuryeAtamaSonucu(
            success: false,
            message: 'Bu sipariş zaten atanmış: $mevcutKurye',
          );
        }

        final couriersSnapshot = await _db.collection('couriers').get();

        QueryDocumentSnapshot<Map<String, dynamic>>? secilenKurye;

        for (final doc in couriersSnapshot.docs) {
          final data = doc.data();

          final bool aktifMi =
              (data['aktifMi'] == true) || (data['isActive'] == true);

          final String uygunlukRaw =
              (data['uygunluk'] ?? data['uygunlukDurumu'] ?? '')
                  .toString()
                  .trim()
                  .toLowerCase();

          final String kuryeSehir =
              (data['sehir'] ?? '').toString().trim().toLowerCase();
          final String kuryeIlce =
              (data['ilce'] ?? '').toString().trim().toLowerCase();

          final bool musaitMi =
              uygunlukRaw == 'müsait' || uygunlukRaw == 'musait';

          if (aktifMi && musaitMi && kuryeSehir == sehir && kuryeIlce == ilce) {
            secilenKurye = doc;
            break;
          }
        }

        if (secilenKurye == null) {
          return const KuryeAtamaSonucu(
            success: false,
            message: 'Uygun kurye bulunamadı.',
          );
        }

        final kuryeRef = _db.collection('couriers').doc(secilenKurye.id);
        final kuryeDoc = await transaction.get(kuryeRef);
        final courierData = kuryeDoc.data();

        if (courierData == null) {
          return const KuryeAtamaSonucu(
            success: false,
            message: 'Kurye verisi okunamadı.',
          );
        }

        final String courierName =
            (courierData['adSoyad'] ?? courierData['ad'] ?? 'Kurye')
                .toString()
                .trim();

        final String uygunlukKontrol =
            (courierData['uygunluk'] ?? courierData['uygunlukDurumu'] ?? '')
                .toString()
                .trim()
                .toLowerCase();

        final bool halaMusait =
            uygunlukKontrol == 'müsait' || uygunlukKontrol == 'musait';

        if (!halaMusait) {
          return const KuryeAtamaSonucu(
            success: false,
            message: 'Kurye artık müsait değil.',
          );
        }

        final int aktifSiparis =
            ((courierData['aktifSiparis'] ?? 0) as num).toInt();

        transaction.update(orderRef, {
          'assignedCourierId': secilenKurye.id,
          'assignedCourierName': courierName,
          'assignmentStatus': 'assigned',
          'assignmentAt': FieldValue.serverTimestamp(),
        });

        transaction.update(kuryeRef, {
          'uygunluk': 'Görevde',
          'aktifSiparis': aktifSiparis + 1,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        return KuryeAtamaSonucu(
          success: true,
          message: 'Kurye atandı: $courierName',
        );
      });
    } catch (e) {
      return KuryeAtamaSonucu(
        success: false,
        message: 'Kurye atama hatası: $e',
      );
    }
  }
}
