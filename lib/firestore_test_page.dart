import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreTestPage extends StatelessWidget {
  const FirestoreTestPage({super.key});

  Future<String> _test() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;

      // ✅ Rules uyumlu okuma: sadece onayli == true olanlardan dene
      final snap = await FirebaseFirestore.instance
          .collection('urunler')
          .where('onayli', isEqualTo: true)
          .limit(3)
          .get();

      return '✅ Firestore OK\n'
          'UID: ${uid ?? "null"}\n'
          'onayli==true bulunan: ${snap.docs.length}';
    } catch (e) {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      return '❌ Firestore ERROR: $e\nUID: ${uid ?? "null"}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Firestore Test'),
      ),
      body: Center(
        child: FutureBuilder<String>(
          future: _test(),
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const CircularProgressIndicator();
            }
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                snapshot.data ?? '❌ Test sonucu alınamadı.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white),
              ),
            );
          },
        ),
      ),
    );
  }
}
