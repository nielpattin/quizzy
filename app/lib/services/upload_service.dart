import "dart:convert";
import "package:http/http.dart" as http;
import "package:image_picker/image_picker.dart";
import "package:supabase_flutter/supabase_flutter.dart";
import "api_exception.dart";
import "http_client.dart";

class UploadService {
  static Future<Map<String, dynamic>> uploadImage(XFile imageFile) async {
    try {
      final session = Supabase.instance.client.auth.currentSession;
      if (session == null) {
        throw ApiException("Not authenticated", statusCode: 401);
      }

      final request = http.MultipartRequest(
        "POST",
        Uri.parse("${HttpClient.baseUrl}/api/upload/image"),
      );
      request.headers["Authorization"] = "Bearer ${session.accessToken}";

      // Use fromBytes with readAsBytes() for web compatibility
      final bytes = await imageFile.readAsBytes();
      request.files.add(
        http.MultipartFile.fromBytes("image", bytes, filename: imageFile.name),
      );

      final response = await request.send();
      final responseData = await response.stream.bytesToString();

      if (response.statusCode == 201) {
        final json = jsonDecode(responseData);
        return json["image"] as Map<String, dynamic>;
      } else {
        throw ApiException(
          "Failed to upload image: $responseData",
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException("Image upload failed: ${e.toString()}");
    }
  }

  static Future<String> getImageUrl(String imageId) async {
    final dynamic result = await HttpClient.handleRequest(() async {
      final headers = await HttpClient.getHeaders();
      return http.get(
        Uri.parse("${HttpClient.baseUrl}/api/upload/image/$imageId/url"),
        headers: headers,
      );
    });
    return result["url"] as String;
  }
}
