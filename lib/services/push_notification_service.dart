import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class PushNotificationService {
  static Future<void> init() async {
    if (kIsWeb) {
      debugPrint('WEB ortamında PushNotificationService kapatıldı');
      return;
    }

    try {
      final messaging = FirebaseMessaging.instance;

      await messaging.requestPermission();

      final token = await messaging.getToken();
      debugPrint('FCM TOKEN: $token');

      if (token == null) return;

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'fcmTokens': FieldValue.arrayUnion([token]),
        'fcmToken': token,
        'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser == null) return;

        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .set({
          'fcmTokens': FieldValue.arrayUnion([newToken]),
          'fcmToken': newToken,
          'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      });
    } catch (e) {
      debugPrint('PushNotificationService.init hata: $e');
    }
  }
}
