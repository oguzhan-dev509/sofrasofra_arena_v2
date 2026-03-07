import 'package:cloud_firestore/cloud_firestore.dart';

class OrderService {
  static Future<String> siparisOlustur({
    required String userId,
    required String musteriAdSoyad,
    required String adres,
    required String telefon,
    required String odemeYontemi,
  }) async {
    final firestore = FirebaseFirestore.instance;

    final sepetRef =
        firestore.collection('sepet').doc(userId).collection('items');

    final sepetSnapshot = await sepetRef.get();

    if (sepetSnapshot.docs.isEmpty) {
      throw Exception('Sepet boş');
    }

    final Map<String, List<Map<String, dynamic>>> groupedByDukkan = {};
    final Map<String, String> dukkanAdlari = {};

    double toplamTutar = 0;

    for (final doc in sepetSnapshot.docs) {
      final data = doc.data();

      final String dukkanId = (data['dukkanId'] ?? '').toString().trim();
      final String dukkanAdi = (data['dukkanAdi'] ?? '').toString().trim();

      if (dukkanId.isEmpty) {
        throw Exception('Sepette dukkanId eksik: ${doc.id}');
      }

      final num fiyatNum = (data['fiyat'] ?? 0) as num;
      final num adetNum = (data['adet'] ?? 1) as num;

      toplamTutar += fiyatNum.toDouble() * adetNum.toInt();

      groupedByDukkan.putIfAbsent(dukkanId, () => []);
      groupedByDukkan[dukkanId]!.add({
        'docId': doc.id,
        'urunId': (data['urunId'] ?? doc.id).toString(),
        'urunAdi': (data['urunAdi'] ?? '').toString(),
        'fiyat': fiyatNum,
        'adet': adetNum,
        'img': (data['img'] ?? '').toString(),
        'kategori': (data['kategori'] ?? '').toString(),
        'dukkanId': dukkanId,
        'dukkanAdi': dukkanAdi,
      });

      dukkanAdlari[dukkanId] = dukkanAdi;
    }

    final siparisRef = firestore.collection('siparisler').doc();

    await siparisRef.set({
      'kullaniciId': userId,
      'musteriAdSoyad': musteriAdSoyad,
      'telefon': telefon,
      'adres': adres,
      'toplamTutar': toplamTutar,
      'genelDurum': 'alindi',
      'saticiSayisi': groupedByDukkan.length,
      'odemeYontemi': odemeYontemi,
      'createdAt': FieldValue.serverTimestamp(),
    });

    for (final entry in groupedByDukkan.entries) {
      final String dukkanId = entry.key;
      final List<Map<String, dynamic>> items = entry.value;
      final String dukkanAdi = dukkanAdlari[dukkanId] ?? '';

      double altToplam = 0;
      for (final item in items) {
        final num fiyat = item['fiyat'] as num;
        final num adet = item['adet'] as num;
        altToplam += fiyat.toDouble() * adet.toInt();
      }

      final saticiSiparisRef =
          siparisRef.collection('saticiSiparisleri').doc(dukkanId);

      await saticiSiparisRef.set({
        'dukkanId': dukkanId,
        'dukkanAdi': dukkanAdi,
        'durum': 'alindi',
        'altToplam': altToplam,
        'kuryeId': '',
        'teslimatDurumu': 'atanmadi',
        'createdAt': FieldValue.serverTimestamp(),
      });

      for (final item in items) {
        final String urunId = item['urunId'].toString();

        await saticiSiparisRef.collection('items').doc(urunId).set({
          'urunId': item['urunId'],
          'urunAdi': item['urunAdi'],
          'fiyat': item['fiyat'],
          'adet': item['adet'],
          'img': item['img'],
          'kategori': item['kategori'],
          'dukkanId': item['dukkanId'],
          'dukkanAdi': item['dukkanAdi'],
        });
      }
    }

    for (final doc in sepetSnapshot.docs) {
      await doc.reference.delete();
    }

    return siparisRef.id;
  }
}
