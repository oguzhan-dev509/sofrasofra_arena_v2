import 'package:cloud_firestore/cloud_firestore.dart';

class ChefValidationResult {
  final bool ok;
  final String message;

  const ChefValidationResult({
    required this.ok,
    required this.message,
  });
}

class ChefValidationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<ChefValidationResult> validateChefProductBeforeCreate({
    required String ownerId,
    required String dukkanId,
    required String ad,
    String? currentDocId,
  }) async {
    final cleanOwnerId = ownerId.trim();
    final cleanDukkanId = dukkanId.trim();
    final cleanAd = ad.trim();

    if (cleanOwnerId.isEmpty) {
      return const ChefValidationResult(
        ok: false,
        message: 'ownerId boş olamaz.',
      );
    }

    if (cleanDukkanId.isEmpty) {
      return const ChefValidationResult(
        ok: false,
        message: 'dukkanId boş olamaz.',
      );
    }

    if (cleanAd.isEmpty) {
      return const ChefValidationResult(
        ok: false,
        message: 'Şef adı boş olamaz.',
      );
    }

    final chefProfile = await _firestore
        .collection('chef_profiles')
        .doc(cleanOwnerId)
        .get();

    if (!chefProfile.exists) {
      return ChefValidationResult(
        ok: false,
        message: 'chef_profiles/$cleanOwnerId bulunamadı.',
      );
    }

    final sameOwnerQuery = await _firestore
        .collection('urunler')
        .where('tip', isEqualTo: 'Usta Sefler')
        .where('ownerId', isEqualTo: cleanOwnerId)
        .get();

    final duplicateOwnerDocs = sameOwnerQuery.docs.where((doc) {
      if (currentDocId == null || currentDocId.isEmpty) return true;
      return doc.id != currentDocId;
    }).toList();

    if (duplicateOwnerDocs.isNotEmpty) {
      return ChefValidationResult(
        ok: false,
        message:
            'Bu ownerId için zaten kayıt var: ${duplicateOwnerDocs.first.id}',
      );
    }

    final sameDukkanQuery = await _firestore
        .collection('urunler')
        .where('tip', isEqualTo: 'Usta Sefler')
        .where('dukkanId', isEqualTo: cleanDukkanId)
        .get();

    final duplicateDukkanDocs = sameDukkanQuery.docs.where((doc) {
      if (currentDocId == null || currentDocId.isEmpty) return true;
      return doc.id != currentDocId;
    }).toList();

    if (duplicateDukkanDocs.isNotEmpty) {
      return ChefValidationResult(
        ok: false,
        message:
            'Bu dukkanId için zaten kayıt var: ${duplicateDukkanDocs.first.id}',
      );
    }

    return const ChefValidationResult(
      ok: true,
      message: 'Doğrulama başarılı.',
    );
  }
}
