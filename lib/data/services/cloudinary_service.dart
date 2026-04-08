import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CloudinaryService {
  // Replace with your actual Cloudinary credentials
  static const String _cloudName = 'dqw4rtvqv';
  static const String _uploadPreset = 'routine_plus_preset'; // unsigned preset
  static const String _folder = 'routine_plus/avatars';

  static const String _baseUrl =
      'https://api.cloudinary.com/v1_1/$_cloudName/image/upload';

  /// Uploads [file] to Cloudinary and returns the secure URL.
  Future<String?> uploadProfilePhoto(File file) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse(_baseUrl));
      request.fields['upload_preset'] = _uploadPreset;
      request.fields['folder'] = _folder;
      request.files.add(
        await http.MultipartFile.fromPath('file', file.path),
      );

      final response = await request.send();
      final responseData = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final json = jsonDecode(responseData);
        return json['secure_url'] as String?;
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
