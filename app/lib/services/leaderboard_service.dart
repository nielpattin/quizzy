import "http_client.dart";
import "package:http/http.dart" as http;

class LeaderboardService {
  static Future<Map<String, dynamic>> getCoinLeaderboard({
    int limit = 100,
  }) async {
    return HttpClient.handleRequest(() async {
      final headers = await HttpClient.getHeaders();
      return http.get(
        Uri.parse("${HttpClient.baseUrl}/api/leaderboard/coins?limit=$limit"),
        headers: headers,
      );
    });
  }
}
