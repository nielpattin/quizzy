import "dart:convert";
import "package:http/http.dart" as http;
import "http_client.dart";

class SocialService {
  static Future<List<dynamic>> getFeedPosts({
    int limit = 20,
    int offset = 0,
  }) async {
    return HttpClient.handleRequest(() async {
      final headers = await HttpClient.getHeaders();
      return http.get(
        Uri.parse(
          "${HttpClient.baseUrl}/api/social/posts?limit=$limit&offset=$offset",
        ),
        headers: headers,
      );
    });
  }

  static Future<List<dynamic>> getUserPosts(String userId) async {
    return HttpClient.handleRequest(() async {
      final headers = await HttpClient.getHeaders();
      return http.get(
        Uri.parse("${HttpClient.baseUrl}/api/social/user/$userId/posts"),
        headers: headers,
      );
    });
  }

  static Future<dynamic> createPost(
    String text, {
    String postType = 'text',
    String? imageUrl,
    String? questionType,
    String? questionText,
    Map<String, dynamic>? questionData,
  }) async {
    return HttpClient.handleRequest(() async {
      final headers = await HttpClient.getHeaders();
      final body = <String, dynamic>{'text': text, 'postType': postType};

      if (imageUrl != null) body['imageUrl'] = imageUrl;
      if (questionType != null) body['questionType'] = questionType;
      if (questionText != null) body['questionText'] = questionText;
      if (questionData != null) body['questionData'] = questionData;

      return http.post(
        Uri.parse("${HttpClient.baseUrl}/api/social/posts"),
        headers: headers,
        body: jsonEncode(body),
      );
    });
  }

  static Future<dynamic> submitPostAnswer(String postId, dynamic answer) async {
    return HttpClient.handleRequest(() async {
      final headers = await HttpClient.getHeaders();
      return http.post(
        Uri.parse("${HttpClient.baseUrl}/api/social/posts/$postId/answer"),
        headers: headers,
        body: jsonEncode({"answer": answer}),
      );
    });
  }

  static Future<void> deletePost(String postId) async {
    return HttpClient.handleRequest(() async {
      final headers = await HttpClient.getHeaders();
      return http.delete(
        Uri.parse("${HttpClient.baseUrl}/api/social/posts/$postId"),
        headers: headers,
      );
    });
  }

  static Future<void> likePost(String postId) async {
    return HttpClient.handleRequest(() async {
      final headers = await HttpClient.getHeaders();
      return http.post(
        Uri.parse("${HttpClient.baseUrl}/api/social/posts/$postId/like"),
        headers: headers,
      );
    });
  }

  static Future<void> unlikePost(String postId) async {
    return HttpClient.handleRequest(() async {
      final headers = await HttpClient.getHeaders();
      return http.delete(
        Uri.parse("${HttpClient.baseUrl}/api/social/posts/$postId/like"),
        headers: headers,
      );
    });
  }

  static Future<List<dynamic>> getPostComments(String postId) async {
    return HttpClient.handleRequest(() async {
      final headers = await HttpClient.getHeaders();
      return http.get(
        Uri.parse("${HttpClient.baseUrl}/api/social/posts/$postId/comments"),
        headers: headers,
      );
    });
  }

  static Future<void> addComment(String postId, String content) async {
    return HttpClient.handleRequest(() async {
      final headers = await HttpClient.getHeaders();
      return http.post(
        Uri.parse("${HttpClient.baseUrl}/api/social/posts/$postId/comments"),
        headers: headers,
        body: jsonEncode({"content": content}),
      );
    });
  }

  static Future<void> deleteComment(String commentId) async {
    return HttpClient.handleRequest(() async {
      final headers = await HttpClient.getHeaders();
      return http.delete(
        Uri.parse("${HttpClient.baseUrl}/api/social/comments/$commentId"),
        headers: headers,
      );
    });
  }

  static Future<dynamic> getPost(String postId) async {
    return HttpClient.handleRequest(() async {
      final headers = await HttpClient.getHeaders();
      return http.get(
        Uri.parse("${HttpClient.baseUrl}/api/social/posts/$postId"),
        headers: headers,
      );
    });
  }

  static Future<void> likeComment(String commentId) async {
    return HttpClient.handleRequest(() async {
      final headers = await HttpClient.getHeaders();
      return http.post(
        Uri.parse("${HttpClient.baseUrl}/api/social/comments/$commentId/like"),
        headers: headers,
      );
    });
  }

  static Future<void> unlikeComment(String commentId) async {
    return HttpClient.handleRequest(() async {
      final headers = await HttpClient.getHeaders();
      return http.delete(
        Uri.parse("${HttpClient.baseUrl}/api/social/comments/$commentId/like"),
        headers: headers,
      );
    });
  }
}
