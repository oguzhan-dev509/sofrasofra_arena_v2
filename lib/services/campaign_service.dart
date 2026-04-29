import 'package:cloud_firestore/cloud_firestore.dart';

class CampaignService {
  static final _ref =
      FirebaseFirestore.instance.collection('campaignSettings').doc('main');

  /// type: 'ev' | 'sef'
  static Future<void> decreaseQuota(String type) async {
    await FirebaseFirestore.instance.runTransaction((tx) async {
      final snap = await tx.get(_ref);

      if (!snap.exists) return;

      final data = snap.data() as Map<String, dynamic>;

      if (type == 'ev') {
        final current = data['evKalan'] ?? 0;
        if (current > 0) {
          tx.update(_ref, {'evKalan': current - 1});
        }
      } else if (type == 'sef') {
        final current = data['sefKalan'] ?? 0;
        if (current > 0) {
          tx.update(_ref, {'sefKalan': current - 1});
        }
      }
    });
  }
}
