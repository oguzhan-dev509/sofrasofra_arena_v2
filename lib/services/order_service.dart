import 'package:cloud_firestore/cloud_firestore.dart';

class OrderService {
  final _firestore = FirebaseFirestore.instance;

  Future<String> createOrder({
    required String userId,
    required String customerName,
    required String phone,
    required String address,
    required String city,
    required String district,
    required List<Map<String, dynamic>> items,
    required double araToplam,
    required double teslimatUcreti,
    required double genelToplam,
    required String paymentMethod,
  }) async {
    final docRef = _firestore.collection('orders').doc();

    await docRef.set({
      "orderId": docRef.id,
      "userId": userId,
      "customerName": customerName,
      "phone": phone,
      "addressText": address,
      "city": city,
      "district": district,
      "items": items,
      "araToplam": araToplam,
      "teslimatUcreti": teslimatUcreti,
      "genelToplam": genelToplam,
      "paymentMethod": paymentMethod,
      "paymentStatus": "pending",
      "status": "pending",
      "assignmentStatus": "unassigned",
      "createdAt": FieldValue.serverTimestamp(),
      "updatedAt": FieldValue.serverTimestamp(),
    });

    return docRef.id;
  }
}
