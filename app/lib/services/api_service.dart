import "dart:convert";
import "package:http/http.dart" as http;
import "http_client.dart";
import "social_service.dart";
import "quiz_service.dart";

export "http_client.dart";
export "upload_service.dart";
export "quiz_service.dart";
export "social_service.dart";

class ApiService {
  static Future<void> favoriteQuiz(String quizId) async {
    return HttpClient.handleRequest(() async {
      final headers = await HttpClient.getHeaders();
      return http.post(
        Uri.parse("${HttpClient.baseUrl}/api/favorite"),
        headers: headers,
        body: jsonEncode({"quizId": quizId}),
      );
    });
  }

  static Future<void> unfavoriteQuiz(String quizId) async {
    return HttpClient.handleRequest(() async {
      final headers = await HttpClient.getHeaders();
      return http.delete(
        Uri.parse("${HttpClient.baseUrl}/api/favorite/$quizId"),
        headers: headers,
      );
    });
  }

  static Future<List<dynamic>> getFavorites() async {
    return HttpClient.handleRequest(() async {
      final headers = await HttpClient.getHeaders();
      return http.get(
        Uri.parse("${HttpClient.baseUrl}/api/favorite"),
        headers: headers,
      );
    });
  }

  static Future<bool> isFavorited(String quizId) async {
    final dynamic result = await HttpClient.handleRequest(() async {
      final headers = await HttpClient.getHeaders();
      return http.get(
        Uri.parse("${HttpClient.baseUrl}/api/favorite/check/$quizId"),
        headers: headers,
      );
    });
    return result["isFavorited"] as bool;
  }

  static Future<void> followUser(String userId) async {
    return HttpClient.handleRequest(() async {
      final headers = await HttpClient.getHeaders();
      return http.post(
        Uri.parse("${HttpClient.baseUrl}/api/follow"),
        headers: headers,
        body: jsonEncode({"followingId": userId}),
      );
    });
  }

  static Future<void> unfollowUser(String userId) async {
    return HttpClient.handleRequest(() async {
      final headers = await HttpClient.getHeaders();
      return http.delete(
        Uri.parse("${HttpClient.baseUrl}/api/follow/$userId"),
        headers: headers,
      );
    });
  }

  static Future<bool> isFollowing(String userId) async {
    final dynamic result = await HttpClient.handleRequest(() async {
      final headers = await HttpClient.getHeaders();
      return http.get(
        Uri.parse("${HttpClient.baseUrl}/api/follow/check/$userId"),
        headers: headers,
      );
    });
    return result["isFollowing"] as bool;
  }

  static Future<List<dynamic>> getFollowers(String userId) async {
    return HttpClient.handleRequest(() async {
      final headers = await HttpClient.getHeaders();
      return http.get(
        Uri.parse("${HttpClient.baseUrl}/api/follow/followers/$userId"),
        headers: headers,
      );
    });
  }

  static Future<List<dynamic>> getFollowing(String userId) async {
    return HttpClient.handleRequest(() async {
      final headers = await HttpClient.getHeaders();
      return http.get(
        Uri.parse("${HttpClient.baseUrl}/api/follow/following/$userId"),
        headers: headers,
      );
    });
  }

  static Future<List<dynamic>> getUserCollections(String userId) async {
    return HttpClient.handleRequest(() async {
      final headers = await HttpClient.getHeaders();
      return http.get(
        Uri.parse("${HttpClient.baseUrl}/api/collection/user/$userId"),
        headers: headers,
      );
    });
  }

  static Future<dynamic> getCollection(String collectionId) async {
    return HttpClient.handleRequest(() async {
      final headers = await HttpClient.getHeaders();
      return http.get(
        Uri.parse("${HttpClient.baseUrl}/api/collection/$collectionId"),
        headers: headers,
      );
    });
  }

  static Future<dynamic> createCollection(
    String title,
    String? description,
    bool isPublic,
    String? imageUrl,
  ) async {
    return HttpClient.handleRequest(() async {
      final headers = await HttpClient.getHeaders();
      return http.post(
        Uri.parse("${HttpClient.baseUrl}/api/collection"),
        headers: headers,
        body: jsonEncode({
          "title": title,
          "description": description,
          "isPublic": isPublic,
          "imageUrl": imageUrl,
        }),
      );
    });
  }

  static Future<void> addQuizToCollection(
    String collectionId,
    String quizId,
  ) async {
    return HttpClient.handleRequest(() async {
      final headers = await HttpClient.getHeaders();
      return http.post(
        Uri.parse("${HttpClient.baseUrl}/api/collection/$collectionId/quiz"),
        headers: headers,
        body: jsonEncode({"quizId": quizId}),
      );
    });
  }

