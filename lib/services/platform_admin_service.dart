import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class PlatformAdminService {
  PlatformAdminService._();

  static Future<bool> isCurrentUserPlatformAdmin() async {
    final uid = (FirebaseAuth.instance.currentUser?.uid ?? '').trim();

    if (uid.isEmpty) {
      return false;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('platform_admins')
          .doc(uid)
          .get();

      final data = doc.data();
      final active = data?['active'] == true;

      return doc.exists && active;
    } catch (e) {
      debugPrint('PlatformAdminService admin check error: $e');
      return false;
    }
  }
}
