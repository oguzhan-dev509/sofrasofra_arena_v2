import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

class KuryeKonumServisi {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static StreamSubscription<Position>? _subscription;

  static Future<void> _konumIzinleriniKontrolEt() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Konum servisi kapalı.');
    }

    var permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw Exception('Konum izni reddedildi.');
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Konum izni kalıcı olarak reddedildi.');
    }
  }

  static bool _istanbulIcindeMi(double lat, double lng) {
    return lat >= 40.7 && lat <= 41.3 && lng >= 28.4 && lng <= 29.8;
  }

  static Future<void> tekSeferlikKonumGuncelle({
    required String kuryeId,
  }) async {
    await _konumIzinleriniKontrolEt();

    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    if (!_istanbulIcindeMi(position.latitude, position.longitude)) {
      throw Exception(
        'Geçersiz konum algılandı. İstanbul dışı koordinat Firestore’a yazılmadı.',
      );
    }

    await _firestore.collection('couriers').doc(kuryeId).update({
      'lat': position.latitude,
      'lng': position.longitude,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> canliTakibiBaslat({
    required String kuryeId,
  }) async {
    // WEB testte otomatik canlı takip kapalı.
    // Çünkü Chrome yanlış konum verip kurye koordinatını bozabiliyor.
    if (kIsWeb) {
      return;
    }

    await _konumIzinleriniKontrolEt();

    await _subscription?.cancel();

    _subscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((position) async {
      if (!_istanbulIcindeMi(position.latitude, position.longitude)) {
        return;
      }

      await _firestore.collection('couriers').doc(kuryeId).update({
        'lat': position.latitude,
        'lng': position.longitude,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  static Future<void> canliTakibiDurdur() async {
    await _subscription?.cancel();
    _subscription = null;
  }
}
