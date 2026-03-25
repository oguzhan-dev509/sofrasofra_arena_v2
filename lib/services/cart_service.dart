import 'package:cloud_firestore/cloud_firestore.dart';

class CartService {
  static Future<void> sepeteEkle({
    required String userId,
    required String urunId,
    required String urunAdi,
    required num fiyat,
    required String dukkanId,
    required String dukkanAdi,
    required String kategori,
    required String img,
  }) async {
    final docRef = FirebaseFirestore.instance
        .collection('sepet')
        .doc(userId)
        .collection('items')
        .doc(urunId);

    final doc = await docRef.get();

    if (doc.exists) {
      final mevcutAdet = (doc.data()?['adet'] ?? 0) as num;

      await docRef.update({
        'adet': mevcutAdet + 1,
        'addedAt': FieldValue.serverTimestamp(),
      });
    } else {
      await docRef.set({
        'urunId': urunId,
        'urunAdi': urunAdi,
        'fiyat': fiyat,
        'adet': 1,
        'dukkanId': dukkanId,
        'dukkanAdi': dukkanAdi,
        'kategori': kategori,
        'img': img,
        'addedAt': FieldValue.serverTimestamp(),
      });
    }
  }
}
