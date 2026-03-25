import 'package:cloud_firestore/cloud_firestore.dart';

class ChefProfileBootstrapService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<void> ensureChefProfile({
    required String chefId,
    required String dukkanId,
    required String displayName,
    String? sehir,
    String? ilce,
    String? uzmanlik,
    String? img,
    String? youtubeUrl,
  }) async {
    final cleanChefId = chefId.trim();
    final cleanDukkanId = dukkanId.trim();
    final cleanDisplayName = displayName.trim();

    if (cleanChefId.isEmpty) {
      throw Exception('chefId boş olamaz.');
    }

    if (cleanDukkanId.isEmpty) {
      throw Exception('dukkanId boş olamaz.');
    }

    final profileRef = _firestore.collection('chef_profiles').doc(cleanChefId);
    final profileSnap = await profileRef.get();

    if (profileSnap.exists) {
      await profileRef.set({
        'updatedAt': FieldValue.serverTimestamp(),
        if ((img ?? '').trim().isNotEmpty) 'img': img!.trim(),
        if ((youtubeUrl ?? '').trim().isNotEmpty) 'youtubeUrl': youtubeUrl!.trim(),
        if ((uzmanlik ?? '').trim().isNotEmpty) 'uzmanlik': uzmanlik!.trim(),
        if ((sehir ?? '').trim().isNotEmpty) 'sehir': sehir!.trim(),
        if ((ilce ?? '').trim().isNotEmpty) 'ilce': ilce!.trim(),
      }, SetOptions(merge: true));
      return;
    }

    await profileRef.set({
      'chefId': cleanChefId,
      'dukkanId': cleanDukkanId,
      'ad': cleanDisplayName,
      'displayName': cleanDisplayName,
      'uzmanlik': (uzmanlik ?? '').trim(),
      'sehir': (sehir ?? '').trim(),
      'ilce': (ilce ?? '').trim(),
      'img': (img ?? '').trim(),
      'youtubeUrl': (youtubeUrl ?? '').trim(),
      'biyografi': '',
      'isActive': true,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}