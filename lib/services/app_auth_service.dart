import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class AppAuthService {
  AppAuthService._();

  static FirebaseAuth get _auth => FirebaseAuth.instance;

  static User? get currentUser => _auth.currentUser;

  static String get currentUid => (_auth.currentUser?.uid ?? '').trim();

  static bool get isAnonymous => _auth.currentUser?.isAnonymous == true;

  /// Müşteri/alıcı tarafı için güvenli misafir oturumu.
  /// Satıcı/admin için kullanılmaz.
  static Future<User?> ensureGuestSession() async {
    final existingUser = _auth.currentUser;

    if (existingUser != null) {
      debugPrint(
        'AUTH EXISTING uid=${existingUser.uid} anonymous=${existingUser.isAnonymous}',
      );
      return existingUser;
    }

    final cred = await _auth.signInAnonymously();

    debugPrint(
      'AUTH GUEST CREATED uid=${cred.user?.uid} anonymous=${cred.user?.isAnonymous}',
    );

    return cred.user;
  }

  /// Kalıcı satıcı, üretici ve platform yöneticisi girişi.
  ///
  /// Yönetici yetkisi burada e-posta listesiyle verilmez.
  /// Platform yöneticiliği Firestore'daki platform_admins/{uid}
  /// belgesi üzerinden kontrol edilir.
  static Future<UserCredential> signInSellerOrAdmin({
    required String email,
    required String password,
  }) async {
    final cleanEmail = email.trim().toLowerCase();

    if (cleanEmail.isEmpty || password.isEmpty) {
      throw FirebaseAuthException(
        code: 'missing-credentials',
        message: 'E-posta ve şifre zorunludur.',
      );
    }

    final existingUser = _auth.currentUser;

    if (existingUser != null && existingUser.isAnonymous) {
      await _auth.signOut();
    }

    final credential = await _auth.signInWithEmailAndPassword(
      email: cleanEmail,
      password: password,
    );

    final user = credential.user;

    if (user == null || user.isAnonymous) {
      await _auth.signOut();

      throw FirebaseAuthException(
        code: 'invalid-fixed-account',
        message: 'Kalıcı kullanıcı hesabıyla giriş yapılamadı.',
      );
    }

    debugPrint(
      'AUTH FIXED LOGIN '
      'uid=${user.uid} '
      'email=${user.email} '
      'anonymous=${user.isAnonymous}',
    );

    return credential;
  }

  static Future<void> signOut() async {
    await _auth.signOut();
    debugPrint('AUTH SIGN OUT');
  }
}
