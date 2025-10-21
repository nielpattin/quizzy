import "dart:convert";
import "package:http/http.dart" as http;
import "package:flutter_dotenv/flutter_dotenv.dart";
import "package:supabase_flutter/supabase_flutter.dart";
import "api_exception.dart";

class ApiService {
  static final String _baseUrl = dotenv.env["SERVER_URL"]!;

  static Future<Map<String, String>> _getHeaders() async {
    final session = Supabase.instance.client.auth.currentSession;
    return {
      "Content-Type": "application/json",
      if (session != null) "Authorization": "Bearer ${session.accessToken}",
    };
  }

  static Future<T> _handleRequest<T>(
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

  static Future<List<dynamic>> getFeaturedQuizzes() async {
    return _handleRequest(() async {
      final headers = await _getHeaders();
      return http.get(
        Uri.parse("$_baseUrl/api/quiz/featured"),
        headers: headers,
      );
    });
  }

  static Future<List<dynamic>> getTrendingQuizzes() async {
    return _handleRequest(() async {
      final headers = await _getHeaders();
      return http.get(
        Uri.parse("$_baseUrl/api/quiz/trending"),
        headers: headers,
      );
    });
  }

  static Future<List<dynamic>> getCategoryQuizzes(String category) async {
    return _handleRequest(() async {
      final headers = await _getHeaders();
      return http.get(
        Uri.parse("$_baseUrl/api/quiz/category/$category"),
        headers: headers,
      );
    });
  }

  static Future<List<dynamic>> getUserQuizzes(String userId) async {
    return _handleRequest(() async {
      final headers = await _getHeaders();
      return http.get(
        Uri.parse("$_baseUrl/api/quiz/user/$userId"),
        headers: headers,
      );
    });
  }

  static Future<dynamic> getQuiz(String quizId) async {
    return _handleRequest(() async {
      final headers = await _getHeaders();
      return http.get(
        Uri.parse("$_baseUrl/api/quiz/$quizId"),
        headers: headers,
      );
    });
  }

  static Future<void> deleteQuiz(String quizId) async {
    return _handleRequest(() async {
      final headers = await _getHeaders();
      return http.delete(
        Uri.parse("$_baseUrl/api/quiz/$quizId"),
        headers: headers,
      );
    });
  }

  static Future<void> favoriteQuiz(String quizId) async {
    return _handleRequest(() async {
      final headers = await _getHeaders();
      return http.post(
        Uri.parse("$_baseUrl/api/favorite"),
        headers: headers,
        body: jsonEncode({"quizId": quizId}),
      );
    });
  }

  static Future<void> unfavoriteQuiz(String quizId) async {
    return _handleRequest(() async {
      final headers = await _getHeaders();
      return http.delete(
        Uri.parse("$_baseUrl/api/favorite/$quizId"),
        headers: headers,
      );
    });
  }

  static Future<List<dynamic>> getFavorites() async {
    return _handleRequest(() async {
      final headers = await _getHeaders();
      return http.get(Uri.parse("$_baseUrl/api/favorite"), headers: headers);
    });
  }

  static Future<bool> isFavorited(String quizId) async {
    final dynamic result = await _handleRequest(() async {
      final headers = await _getHeaders();
      return http.get(
        Uri.parse("$_baseUrl/api/favorite/check/$quizId"),
        headers: headers,
      );
    });
    return result["isFavorited"] as bool;
  }

  static Future<void> followUser(String userId) async {
    return _handleRequest(() async {
      final headers = await _getHeaders();
      return http.post(
        Uri.parse("$_baseUrl/api/follow"),
        headers: headers,
        body: jsonEncode({"followingId": userId}),
      );
    });
  }

  static Future<void> unfollowUser(String userId) async {
    return _handleRequest(() async {
      final headers = await _getHeaders();
      return http.delete(
        Uri.parse("$_baseUrl/api/follow/$userId"),
        headers: headers,
      );
    });
  }

  static Future<bool> isFollowing(String userId) async {
    final dynamic result = await _handleRequest(() async {
      final headers = await _getHeaders();
      return http.get(
        Uri.parse("$_baseUrl/api/follow/check/$userId"),
        headers: headers,
      );
    });
    return result["isFollowing"] as bool;
  }

  static Future<List<dynamic>> getFollowers(String userId) async {
    return _handleRequest(() async {
      final headers = await _getHeaders();
      return http.get(
        Uri.parse("$_baseUrl/api/follow/followers/$userId"),
        headers: headers,
      );
    });
  }

  static Future<List<dynamic>> getFollowing(String userId) async {
    return _handleRequest(() async {
      final headers = await _getHeaders();
      return http.get(
        Uri.parse("$_baseUrl/api/follow/following/$userId"),
        headers: headers,
      );
    });
  }

  static Future<List<dynamic>> getUserCollections(String userId) async {
    return _handleRequest(() async {
      final headers = await _getHeaders();
      return http.get(
        Uri.parse("$_baseUrl/api/collection/user/$userId"),
        headers: headers,
      );
    });
  }

  static Future<dynamic> getCollection(String collectionId) async {
    return _handleRequest(() async {
      final headers = await _getHeaders();
      return http.get(
        Uri.parse("$_baseUrl/api/collection/$collectionId"),
        headers: headers,
      );
    });
  }

  static Future<dynamic> createCollection(
    String title,
    String? description,
    bool isPublic,
  ) async {
    return _handleRequest(() async {
      final headers = await _getHeaders();
      return http.post(
        Uri.parse("$_baseUrl/api/collection"),
        headers: headers,
        body: jsonEncode({
          "title": title,
          "description": description,
          "isPublic": isPublic,
        }),
      );
    });
  }

  static Future<void> addQuizToCollection(
    String collectionId,
    String quizId,
  ) async {
    return _handleRequest(() async {
      final headers = await _getHeaders();
      return http.post(
        Uri.parse("$_baseUrl/api/collection/$collectionId/quiz"),
        headers: headers,
        body: jsonEncode({"quizId": quizId}),
      );
    });
  }

  static Future<void> removeQuizFromCollection(
    String collectionId,
    String quizId,
  ) async {
    return _handleRequest(() async {
      final headers = await _getHeaders();
      return http.delete(
        Uri.parse("$_baseUrl/api/collection/$collectionId/quiz/$quizId"),
        headers: headers,
      );
    });
  }

  static Future<void> deleteCollection(String collectionId) async {
    return _handleRequest(() async {
      final headers = await _getHeaders();
      return http.delete(
        Uri.parse("$_baseUrl/api/collection/$collectionId"),
        headers: headers,
      );
    });
  }

  static Future<dynamic> createSession(
    String quizId, {
    String? title,
    int? estimatedMinutes,
  }) async {
    return _handleRequest(() async {
      final headers = await _getHeaders();
      return http.post(
        Uri.parse("$_baseUrl/api/session"),
        headers: headers,
        body: jsonEncode({
          "quizId": quizId,
          "title": title,
          "estimatedMinutes": estimatedMinutes,
        }),
      );
    });
  }

  static Future<dynamic> getSessionByCode(String code) async {
    return _handleRequest(() async {
      final headers = await _getHeaders();
      return http.get(
        Uri.parse("$_baseUrl/api/session/code/$code"),
        headers: headers,
      );
    });
  }

  static Future<List<dynamic>> getHostedSessions(String userId) async {
    return _handleRequest(() async {
      final headers = await _getHeaders();
      return http.get(
        Uri.parse("$_baseUrl/api/session/user/$userId/hosted"),
        headers: headers,
      );
    });
  }

  static Future<List<dynamic>> getPlayedSessions(String userId) async {
    return _handleRequest(() async {
      final headers = await _getHeaders();
      return http.get(
        Uri.parse("$_baseUrl/api/session/user/$userId/played"),
        headers: headers,
      );
    });
  }

  static Future<List<dynamic>> getFeedPosts({
    int limit = 20,
    int offset = 0,
  }) async {
    return _handleRequest(() async {
      final headers = await _getHeaders();
      return http.get(
        Uri.parse("$_baseUrl/api/social/posts?limit=$limit&offset=$offset"),
        headers: headers,
      );
    });
  }

  static Future<List<dynamic>> getUserPosts(String userId) async {
    return _handleRequest(() async {
      final headers = await _getHeaders();
      return http.get(
        Uri.parse("$_baseUrl/api/social/user/$userId/posts"),
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
    return _handleRequest(() async {
      final headers = await _getHeaders();
      final body = <String, dynamic>{'text': text, 'postType': postType};

      if (imageUrl != null) body['imageUrl'] = imageUrl;
      if (questionType != null) body['questionType'] = questionType;
      if (questionText != null) body['questionText'] = questionText;
      if (questionData != null) body['questionData'] = questionData;

      return http.post(
        Uri.parse("$_baseUrl/api/social/posts"),
        headers: headers,
        body: jsonEncode(body),
      );
    });
  }

  static Future<dynamic> submitPostAnswer(String postId, dynamic answer) async {
    return _handleRequest(() async {
      final headers = await _getHeaders();
      return http.post(
        Uri.parse("$_baseUrl/api/social/posts/$postId/answer"),
        headers: headers,
        body: jsonEncode({"answer": answer}),
      );
    });
  }

  static Future<void> deletePost(String postId) async {
    return _handleRequest(() async {
      final headers = await _getHeaders();
      return http.delete(
        Uri.parse("$_baseUrl/api/social/posts/$postId"),
        headers: headers,
      );
    });
  }

  static Future<void> likePost(String postId) async {
    return _handleRequest(() async {
      final headers = await _getHeaders();
      return http.post(
        Uri.parse("$_baseUrl/api/social/posts/$postId/like"),
        headers: headers,
      );
    });
  }

  static Future<void> unlikePost(String postId) async {
    return _handleRequest(() async {
      final headers = await _getHeaders();
      return http.delete(
        Uri.parse("$_baseUrl/api/social/posts/$postId/like"),
        headers: headers,
      );
    });
  }

  static Future<List<dynamic>> getPostComments(String postId) async {
    return _handleRequest(() async {
      final headers = await _getHeaders();
      return http.get(
        Uri.parse("$_baseUrl/api/social/posts/$postId/comments"),
        headers: headers,
      );
    });
  }

  static Future<void> addComment(String postId, String content) async {
    return _handleRequest(() async {
      final headers = await _getHeaders();
      return http.post(
        Uri.parse("$_baseUrl/api/social/posts/$postId/comments"),
        headers: headers,
        body: jsonEncode({"content": content}),
      );
    });
  }

  static Future<void> deleteComment(String commentId) async {
    return _handleRequest(() async {
      final headers = await _getHeaders();
      return http.delete(
        Uri.parse("$_baseUrl/api/social/comments/$commentId"),
        headers: headers,
      );
    });
  }

  static Future<dynamic> getPost(String postId) async {
    return _handleRequest(() async {
      final headers = await _getHeaders();
      return http.get(
        Uri.parse("$_baseUrl/api/social/posts/$postId"),
        headers: headers,
      );
    });
  }

  static Future<void> likeComment(String commentId) async {
    return _handleRequest(() async {
      final headers = await _getHeaders();
      return http.post(
        Uri.parse("$_baseUrl/api/social/comments/$commentId/like"),
        headers: headers,
      );
    });
  }

  static Future<void> unlikeComment(String commentId) async {
    return _handleRequest(() async {
      final headers = await _getHeaders();
      return http.delete(
        Uri.parse("$_baseUrl/api/social/comments/$commentId/like"),
        headers: headers,
      );
    });
  }

  static Future<Map<String, dynamic>> search(String query) async {
    return _handleRequest(() async {
      final headers = await _getHeaders();
      return http.get(
        Uri.parse("$_baseUrl/api/search?q=${Uri.encodeComponent(query)}"),
        headers: headers,
      );
    });
  }

  static Future<List<dynamic>> searchQuizzes(
    String query, {
    String? category,
  }) async {
    return _handleRequest(() async {
      final headers = await _getHeaders();
      final categoryParam = category != null
          ? "&category=${Uri.encodeComponent(category)}"
          : "";
      return http.get(
        Uri.parse(
          "$_baseUrl/api/search/quizzes?q=${Uri.encodeComponent(query)}$categoryParam",
        ),
        headers: headers,
      );
    });
  }

  static Future<List<dynamic>> searchUsers(String query) async {
    return _handleRequest(() async {
      final headers = await _getHeaders();
      return http.get(
        Uri.parse("$_baseUrl/api/search/users?q=${Uri.encodeComponent(query)}"),
        headers: headers,
      );
    });
  }

  static Future<List<dynamic>> getNotifications({
    bool unreadOnly = false,
  }) async {
    return _handleRequest(() async {
      final headers = await _getHeaders();
      final unreadParam = unreadOnly ? "?unread=true" : "";
      return http.get(
        Uri.parse("$_baseUrl/api/notification$unreadParam"),
        headers: headers,
      );
    });
  }

  static Future<int> getUnreadCount() async {
    final dynamic result = await _handleRequest(() async {
      final headers = await _getHeaders();
      return http.get(
        Uri.parse("$_baseUrl/api/notification/unread/count"),
        headers: headers,
      );
    });
    return result["count"] as int;
  }

  static Future<void> markAsRead(String notificationId) async {
    return _handleRequest(() async {
      final headers = await _getHeaders();
      return http.patch(
        Uri.parse("$_baseUrl/api/notification/$notificationId/read"),
        headers: headers,
      );
    });
  }

  static Future<void> markAllAsRead() async {
    return _handleRequest(() async {
      final headers = await _getHeaders();
      return http.patch(
        Uri.parse("$_baseUrl/api/notification/read-all"),
        headers: headers,
      );
    });
  }

  static Future<void> deleteNotification(String notificationId) async {
    return _handleRequest(() async {
      final headers = await _getHeaders();
      return http.delete(
        Uri.parse("$_baseUrl/api/notification/$notificationId"),
        headers: headers,
      );
    });
  }

  static Future<Map<String, dynamic>> fetchQuestionWithTiming(
    String sessionId,
    int questionIndex,
  ) async {
    return _handleRequest(() async {
      final headers = await _getHeaders();
      return http.get(
        Uri.parse("$_baseUrl/api/session/$sessionId/question/$questionIndex"),
        headers: headers,
      );
    });
  }

  static Future<Map<String, dynamic>> submitAnswerWithValidation(
    String sessionId,
    String questionId,
    String answer,
  ) async {
    return _handleRequest(() async {
      final headers = await _getHeaders();
      return http.post(
        Uri.parse("$_baseUrl/api/session/$sessionId/answer"),
        headers: headers,
        body: jsonEncode({"questionId": questionId, "answer": answer}),
      );
    });
  }
}
