import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';

class KuryeSimulator {
  final String courierId;

  KuryeSimulator(this.courierId);

  Timer? _timer;

  void start() {
    double lat = 40.9912;
    double lng = 29.0284;

    _timer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      lat += 0.0050;
      lng += 0.0050;

      await FirebaseFirestore.instance
          .collection('couriers')
          .doc(courierId)
          .update({
        'lat': lat,
        'lng': lng,
        'lastLocationAt': FieldValue.serverTimestamp(),
      });
    });
  }

  void stop() {
    _timer?.cancel();
  }
}
