import 'dart:typed_data';

class UploadImageResult {
  final String downloadUrl;
  final String storagePath;
  final Uint8List? webBytes;
  final String? localPath;
  final String fileName;

  const UploadImageResult({
    required this.downloadUrl,
    required this.storagePath,
    required this.fileName,
    this.webBytes,
    this.localPath,
  });
}
