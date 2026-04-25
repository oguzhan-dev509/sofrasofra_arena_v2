import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

class KuryeKonumServisi {
  static StreamSubscription<Position>? _sub;
  static Timer? _testTimer;

  static Future<bool> izinleriHazirla() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint('Konum servisleri kapalı.');
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      debugPrint('Konum izni reddedildi.');
      return false;
    }

    if (permission == LocationPermission.deniedForever) {
      debugPrint('Konum izni kalıcı olarak reddedildi.');
      return false;
    }

    return true;
  }

  static Future<void> tekSeferGonder({
    required String courierId,
  }) async {
    final hazir = await izinleriHazirla();
    if (!hazir) {
      await testBaslat(courierId: courierId);
      return;
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );

      await FirebaseFirestore.instance
          .collection('couriers')
          .doc(courierId)
          .set({
        'lat': position.latitude,
        'lng': position.longitude,
        'updatedAt': FieldValue.serverTimestamp(),
        'konumKaynak': 'gps_manual',
      }, SetOptions(merge: true));

      debugPrint(
        'Tek seferlik kurye konumu yazıldı: ${position.latitude}, ${position.longitude}',
      );
    } catch (e) {
      debugPrint('tekSeferGonder hatası: $e');
      await testBaslat(courierId: courierId);
    }
  }

  static Future<void> baslat({
    required String courierId,
  }) async {
    await durdur();

    final hazir = await izinleriHazirla();
    if (!hazir) {
      await testBaslat(courierId: courierId);
      return;
    }

    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.best,
      distanceFilter: 10,
    );

    _sub = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(
      (Position position) async {
        try {
          await FirebaseFirestore.instance
              .collection('couriers')
              .doc(courierId)
              .set({
            'lat': position.latitude,
            'lng': position.longitude,
            'updatedAt': FieldValue.serverTimestamp(),
            'konumKaynak': 'gps',
          }, SetOptions(merge: true));

          debugPrint(
            'Kurye konumu yazıldı: ${position.latitude}, ${position.longitude}',
          );
        } catch (e) {
          debugPrint('Kurye konumu Firestore yazma hatası: $e');
        }
      },
      onError: (e) async {
        debugPrint('Konum stream hatası: $e');
        await testBaslat(courierId: courierId);
      },
    );
  }

  static Future<void> testBaslat({
    required String courierId,
  }) async {
    await durdur();

    double lat = 40.991;
    double lng = 29.028;

    _testTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
      lat += 0.00012;
      lng += 0.00008;

      try {
        await FirebaseFirestore.instance
            .collection('couriers')
            .doc(courierId)
            .set({
          'lat': lat,
          'lng': lng,
          'updatedAt': FieldValue.serverTimestamp(),
          'konumKaynak': 'test_stream',
        }, SetOptions(merge: true));

        debugPrint('TEST kurye konumu yazıldı: $lat, $lng');
      } catch (e) {
        debugPrint('TEST kurye konumu yazma hatası: $e');
      }
    });
  }

  static Future<void> durdur() async {
    await _sub?.cancel();
    _sub = null;

    _testTimer?.cancel();
    _testTimer = null;
  }
}
