import 'package:cloud_firestore/cloud_firestore.dart';

class ScoreService {
  static Timestamp? _asTimestamp(dynamic value) {
    if (value is Timestamp) return value;
    return null;
  }

  static double hesaplaUrunScore(Map<String, dynamic> data) {
    final int son7GunSiparis = (data['son7GunSiparis'] is num)
        ? (data['son7GunSiparis'] as num).toInt()
        : 0;

    final double puan =
        (data['puan'] is num) ? (data['puan'] as num).toDouble() : 0.0;

    final bool ilceOneCikan = data['ilceOneCikan'] == true;
    final bool sehirOneCikan = data['sehirOneCikan'] == true;
    final bool ulkeOneCikan = data['ulkeOneCikan'] == true;

    final Timestamp? ilceUntil = _asTimestamp(data['ilceOneCikanUntil']);
    final Timestamp? sehirUntil = _asTimestamp(data['sehirOneCikanUntil']);
    final Timestamp? ulkeUntil = _asTimestamp(data['ulkeOneCikanUntil']);
    final Timestamp? createdAt = _asTimestamp(data['createdAt']);

    final now = DateTime.now();

    int siparisPuani = son7GunSiparis * 10;
    double ratingPuani = puan * 15;
    int vitrinPuani = 0;
    int tazelikPuani = 0;

    final bool ilceAktif =
        ilceOneCikan && ilceUntil != null && now.isBefore(ilceUntil.toDate());

    final bool sehirAktif = sehirOneCikan &&
        sehirUntil != null &&
        now.isBefore(sehirUntil.toDate());

    final bool ulkeAktif =
        ulkeOneCikan && ulkeUntil != null && now.isBefore(ulkeUntil.toDate());

    if (ilceAktif) vitrinPuani += 20;
    if (sehirAktif) vitrinPuani += 50;
    if (ulkeAktif) vitrinPuani += 120;

    if (createdAt != null) {
      final int gunFarki = now.difference(createdAt.toDate()).inDays;

      if (gunFarki <= 3) {
        tazelikPuani = 40;
      } else if (gunFarki <= 7) {
        tazelikPuani = 20;
      }
    }

    return siparisPuani + ratingPuani + vitrinPuani + tazelikPuani;
  }

  static Future<void> urunScoreGuncelle(
    String docId,
    Map<String, dynamic> data,
  ) async {
    final double score = hesaplaUrunScore(data);

    await FirebaseFirestore.instance.collection('urunler').doc(docId).update({
      'score': score,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> tumUrunScorelariniGuncelle() async {
    final query = await FirebaseFirestore.instance.collection('urunler').get();
    final batch = FirebaseFirestore.instance.batch();

    for (final doc in query.docs) {
      final data = doc.data();
      final double score = hesaplaUrunScore(data);

      batch.update(doc.reference, {
        'score': score,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
  }
}