  static Future<void> removeQuizFromCollection(
    String collectionId,
    String quizId,
  ) async {
    return HttpClient.handleRequest(() async {
      final headers = await HttpClient.getHeaders();
      return http.delete(
        Uri.parse(
          "${HttpClient.baseUrl}/api/collection/$collectionId/quiz/$quizId",
        ),
        headers: headers,
      );
    });
  }

  static Future<void> deleteCollection(String collectionId) async {
    return HttpClient.handleRequest(() async {
      final headers = await HttpClient.getHeaders();
      return http.delete(
        Uri.parse("${HttpClient.baseUrl}/api/collection/$collectionId"),
        headers: headers,
      );
    });
  }

  static Future<dynamic> createSession(
    String quizId, {
    String? title,
    int? estimatedMinutes,
  }) async {
    return HttpClient.handleRequest(() async {
      final headers = await HttpClient.getHeaders();
      return http.post(
        Uri.parse("${HttpClient.baseUrl}/api/session"),
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
    return HttpClient.handleRequest(() async {
      final headers = await HttpClient.getHeaders();
      return http.get(
        Uri.parse("${HttpClient.baseUrl}/api/session/code/$code"),
        headers: headers,
      );
    });
  }

  static Future<List<dynamic>> getHostedSessions(String userId) async {
    return HttpClient.handleRequest(() async {
      final headers = await HttpClient.getHeaders();
      return http.get(
        Uri.parse("${HttpClient.baseUrl}/api/session/user/$userId/hosted"),
        headers: headers,
      );
    });
  }

  static Future<List<dynamic>> getPlayedSessions(String userId) async {
    return HttpClient.handleRequest(() async {
      final headers = await HttpClient.getHeaders();
      return http.get(
        Uri.parse("${HttpClient.baseUrl}/api/session/user/$userId/played"),
        headers: headers,
      );
    });
  }

  static Future<dynamic> getUserProfile(String userId) async {
    return HttpClient.handleRequest(() async {
      final headers = await HttpClient.getHeaders();
      return http.get(
        Uri.parse("${HttpClient.baseUrl}/api/user/profile/$userId"),
        headers: headers,
      );
    });
  }

  static Future<dynamic> getCurrentUserProfile() async {
    return HttpClient.handleRequest(() async {
      final headers = await HttpClient.getHeaders();
      return http.get(
        Uri.parse("${HttpClient.baseUrl}/api/user/profile"),
        headers: headers,
      );
    });
  }

  static Future<List<dynamic>> getCurrentUserQuizzes() async {
    return HttpClient.handleRequest(() async {
      final headers = await HttpClient.getHeaders();
      return http.get(
        Uri.parse("${HttpClient.baseUrl}/api/user/quizzes"),
        headers: headers,
      );
    });
  }

  static Future<List<dynamic>> getUserSessions() async {
    return HttpClient.handleRequest(() async {
      final headers = await HttpClient.getHeaders();
      return http.get(
        Uri.parse("${HttpClient.baseUrl}/api/user/sessions"),
        headers: headers,
      );
    });
  }

  static Future<List<dynamic>> getUserPostsForProfile() async {
    return HttpClient.handleRequest(() async {
      final headers = await HttpClient.getHeaders();
      return http.get(
        Uri.parse("${HttpClient.baseUrl}/api/user/posts"),
        headers: headers,
      );
    });
  }

  static Future<void> updateProfile({
    String? fullName,
    String? username,
    String? bio,
  }) async {
    return HttpClient.handleRequest(() async {
      final headers = await HttpClient.getHeaders();
      final body = <String, dynamic>{};
      if (fullName != null) body['fullName'] = fullName;
      if (username != null) body['username'] = username;
      if (bio != null) body['bio'] = bio;

      return http.put(
        Uri.parse("${HttpClient.baseUrl}/api/user/profile"),
        headers: headers,
        body: jsonEncode(body),
      );
    });
  }

  static Future<Map<String, dynamic>> search(String query) async {
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

  static Future<List<dynamic>> getNotifications({
    bool unreadOnly = false,
  }) async {
    return HttpClient.handleRequest(() async {
      final headers = await HttpClient.getHeaders();
      final unreadParam = unreadOnly ? "?unread=true" : "";
      return http.get(
        Uri.parse("${HttpClient.baseUrl}/api/notification$unreadParam"),
        headers: headers,
      );
    });
  }

  static Future<int> getUnreadCount() async {
    final dynamic result = await HttpClient.handleRequest(() async {
      final headers = await HttpClient.getHeaders();
      return http.get(
        Uri.parse("${HttpClient.baseUrl}/api/notification/unread/count"),
        headers: headers,
      );
    });
    return result["count"] as int;
  }

  static Future<void> markAsRead(String notificationId) async {
    return HttpClient.handleRequest(() async {
      final headers = await HttpClient.getHeaders();
      return http.patch(
        Uri.parse(
          "${HttpClient.baseUrl}/api/notification/$notificationId/read",
        ),
        headers: headers,
      );
    });
  }

  static Future<void> markAllAsRead() async {
    return HttpClient.handleRequest(() async {
      final headers = await HttpClient.getHeaders();
      return http.patch(
        Uri.parse("${HttpClient.baseUrl}/api/notification/read-all"),
        headers: headers,
      );
    });
  }

  static Future<void> deleteNotification(String notificationId) async {
    return HttpClient.handleRequest(() async {
      final headers = await HttpClient.getHeaders();
      return http.delete(
        Uri.parse("${HttpClient.baseUrl}/api/notification/$notificationId"),
        headers: headers,
      );
    });
  }

  static Future<Map<String, dynamic>> fetchQuestionWithTiming(
    String sessionId,
    int questionIndex,
  ) async {
    return HttpClient.handleRequest(() async {
      final headers = await HttpClient.getHeaders();
      return http.get(
        Uri.parse(
          "${HttpClient.baseUrl}/api/session/$sessionId/question/$questionIndex",
        ),
        headers: headers,
      );
    });
  }

  static Future<Map<String, dynamic>> submitAnswerWithValidation(
    String sessionId,
    String questionId,
    String answer,
  ) async {
    return HttpClient.handleRequest(() async {
      final headers = await HttpClient.getHeaders();
      return http.post(
        Uri.parse("${HttpClient.baseUrl}/api/session/$sessionId/answer"),
        headers: headers,
        body: jsonEncode({"questionId": questionId, "answer": answer}),
      );
    });
  }

  static Future<List<dynamic>> getFeedPosts({
    int limit = 20,
    int offset = 0,
  }) async {
    return SocialService.getFeedPosts(limit: limit, offset: offset);
  }

  static Future<List<dynamic>> getUserPosts(String userId) async {
    return SocialService.getUserPosts(userId);
  }

  static Future<dynamic> createPost(
    String text, {
    String postType = 'text',
    String? imageUrl,
    String? questionType,
    String? questionText,
    Map<String, dynamic>? questionData,
  }) async {
    return SocialService.createPost(
      text,
      postType: postType,
      imageUrl: imageUrl,
      questionType: questionType,
      questionText: questionText,
      questionData: questionData,
    );
  }

  static Future<dynamic> submitPostAnswer(String postId, dynamic answer) async {
    return SocialService.submitPostAnswer(postId, answer);
  }

  static Future<void> deletePost(String postId) async {
    return SocialService.deletePost(postId);
  }

  static Future<void> likePost(String postId) async {
    return SocialService.likePost(postId);
  }

  static Future<void> unlikePost(String postId) async {
    return SocialService.unlikePost(postId);
  }

  static Future<List<dynamic>> getPostComments(String postId) async {
    return SocialService.getPostComments(postId);
  }

  static Future<void> addComment(String postId, String content) async {
    return SocialService.addComment(postId, content);
  }

  static Future<void> deleteComment(String commentId) async {
    return SocialService.deleteComment(commentId);
  }

  static Future<dynamic> getPost(String postId) async {
    return SocialService.getPost(postId);
  }

  static Future<void> likeComment(String commentId) async {
    return SocialService.likeComment(commentId);
  }

  static Future<void> unlikeComment(String commentId) async {
    return SocialService.unlikeComment(commentId);
  }

  static Future<List<dynamic>> getFeaturedQuizzes() async {
    return QuizService.getFeaturedQuizzes();
  }

  static Future<List<dynamic>> getTrendingQuizzes() async {
    return QuizService.getTrendingQuizzes();
  }

  static Future<List<dynamic>> getCategoryQuizzes(String category) async {
    return QuizService.getCategoryQuizzes(category);
  }

  static Future<List<dynamic>> getUserQuizzes(String userId) async {
    return QuizService.getUserQuizzes(userId);
  }

  static Future<dynamic> getQuiz(String quizId) async {
    return QuizService.getQuiz(quizId);
  }

  static Future<void> deleteQuiz(String quizId) async {
    return QuizService.deleteQuiz(quizId);
  }
}
