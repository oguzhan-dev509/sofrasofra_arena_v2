import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../lib/firebase_options.dart';

Future<void> main() async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final firestore = FirebaseFirestore.instance;

  print('🚀 ownerId düzeltme başlıyor...\n');

  final snapshot = await firestore.collection('urunler').get();

  int fixed = 0;
  int skipped = 0;

  for (var doc in snapshot.docs) {
    final data = doc.data();

    final String currentOwnerId = (data['ownerId'] ?? '').toString().trim();

    if (currentOwnerId.isNotEmpty) {
      skipped++;
      continue;
    }

    // 🔥 ownerId üretme mantığı
    final String rawName =
        (data['dukkan'] ?? data['ad'] ?? 'chef').toString().toLowerCase();

    final String cleaned = rawName
        .replaceAll(' ', '_')
        .replaceAll(RegExp(r'[^a-z0-9_ğüşöçı]'), '');

    final String newOwnerId = 'chef_$cleaned';

    await doc.reference.update({
      'ownerId': newOwnerId,
    });

    print('✅ ${doc.id} → ownerId: $newOwnerId');
    fixed++;
  }

  print('\n🎯 TAMAMLANDI');
  print('✔️ Güncellenen: $fixed');
  print('⏭️ Atlanan: $skipped');
}
