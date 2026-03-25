import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class KuryeSimulator {
  static Timer? _timer;
  static bool _aktif = false;

  static Future<void> baslat(String courierId) async {
    if (_aktif) {
      debugPrint('SIMULATOR zaten aktif, yeniden başlatılıyor...');
      durdur();
    }

    double lat = 41.0;
    double lng = 29.05;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('couriers')
          .doc(courierId)
          .get();

      final data = doc.data();
      if (data != null) {
        final dynamic rawLat = data['lat'];
        final dynamic rawLng = data['lng'];

        if (rawLat is num) lat = rawLat.toDouble();
        if (rawLng is num) lng = rawLng.toDouble();
      }
    } catch (e) {
      debugPrint('SIM INIT READ ERROR: $e');
    }

    debugPrint('SIMULATOR BASLADI courierId=$courierId lat=$lat lng=$lng');

    _aktif = true;

    _timer = Timer.periodic(const Duration(seconds: 2), (_) async {
      lat += 0.0005;
      lng += 0.0005;

      debugPrint('SIM UPDATE lat=$lat lng=$lng');

      try {
        await FirebaseFirestore.instance
            .collection('couriers')
            .doc(courierId)
            .update({
          'lat': lat,
          'lng': lng,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        debugPrint('SIM ERROR: $e');
      }
    });
  }

  static void durdur() {
    _timer?.cancel();
    _timer = null;
    _aktif = false;
    debugPrint('SIMULATOR DURDU');
  }

  static bool get aktifMi => _aktif;
}
