import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sana_app/data/services/api_service.dart';

class UploadService {
  final Dio dio;

  UploadService(this.dio);

  // Upload single file
  Future<Map<String, dynamic>> uploadFile(
    String filePath,
    String fileName,
  ) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath, filename: fileName),
    });

    final response = await dio.post('/uploads/single', data: formData);
    return response.data;
  }

  // Upload multiple files
  Future<List<Map<String, dynamic>>> uploadMultipleFiles(
    List<Map<String, String>> files,
  ) async {
    final formData = FormData.fromMap({
      'files': await Future.wait(
        files.map((file) => MultipartFile.fromFile(
              file['path']!,
              filename: file['name'],
            )),
      ),
    });

    final response = await dio.post('/uploads/multiple', data: formData);
    return List<Map<String, dynamic>>.from(response.data['data']);
  }

  // Upload profile photo
  Future<Map<String, dynamic>> uploadProfilePhoto(
    String filePath,
    String fileName,
  ) async {
    final formData = FormData.fromMap({
      'photo': await MultipartFile.fromFile(filePath, filename: fileName),
    });

    final response = await dio.post('/uploads/profile-photo', data: formData);
    return response.data;
  }
}

// Provider
final uploadServiceProvider = Provider<UploadService>((ref) {
  final dio = ref.watch(dioProvider);
  return UploadService(dio);
});
