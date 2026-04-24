import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class EvGalleryManager {
  EvGalleryManager._();

  static final ImagePicker _picker = ImagePicker();

  static bool isHttpUrl(String? value) {
    final v = (value ?? '').trim();
    return v.startsWith('http://') || v.startsWith('https://');
  }

  static List<String> normalizeImages({
    List<dynamic>? images,
    String? fallbackImage,
  }) {
    final resolved = <String>[];

    void addIfValid(dynamic raw) {
      final value = (raw ?? '').toString().trim();
      if (!isHttpUrl(value)) return;
      if (resolved.contains(value)) return;
      resolved.add(value);
    }

    if (images != null) {
      for (final item in images) {
        addIfValid(item);
      }
    }

    addIfValid(fallbackImage);

    return resolved;
  }

  static List<String> normalizeGalleryImages({
    List<dynamic>? images,
  }) {
    final resolved = <String>[];

    void addIfValid(dynamic raw) {
      final value = (raw ?? '').toString().trim();
      if (!isHttpUrl(value)) return;
      if (value.contains('/cover/') || value.contains('%2Fcover%2F')) return;
      if (resolved.contains(value)) return;
      resolved.add(value);
    }

    if (images != null) {
      for (final item in images) {
        addIfValid(item);
      }
    }

    return resolved;
  }

  static Future<Uint8List?> pickSingleImage({
    int imageQuality = 85,
  }) async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: imageQuality,
    );
    if (picked == null) return null;
    return picked.readAsBytes();
  }

  static Future<List<Uint8List>> pickImages({
    int maxCount = 1,
    int imageQuality = 85,
  }) async {
    final picked = await _picker.pickMultiImage(imageQuality: imageQuality);
    if (picked.isEmpty) return <Uint8List>[];

    final limited = picked.take(maxCount).toList();
    final bytesList = <Uint8List>[];

    for (final file in limited) {
      bytesList.add(await file.readAsBytes());
    }

    return bytesList;
  }

  static Future<String> uploadImage({
    required String sellerId,
    required String productId,
    required Uint8List bytes,
  }) async {
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';

    final ref = FirebaseStorage.instance
        .ref()
        .child('urunler')
        .child(sellerId)
        .child(productId)
        .child('gallery')
        .child(fileName);

    final snap = await ref.putData(
      bytes,
      SettableMetadata(contentType: 'image/jpeg'),
    );

    return snap.ref.getDownloadURL();
  }

  static Future<String> uploadCoverImage({
    required String sellerId,
    required String productId,
    required Uint8List bytes,
  }) async {
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';

    final ref = FirebaseStorage.instance
        .ref()
        .child('urunler')
        .child(sellerId)
        .child(productId)
        .child('cover')
        .child(fileName);

    final snap = await ref.putData(
      bytes,
      SettableMetadata(contentType: 'image/jpeg'),
    );

    return snap.ref.getDownloadURL();
  }

  static Future<List<String>> uploadImages({
    required String sellerId,
    required String productId,
    required List<Uint8List> files,
  }) async {
    final urls = <String>[];

    for (final bytes in files) {
      final url = await uploadImage(
        sellerId: sellerId,
        productId: productId,
        bytes: bytes,
      );
      urls.add(url);
    }

    return urls;
  }

  static Future<void> addGalleryImages({
    required String productId,
    required String sellerId,
    required List<String> existingImages,
    required List<String> newUrls,
  }) async {
    final docRef =
        FirebaseFirestore.instance.collection('urunler').doc(productId);

    final merged = normalizeGalleryImages(
      images: [...existingImages, ...newUrls],
    );

    final currentDoc = await docRef.get();
    final currentData = currentDoc.data() ?? <String, dynamic>{};
    final currentImg = (currentData['img'] ?? '').toString().trim();

    await docRef.set({
      'dukkanId': sellerId,
      'images': merged,
      'img': currentImg,
      'photoCount': merged.length,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static Future<void> removeGalleryImage({
    required String productId,
    required String sellerId,
    required List<String> existingImages,
    required String imageUrl,
  }) async {
    final docRef =
        FirebaseFirestore.instance.collection('urunler').doc(productId);

    final next = existingImages
        .where((e) => e.trim().isNotEmpty && e.trim() != imageUrl.trim())
        .toList();

    final normalized = normalizeGalleryImages(
      images: next,
    );

    final currentDoc = await docRef.get();
    final currentData = currentDoc.data() ?? <String, dynamic>{};
    final currentImg = (currentData['img'] ?? '').toString().trim();

    final nextImg = currentImg == imageUrl.trim()
        ? (normalized.isNotEmpty ? normalized.first : '')
        : currentImg;

    await docRef.set({
      'dukkanId': sellerId,
      'images': normalized,
      'img': nextImg,
      'photoCount': normalized.length,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static Future<void> replaceCoverImage({
    required String productId,
    required String sellerId,
    required List<String> existingImages,
    required String newCoverUrl,
  }) async {
    final docRef =
        FirebaseFirestore.instance.collection('urunler').doc(productId);

    final normalizedGallery = normalizeGalleryImages(
      images: existingImages,
    );

    await docRef.set({
      'dukkanId': sellerId,
      'img': newCoverUrl.trim(),
      'images': normalizedGallery,
      'photoCount': normalizedGallery.length,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static Future<void> setAsCoverImage({
    required String productId,
    required String sellerId,
    required List<String> existingImages,
    required String imageUrl,
  }) async {
    final docRef =
        FirebaseFirestore.instance.collection('urunler').doc(productId);

    final normalized = normalizeGalleryImages(
      images: existingImages,
    );

    await docRef.set({
      'dukkanId': sellerId,
      'img': imageUrl.trim(),
      'images': normalized,
      'photoCount': normalized.length,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static Future<void> removeCoverImage({
    required String productId,
    required String sellerId,
    required List<String> existingImages,
  }) async {
    final docRef =
        FirebaseFirestore.instance.collection('urunler').doc(productId);

    final normalized = normalizeGalleryImages(
      images: existingImages,
    );

    await docRef.set({
      'dukkanId': sellerId,
      'img': '',
      'images': normalized,
      'photoCount': normalized.length,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static Future<void> deleteStorageByUrl(String? url) async {
    final value = (url ?? '').trim();
    if (!isHttpUrl(value)) return;

    try {
      final ref = FirebaseStorage.instance.refFromURL(value);
      await ref.delete();
    } catch (_) {
      // Firestore tarafı yine güncellensin diye burada sessiz geçiyoruz.
    }
  }
}
