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

  /// Satıcı/admin sabit giriş.
  /// Anonim kullanıcı varsa önce çıkış yapılır, sonra kalıcı hesapla giriş yapılır.
  static Future<UserCredential> signInSellerOrAdmin({
    required String email,
    required String password,
  }) async {
    final cleanEmail = email.trim().toLowerCase();

    if (!allowedAdminEmails.contains(cleanEmail)) {
      throw FirebaseAuthException(
        code: 'unauthorized-email',
        message: 'Bu e-posta yetkili giriş için tanımlı değil.',
      );
    }

    final existingUser = _auth.currentUser;

    if (existingUser != null && existingUser.isAnonymous) {
      await _auth.signOut();
    }

    final cred = await _auth.signInWithEmailAndPassword(
      email: cleanEmail,
      password: password,
    );

    final signedEmail = (cred.user?.email ?? '').trim().toLowerCase();

    if (!allowedAdminEmails.contains(signedEmail)) {
      await _auth.signOut();

      throw FirebaseAuthException(
        code: 'unauthorized-email',
        message: 'Bu e-posta yetkili giriş için tanımlı değil.',
      );
    }

    debugPrint(
      'AUTH FIXED LOGIN uid=${cred.user?.uid} email=${cred.user?.email} anonymous=${cred.user?.isAnonymous}',
    );

    return cred;
  }

  static const Set<String> allowedAdminEmails = {
    'meminhazret@gmail.com',
    'admin@sofrasofra.com',
  };
  static Future<void> signOut() async {
    await _auth.signOut();
    debugPrint('AUTH SIGN OUT');
  }
}
