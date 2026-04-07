import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  static Future<void> signInAnonymously() async {
    final auth = FirebaseAuth.instance;

    if (auth.currentUser != null) {
      debugPrint('✅ Mevcut kullanıcı: ${auth.currentUser!.uid}');
      return;
    }

    final cred = await auth.signInAnonymously();
    debugPrint('🆕 Yeni anonim kullanıcı: ${cred.user?.uid}');
  }
}
