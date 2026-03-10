import 'dart:math';

class KuryeMesafeSonucu {
  final String kuryeId;
  final String kuryeAdi;
  final double kuryeLat;
  final double kuryeLng;
  final double hedefLat;
  final double hedefLng;
  final double mesafeKm;

  const KuryeMesafeSonucu({
    required this.kuryeId,
    required this.kuryeAdi,
    required this.kuryeLat,
    required this.kuryeLng,
    required this.hedefLat,
    required this.hedefLng,
    required this.mesafeKm,
  });
}

class KuryeMesafeHesaplayici {
  /// 中文
  /// Haversine formülü ile iki koordinat arası km hesaplar
  ///
  /// Türkçe
  /// Haversine formülü ile iki koordinat arası km hesaplar
  static double ikiNoktaArasiKm({
    required double lat1,
    required double lng1,
    required double lat2,
    required double lng2,
  }) {
    const double dunyaYaricapiKm = 6371;

    final dLat = _dereceyiRadyanaCevir(lat2 - lat1);
    final dLng = _dereceyiRadyanaCevir(lng2 - lng1);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_dereceyiRadyanaCevir(lat1)) *
            cos(_dereceyiRadyanaCevir(lat2)) *
            sin(dLng / 2) *
            sin(dLng / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return dunyaYaricapiKm * c;
  }

  /// 中文
  /// Kurye ile hedef arasındaki mesafeyi hesaplar
  ///
  /// Türkçe
  /// Kurye ile hedef arasındaki mesafeyi hesaplar
  static KuryeMesafeSonucu kuryeIleHedefArasiMesafe({
    required String kuryeId,
    required String kuryeAdi,
    required double kuryeLat,
    required double kuryeLng,
    required double hedefLat,
    required double hedefLng,
  }) {
    final mesafe = ikiNoktaArasiKm(
      lat1: kuryeLat,
      lng1: kuryeLng,
      lat2: hedefLat,
      lng2: hedefLng,
    );

    return KuryeMesafeSonucu(
      kuryeId: kuryeId,
      kuryeAdi: kuryeAdi,
      kuryeLat: kuryeLat,
      kuryeLng: kuryeLng,
      hedefLat: hedefLat,
      hedefLng: hedefLng,
      mesafeKm: mesafe,
    );
  }

  /// 中文
  /// Kuryeleri hedef noktaya göre yakınlık sırasına dizer
  ///
  /// Türkçe
  /// Kuryeleri hedef noktaya göre yakınlık sırasına dizer
  static List<KuryeMesafeSonucu> enYakinKuryeleriSirala({
    required List<Map<String, dynamic>> kuryeler,
    required double hedefLat,
    required double hedefLng,
  }) {
    final List<KuryeMesafeSonucu> sonuc = [];

    for (final kurye in kuryeler) {
      final kuryeId = (kurye['id'] ?? '').toString().trim();
      final kuryeAdi =
          (kurye['ad'] ?? kurye['name'] ?? 'Kurye').toString().trim();

      final kuryeLat = _toDouble(kurye['lat']);
      final kuryeLng = _toDouble(kurye['lng']);

      if (kuryeLat == null || kuryeLng == null) {
        continue;
      }

      sonuc.add(
        kuryeIleHedefArasiMesafe(
          kuryeId: kuryeId,
          kuryeAdi: kuryeAdi,
          kuryeLat: kuryeLat,
          kuryeLng: kuryeLng,
          hedefLat: hedefLat,
          hedefLng: hedefLng,
        ),
      );
    }

    sonuc.sort((a, b) => a.mesafeKm.compareTo(b.mesafeKm));
    return sonuc;
  }

  /// 中文
  /// İlk N en yakın kuryeyi döndürür
  ///
  /// Türkçe
  /// İlk N en yakın kuryeyi döndürür
  static List<KuryeMesafeSonucu> ilkNEnYakinKurye({
    required List<Map<String, dynamic>> kuryeler,
    required double hedefLat,
    required double hedefLng,
    int limit = 3,
  }) {
    final sirali = enYakinKuryeleriSirala(
      kuryeler: kuryeler,
      hedefLat: hedefLat,
      hedefLng: hedefLng,
    );

    if (sirali.length <= limit) {
      return sirali;
    }

    return sirali.take(limit).toList();
  }

  static double _dereceyiRadyanaCevir(double derece) {
    return derece * pi / 180;
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString());
  }
}
