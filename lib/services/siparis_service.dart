import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SiparisService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<String> sepetiSipariseDonustur({
    required String musteriAd,
    required String odemeTipi,
    required Map<String, dynamic> adres,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Kullanıcı giriş yapmamış.');
    }

    final String uid = user.uid;

    final sepetRef = _firestore.collection('sepetler').doc(uid);
    final sepetItemsRef = sepetRef.collection('items');

    // 1) Sepeti oku
    final sepetSnap = await sepetRef.get();
    if (!sepetSnap.exists) {
      throw Exception('Sepet bulunamadı.');
    }

    final sepetData = sepetSnap.data();
    if (sepetData == null) {
      throw Exception('Sepet verisi boş.');
    }

    // 2) Sepet items'larını oku
    final itemsSnap = await sepetItemsRef.get();
    if (itemsSnap.docs.isEmpty) {
      throw Exception('Sepette ürün yok.');
    }

    final String dukkanId = (sepetData['dukkanId'] ?? '').toString();
    final String dukkanAd = (sepetData['dukkanAd'] ?? '').toString();
    final String saticiId = (sepetData['saticiId'] ?? '').toString();
    final String siparisTipi =
        (sepetData['siparisTipi'] ?? 'teslimat').toString();

    if (dukkanId.isEmpty || dukkanAd.isEmpty || saticiId.isEmpty) {
      throw Exception('Sepet temel bilgileri eksik.');
    }

    num araToplam = 0;
    int urunSayisi = 0;
    final List<Map<String, dynamic>> normalizedItems = [];

    for (final doc in itemsSnap.docs) {
      final data = doc.data();

      final String urunId = (data['urunId'] ?? '').toString();
      final String urunAd = (data['urunAd'] ?? '').toString();
      final String img = (data['img'] ?? '').toString();
      final int adet = _toInt(data['adet']);
      final num birimFiyat = _toNum(data['birimFiyat']);
      final num toplamFiyat = adet * birimFiyat;

      if (urunId.isEmpty || urunAd.isEmpty || adet <= 0 || birimFiyat <= 0) {
        throw Exception('Sepet item verisi bozuk: ${doc.id}');
      }

      normalizedItems.add({
        'urunId': urunId,
        'urunAd': urunAd,
        'img': img,
        'adet': adet,
        'birimFiyat': birimFiyat,
        'toplamFiyat': toplamFiyat,
      });

      araToplam += toplamFiyat;
      urunSayisi += 1;
    }

    final dukkanSnap =
        await _firestore.collection('dukkanlar').doc(dukkanId).get();
    if (!dukkanSnap.exists) {
      throw Exception('Dükkan bulunamadı.');
    }

    final dukkanData = dukkanSnap.data();
    if (dukkanData == null) {
      throw Exception('Dükkan verisi boş.');
    }

    final num teslimatUcreti = _toNum(dukkanData['teslimatUcreti']);
    final num minSiparisTutari = _toNum(dukkanData['minSiparisTutari']);

    if (araToplam < minSiparisTutari) {
      throw Exception(
        'Minimum sipariş tutarı sağlanmadı. Minimum: $minSiparisTutari / Sepet: $araToplam',
      );
    }

    final num genelToplam = araToplam + teslimatUcreti;

    // 3) Yeni sipariş dokümanı oluştur
    final String siparisId = _yeniSiparisId();
    final siparisRef = _firestore.collection('siparisler').doc(siparisId);

    final WriteBatch batch = _firestore.batch();

    batch.set(siparisRef, {
      'musteriId': uid,
      'saticiId': saticiId,
      'dukkanId': dukkanId,
      'dukkanAd': dukkanAd,
      'musteriAd': musteriAd,
      'siparisTipi': siparisTipi,
      'siparisDurumu': 'beklemede',
      'araToplam': araToplam,
      'teslimatUcreti': teslimatUcreti,
      'genelToplam': genelToplam,
      'urunSayisi': urunSayisi,
      'odemeTipi': odemeTipi,
      'adres': adres,
      'siparisZamani': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'sehir': (adres['sehir'] ?? '').toString(),
      'ilce': (adres['ilce'] ?? '').toString(),
    });

    // 4) Items'ları siparişe kopyala
    for (int i = 0; i < normalizedItems.length; i++) {
      final itemData = normalizedItems[i];
      final itemRef = siparisRef.collection('items').doc('item_${i + 1}');
      batch.set(itemRef, itemData);
    }

    // 5) Sepeti temizle
    for (final doc in itemsSnap.docs) {
      batch.delete(doc.reference);
    }

    batch.set(
        sepetRef,
        {
          'userId': uid,
          'dukkanId': '',
          'dukkanAd': '',
          'saticiId': '',
          'siparisTipi': 'teslimat',
          'araToplam': 0,
          'teslimatUcreti': 0,
          'genelToplam': 0,
          'urunSayisi': 0,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true));

    await batch.commit();
    return siparisId;
  }

  int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }

  num _toNum(dynamic value) {
    if (value is num) return value;
    return num.tryParse(value.toString()) ?? 0;
  }

  String _yeniSiparisId() {
    final now = DateTime.now();
    final y = now.year.toString().padLeft(4, '0');
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    final ms = now.microsecondsSinceEpoch.toString().substring(10);
    return 'sip_${y}${m}${d}_$ms';
  }
}
