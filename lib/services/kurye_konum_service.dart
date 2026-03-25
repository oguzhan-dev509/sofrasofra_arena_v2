import 'package:cloud_firestore/cloud_firestore.dart';

class KuryeKonumService {
  final FirebaseFirestore _firestore;

  KuryeKonumService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<void> kuryeKonumGuncelle({
    required String courierId,
    required double lat,
    required double lng,
    double? heading,
    double? speed,
  }) async {
    await _firestore.collection('couriers').doc(courierId).set({
      'location': {
        'lat': lat,
        'lng': lng,
        'heading': heading ?? 0.0,
        'speed': speed ?? 0.0,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      'lastSeenAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> kuryeSonKonumuTemizle(String courierId) async {
    await _firestore.collection('couriers').doc(courierId).set({
      'location': FieldValue.delete(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> kuryeDinle(String courierId) {
    return _firestore.collection('couriers').doc(courierId).snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> tumKuryeleriDinle() {
    return _firestore.collection('couriers').snapshots();
  }
}
