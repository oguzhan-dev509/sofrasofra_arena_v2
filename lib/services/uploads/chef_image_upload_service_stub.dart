import 'chef_image_upload_service.dart';
import 'upload_image_result.dart';

class UnsupportedChefImageUploadService implements ChefImageUploadService {
  @override
  Future<UploadImageResult?> pickAndUpload({
    required String chefId,
    required String folderName,
  }) async {
    throw UnsupportedError('Bu platformda upload desteklenmiyor.');
  }
}

ChefImageUploadService createChefImageUploadServiceImpl() =>
    UnsupportedChefImageUploadService();
