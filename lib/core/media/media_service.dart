import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class MediaService {
  static final ImagePicker _picker = ImagePicker();

  static Future<Uint8List?> pickImage({
    int imageQuality = 85,
  }) async {
    try {
      final XFile? file = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: imageQuality,
      );

      if (file == null) {
        return null;
      }

      return await file.readAsBytes();
    } catch (e) {
      print('PICK IMAGE ERROR => $e');
      return null;
    }
  }

  static Future<String> upload({
    required Uint8List data,
    required String path,
    String contentType = 'image/jpeg',
  }) async {
    try {
      final ref = FirebaseStorage.instance.ref().child(path);

      final task = await ref.putData(
        data,
        SettableMetadata(contentType: contentType),
      );

      final url = await task.ref.getDownloadURL();

      print('UPLOAD SUCCESS => $url');

      return url;
    } catch (e) {
      print('UPLOAD ERROR => $e');
      rethrow;
    }
  }
}
