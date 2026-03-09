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

    // Tek sepet = tek satıcı kuralı
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

    // Aynı ürünü tekilleştir
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
        'siparisTipi': 'teslimat',
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

  static Future<void> _sepetToplamlariniGuncelle() async {
    final sepetRef = _firestore.collection('sepetler').doc(_userId);
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

    const double teslimatUcreti = 25;
    final double genelToplam =
        urunSayisi == 0 ? 0 : (araToplam + teslimatUcreti);

    await sepetRef.set({
      'userId': _userId,
      'araToplam': araToplam,
      'teslimatUcreti': urunSayisi == 0 ? 0 : teslimatUcreti,
      'genelToplam': genelToplam,
      'urunSayisi': urunSayisi,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
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
