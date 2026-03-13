import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
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

  static Future<void> tekSeferlikKonumGuncelle({
    required String kuryeId,
  }) async {
    await _konumIzinleriniKontrolEt();

    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    await _firestore.collection('couriers').doc(kuryeId).update({
      'lat': position.latitude,
      'lng': position.longitude,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> canliTakibiBaslat({
    required String kuryeId,
  }) async {
    await _konumIzinleriniKontrolEt();

    await _subscription?.cancel();

    _subscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((position) async {
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
