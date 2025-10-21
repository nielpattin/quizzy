import "dart:convert";
import "package:http/http.dart" as http;
import "package:flutter_dotenv/flutter_dotenv.dart";
import "package:supabase_flutter/supabase_flutter.dart";
import "api_exception.dart";

class HttpClient {
  static final String baseUrl = dotenv.env["SERVER_URL"]!;

  static Future<Map<String, String>> getHeaders() async {
    final session = Supabase.instance.client.auth.currentSession;
    return {
      "Content-Type": "application/json",
      if (session != null) "Authorization": "Bearer ${session.accessToken}",
    };
  }

  static Future<T> handleRequest<T>(
    Future<http.Response> Function() request,
  ) async {
    try {
      final response = await request();

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (response.body.isEmpty) {
          return null as T;
        }
        return jsonDecode(response.body) as T;
      } else if (response.statusCode == 401) {
        throw ApiException(
          "Unauthorized - please log in again",
          statusCode: 401,
        );
      } else if (response.statusCode == 404) {
        throw ApiException("Resource not found", statusCode: 404);
      } else {
        try {
          final error = jsonDecode(response.body);
          throw ApiException(
            error["error"] ?? "An error occurred",
            statusCode: response.statusCode,
          );
        } catch (_) {
          throw ApiException(
            "Server error: ${response.statusCode}",
            statusCode: response.statusCode,
          );
        }
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException("Network error: ${e.toString()}");
    }
  }
}
