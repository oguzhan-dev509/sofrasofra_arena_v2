import 'package:cloud_firestore/cloud_firestore.dart';

class SepetService {
  static const String userId = 'demo_user';

  static CollectionReference<Map<String, dynamic>> get _itemsRef =>
      FirebaseFirestore.instance
          .collection('sepet')
          .doc(userId)
          .collection('items');

  static Future<void> sepeteEkle({
    required String urunId,
    required String urunAdi,
    required String dukkanAdi,
    required String kategori,
    required String img,
    required num fiyat,
  }) async {
    final docRef = _itemsRef.doc(urunId);

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final snap = await transaction.get(docRef);

      if (snap.exists) {
        final data = snap.data() ?? {};
        final int mevcutAdet =
            (data['adet'] is num) ? (data['adet'] as num).toInt() : 1;

        transaction.update(docRef, {
          'adet': mevcutAdet + 1,
          'addedAt': FieldValue.serverTimestamp(),
        });
      } else {
        transaction.set(docRef, {
          'urunId': urunId,
          'urunAdi': urunAdi,
          'dukkanAdi': dukkanAdi,
          'kategori': kategori,
          'img': img,
          'fiyat': fiyat,
          'adet': 1,
          'addedAt': FieldValue.serverTimestamp(),
        });
      }
    });
  }
}
