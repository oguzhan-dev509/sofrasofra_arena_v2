import 'package:cloud_firestore/cloud_firestore.dart';

class ChefService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<List<Map<String, dynamic>>> streamChefs() {
    return _db.collection('chefs').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => doc.data()).toList();
    });
  }
}
