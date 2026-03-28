import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'chef_image_upload_service.dart';
import 'upload_image_result.dart';

class ChefImageUploadServiceWeb implements ChefImageUploadService {
  @override
  Future<UploadImageResult?> pickAndUpload({
    required String chefId,
    required String folderName,
  }) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );

    if (result == null || result.files.isEmpty) {
      return null;
    }

    final file = result.files.first;
    final bytes = file.bytes;

    if (bytes == null || bytes.isEmpty) {
      return null;
    }

    final safeChefId = chefId.trim().isEmpty ? 'temp_chef' : chefId.trim();
    final ext = (file.extension ?? 'jpg').toLowerCase();
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.$ext';
    final storagePath = 'chef_uploads/$safeChefId/$folderName/$fileName';

    final ref = FirebaseStorage.instance.ref(storagePath);

    await ref.putData(
      bytes,
      SettableMetadata(
        contentType: 'image/jpeg',
      ),
    );

    final downloadUrl = await ref.getDownloadURL();

    return UploadImageResult(
      downloadUrl: downloadUrl,
      storagePath: storagePath,
      fileName: file.name,
      webBytes: bytes,
    );
  }
}

ChefImageUploadService createChefImageUploadServiceImpl() =>
    ChefImageUploadServiceWeb();
