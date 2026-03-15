import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'otomatik_yeniden_atama_servisi.dart';

class DispatchTimeoutWatcher {
  Timer? _timer;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final OtomatikYenidenAtamaServisi _servis = OtomatikYenidenAtamaServisi();

  void start() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 10), (_) async {
      final query = await _firestore
          .collection('orders')
          .where('assignmentStatus', isEqualTo: 'offer_sent')
          .limit(20)
          .get();

      for (final doc in query.docs) {
        await _servis.timeoutKontrolVeYenidenAta(orderId: doc.id);
      }
    });
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }
}
