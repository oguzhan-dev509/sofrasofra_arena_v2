import 'package:cloud_firestore/cloud_firestore.dart';

class SepetService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Geçici olarak tek kullanıcı mantığıyla ilerliyoruz.
  /// Sonra gerçek auth bağlanınca bunu user.uid yapacağız.
  static const String demoUserId = 'demo-user';

  CollectionReference<Map<String, dynamic>> _sepetRef(String userId) {
    return _firestore.collection('sepet').doc(userId).collection('items');
  }

  Future<void> sepeteEkle({
    required String urunId,
    required String urunAdi,
    required String img,
    required String dukkan,
    required String konum,
    required int adet,
    required dynamic fiyat,
  }) async {
    final ref = _sepetRef(demoUserId).doc(urunId);

    final mevcut = await ref.get();

    int mevcutAdet = 0;

    if (mevcut.exists) {
      final data = mevcut.data();
      mevcutAdet = (data?['adet'] ?? 0) is int
          ? (data?['adet'] ?? 0) as int
          : int.tryParse((data?['adet'] ?? '0').toString()) ?? 0;
    }

    final num parsedFiyat =
        fiyat is num ? fiyat : num.tryParse(fiyat.toString()) ?? 0;

    await ref.set({
      'urunId': urunId,
      'urunAdi': urunAdi,
      'img': img,
      'dukkan': dukkan,
      'konum': konum,
      'adet': mevcutAdet + adet,
      'fiyat': parsedFiyat,
      'eklenmeTarihi': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> sepetAkisi() {
    return _sepetRef(demoUserId)
        .orderBy('eklenmeTarihi', descending: true)
        .snapshots();
  }

  Future<void> adetGuncelle({
    required String urunId,
    required int yeniAdet,
  }) async {
    final ref = _sepetRef(demoUserId).doc(urunId);

    if (yeniAdet <= 0) {
      await ref.delete();
      return;
    }

    await ref.update({'adet': yeniAdet});
  }

  Future<void> urunSil(String urunId) async {
    await _sepetRef(demoUserId).doc(urunId).delete();
  }

  Future<void> sepetiTemizle() async {
    final items = await _sepetRef(demoUserId).get();

    for (final doc in items.docs) {
      await doc.reference.delete();
    }
  }
}
