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

    if (cleanDisplayName.isEmpty) {
      throw Exception('displayName boş olamaz.');
    }

    final profileRef = _firestore.collection('chef_profiles').doc(cleanChefId);
    final profileSnap = await profileRef.get();

    final now = FieldValue.serverTimestamp();

    if (profileSnap.exists) {
      await profileRef.set({
        'updatedAt': now,
        'chefId': cleanChefId,
        'dukkanId': cleanDukkanId,
        'ad': cleanDisplayName,
        'displayName': cleanDisplayName,
        if ((img ?? '').trim().isNotEmpty) 'img': img!.trim(),
        if ((youtubeUrl ?? '').trim().isNotEmpty)
          'youtubeUrl': youtubeUrl!.trim(),
        if ((uzmanlik ?? '').trim().isNotEmpty)
          'uzmanlik': uzmanlik!.trim(),
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
      'kapakFoto': (img ?? '').trim(),
      'youtubeUrl': (youtubeUrl ?? '').trim(),

      'biyografi': '',
      'hakkinda': '',
      'mutfakTarzi': '',
      'imzaTabaklar': <String>[],
      'galeri': <String>[],
      'etiketler': <String>[],

      'instagram': '',
      'tiktok': '',
      'website': '',

      'puan': 0.0,
      'yorumSayisi': 0,
      'ogrenciSayisi': 0,
      'satisSayisi': 0,
      'tamamlananSiparis': 0,

      'profilTamamlanmaOrani': 20,
      'onboardingStep': 1,
      'onboardingComplete': false,

      'isActive': true,
      'createdAt': now,
      'updatedAt': now,
    });
  }
}
