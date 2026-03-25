import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class BildirimService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static const String _demoUserId = 'demo_user';

  static Future<void> initialize() async {
    try {
      if (kIsWeb) {
        print('Web ortamında FCM başlatma şimdilik atlandı.');
        return;
      }

      await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      final token = await _messaging.getToken();

      print('FCM TOKEN: $token');

      if (token == null || token.trim().isEmpty) {
        print('FCM token boş geldi.');
        return;
      }

      final ref =
          FirebaseFirestore.instance.collection('users').doc(_demoUserId);

      await ref.set({
        'fcmToken': token,
        'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      final kontrol = await ref.get();
      print('FCM YAZILDI MI: ${kontrol.data()}');
    } catch (e) {
      print('BildirimService initialize hata: $e');
    }
  }
}
