import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

import 'chef_image_upload_service.dart';
import 'upload_image_result.dart';

class ChefImageUploadServiceMobile implements ChefImageUploadService {
  final ImagePicker _picker = ImagePicker();

  @override
  Future<UploadImageResult?> pickAndUpload({
    required String chefId,
    required String folderName,
  }) async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 92,
    );

    if (picked == null) {
      return null;
    }

    final safeChefId = chefId.trim().isEmpty ? 'temp_chef' : chefId.trim();

    final ext = picked.name.contains('.')
        ? picked.name.split('.').last.toLowerCase()
        : 'jpg';

    final fileName = '${DateTime.now().millisecondsSinceEpoch}.$ext';
    final storagePath = 'chef_uploads/$safeChefId/$folderName/$fileName';

    final ref = FirebaseStorage.instance.ref(storagePath);

    await ref.putFile(
      File(picked.path),
      SettableMetadata(contentType: 'image/jpeg'),
    );

    final downloadUrl = await ref.getDownloadURL();

    return UploadImageResult(
      downloadUrl: downloadUrl,
      storagePath: storagePath,
      fileName: picked.name,
      localPath: picked.path,
    );
  }
}

ChefImageUploadService createChefImageUploadServiceImpl() =>
    ChefImageUploadServiceMobile();
