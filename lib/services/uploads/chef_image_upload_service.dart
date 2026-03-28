import 'upload_image_result.dart';
import 'chef_image_upload_service_impl.dart';

abstract class ChefImageUploadService {
  Future<UploadImageResult?> pickAndUpload({
    required String chefId,
    required String folderName,
  });
}

ChefImageUploadService createChefImageUploadService() =>
    createChefImageUploadServiceImpl();
