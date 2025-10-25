import "dart:convert";
import "package:http/http.dart" as http;
import "http_client.dart";

class SearchService {
  static Future<List<dynamic>> searchQuizzes(
    String query, {
    String? category,
  }) async {
    return HttpClient.handleRequest(() async {
      final headers = await HttpClient.getHeaders();
      final categoryParam = category != null
          ? "&category=${Uri.encodeComponent(category)}"
          : "";
      return http.get(
        Uri.parse(
          "${HttpClient.baseUrl}/api/search/quizzes?q=${Uri.encodeComponent(query)}$categoryParam",
        ),
        headers: headers,
      );
    });
  }

  static Future<List<dynamic>> searchUsers(String query) async {
    return HttpClient.handleRequest(() async {
      final headers = await HttpClient.getHeaders();
      return http.get(
        Uri.parse(
          "${HttpClient.baseUrl}/api/search/users?q=${Uri.encodeComponent(query)}",
        ),
        headers: headers,
      );
    });
  }

  static Future<List<dynamic>> searchCollections(String query) async {
    return HttpClient.handleRequest(() async {
      final headers = await HttpClient.getHeaders();
      return http.get(
        Uri.parse(
          "${HttpClient.baseUrl}/api/search/collections?q=${Uri.encodeComponent(query)}",
        ),
        headers: headers,
      );
    });
  }

  static Future<List<dynamic>> searchPosts(String query) async {
    return HttpClient.handleRequest(() async {
      final headers = await HttpClient.getHeaders();
      return http.get(
        Uri.parse(
          "${HttpClient.baseUrl}/api/search/posts?q=${Uri.encodeComponent(query)}",
        ),
        headers: headers,
      );
    });
  }

  static Future<Map<String, dynamic>> searchAll(String query) async {
    return HttpClient.handleRequest(() async {
      final headers = await HttpClient.getHeaders();
      return http.get(
        Uri.parse(
          "${HttpClient.baseUrl}/api/search?q=${Uri.encodeComponent(query)}",
        ),
        headers: headers,
      );
    });
  }

  static Future<dynamic> saveSearchHistory(
    String query, {
    String? filterType,
  }) async {
    return HttpClient.handleRequest(() async {
      final headers = await HttpClient.getHeaders();
      return http.post(
        Uri.parse("${HttpClient.baseUrl}/api/search/history"),
        headers: headers,
        body: jsonEncode({
          'query': query,
          if (filterType != null) 'filterType': filterType,
        }),
      );
    });
  }

  static Future<List<dynamic>> getSearchHistory() async {
    return HttpClient.handleRequest(() async {
      final headers = await HttpClient.getHeaders();
      return http.get(
        Uri.parse("${HttpClient.baseUrl}/api/search/history"),
        headers: headers,
      );
    });
  }

  static Future<void> deleteSearchHistory(String id) async {
    return HttpClient.handleRequest(() async {
      final headers = await HttpClient.getHeaders();
      return http.delete(
        Uri.parse("${HttpClient.baseUrl}/api/search/history/$id"),
        headers: headers,
      );
    });
  }
}
