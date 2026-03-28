import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static Future<User?> signInAnonymously() async {
    try {
      final result = await _auth.signInAnonymously();
      return result.user;
    } catch (e) {
      print('Auth hata: $e');
      return null;
    }
  }

  static String? get currentUserId {
    return _auth.currentUser?.uid;
  }
}