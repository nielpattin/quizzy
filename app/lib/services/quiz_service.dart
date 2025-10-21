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

  static Future<void> deleteQuiz(String quizId) async {
    return HttpClient.handleRequest(() async {
      final headers = await HttpClient.getHeaders();
      return http.delete(
        Uri.parse("${HttpClient.baseUrl}/api/quiz/$quizId"),
        headers: headers,
      );
    });
  }
}
