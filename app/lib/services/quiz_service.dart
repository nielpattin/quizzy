import "dart:convert";
import "package:http/http.dart" as http;
import "http_client.dart";

class QuizService {
  static Future<List<dynamic>> getFeaturedQuizzes() async {
    return HttpClient.handleRequest(() async {
      final headers = await HttpClient.getHeaders();
      return http.get(
        Uri.parse("${HttpClient.baseUrl}/api/quiz/featured"),
        headers: headers,
      );
    });
  }

  static Future<List<dynamic>> getTrendingQuizzes() async {
    return HttpClient.handleRequest(() async {
      final headers = await HttpClient.getHeaders();
      return http.get(
        Uri.parse("${HttpClient.baseUrl}/api/quiz/trending"),
        headers: headers,
      );
    });
  }

  static Future<List<dynamic>> getCategoryQuizzes(String category) async {
    return HttpClient.handleRequest(() async {
      final headers = await HttpClient.getHeaders();
      return http.get(
        Uri.parse("${HttpClient.baseUrl}/api/quiz/category/$category"),
        headers: headers,
      );
    });
  }

  static Future<List<dynamic>> getUserQuizzes(String userId) async {
    return HttpClient.handleRequest(() async {
      final headers = await HttpClient.getHeaders();
      return http.get(
        Uri.parse("${HttpClient.baseUrl}/api/quiz/user/$userId"),
        headers: headers,
      );
    });
  }

  static Future<dynamic> getQuiz(String quizId) async {
    return HttpClient.handleRequest(() async {
      final headers = await HttpClient.getHeaders();
      return http.get(
        Uri.parse("${HttpClient.baseUrl}/api/quiz/$quizId"),
        headers: headers,
      );
    });
  }

  static Future<List<dynamic>> getQuizQuestions(String quizId) async {
    return HttpClient.handleRequest(() async {
      final headers = await HttpClient.getHeaders();
      return http.get(
        Uri.parse("${HttpClient.baseUrl}/api/quiz/$quizId/questions"),
        headers: headers,
      );
    });
  }

  static Future<dynamic> updateQuiz(
    String quizId, {
    required String title,
    String? description,
    String? categoryId,
    String? imageUrl,
    String? collectionId,
    required bool isPublic,
    required bool questionsVisible,
  }) async {
    return HttpClient.handleRequest(() async {
      final headers = await HttpClient.getHeaders();
      return http.put(
        Uri.parse("${HttpClient.baseUrl}/api/quiz/$quizId"),
        headers: headers,
        body: jsonEncode({
          "title": title,
          "description": description,
          "categoryId": categoryId,
          "imageUrl": imageUrl,
          "collectionId": collectionId,
          "isPublic": isPublic,
          "questionsVisible": questionsVisible,
        }),
      );
    });
  }

  static Future<void> deleteQuiz(String quizId) async {
    return HttpClient.handleRequest(() async {
      final headers = await HttpClient.getHeaders();
      return http.delete(
        Uri.parse("${HttpClient.baseUrl}/api/quiz/$quizId"),
        headers: headers,
      );
    });
  }

  static Future<void> reorderQuestions(
    String quizId,
    List<Map<String, dynamic>> questionsOrder,
  ) async {
    return HttpClient.handleRequest(() async {
      final headers = await HttpClient.getHeaders();
      return http.put(
        Uri.parse("${HttpClient.baseUrl}/api/question/reorder"),
        headers: headers,
        body: jsonEncode({"quizId": quizId, "questions": questionsOrder}),
      );
    });
  }

  static Future<void> deleteAllQuestions(String quizId) async {
    return HttpClient.handleRequest(() async {
      final headers = await HttpClient.getHeaders();
      return http.delete(
        Uri.parse("${HttpClient.baseUrl}/api/quiz/$quizId/questions"),
        headers: headers,
      );
    });
  }

  // Get user's coin balance
  static Future<int> getUserCoins() async {
    final response = await HttpClient.handleRequest(() async {
      final headers = await HttpClient.getHeaders();
      return http.get(
        Uri.parse("${HttpClient.baseUrl}/api/user/coins"),
        headers: headers,
      );
    });
    return response['coins'] as int;
  }

  // Claim quiz reward and update coins
  static Future<Map<String, dynamic>> claimQuizReward({
    required String sessionId,
    required int correctAnswers,
    required int totalQuestions,
    required int streak,
  }) async {
    return HttpClient.handleRequest(() async {
      final headers = await HttpClient.getHeaders();
      return http.post(
        Uri.parse("${HttpClient.baseUrl}/api/session/$sessionId/reward"),
        headers: headers,
        body: jsonEncode({
          "correctAnswers": correctAnswers,
          "totalQuestions": totalQuestions,
          "streak": streak,
        }),
      );
    });
  }

  // Get coin transaction history
  static Future<List<dynamic>> getCoinTransactions({
    int limit = 50,
    int offset = 0,
  }) async {
    final response = await HttpClient.handleRequest(() async {
      final headers = await HttpClient.getHeaders();
      return http.get(
        Uri.parse(
          "${HttpClient.baseUrl}/api/user/coins/transactions?limit=$limit&offset=$offset",
        ),
        headers: headers,
      );
    });
    return response['transactions'] as List<dynamic>;
  }
}
