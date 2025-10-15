import "dart:convert";
import "package:flutter/foundation.dart";
import "package:flutter_dotenv/flutter_dotenv.dart";
import "package:http/http.dart" as http;

class TestDataService {
  static final String _baseUrl = dotenv.env["SERVER_URL"]!;

  static Future<List<dynamic>> getFeatured() async {
    try {
      final response = await http.get(
        Uri.parse("$_baseUrl/api/test/homepage/featured"),
      );
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      throw Exception("Failed to load featured");
    } catch (e) {
      debugPrint("[TestDataService] Error loading featured: $e");
      rethrow;
    }
  }

  static Future<List<dynamic>> getTopics() async {
    try {
      final response = await http.get(
        Uri.parse("$_baseUrl/api/test/homepage/topics"),
      );
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      throw Exception("Failed to load topics");
    } catch (e) {
      debugPrint("[TestDataService] Error loading topics: $e");
      rethrow;
    }
  }

  static Future<List<dynamic>> getTrending() async {
    try {
      final response = await http.get(
        Uri.parse("$_baseUrl/api/test/homepage/trending"),
      );
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      throw Exception("Failed to load trending");
    } catch (e) {
      debugPrint("[TestDataService] Error loading trending: $e");
      rethrow;
    }
  }

  static Future<List<dynamic>> getContinuePlaying() async {
    try {
      final response = await http.get(
        Uri.parse("$_baseUrl/api/test/homepage/continue-playing"),
      );
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      throw Exception("Failed to load continue playing");
    } catch (e) {
      debugPrint("[TestDataService] Error loading continue playing: $e");
      rethrow;
    }
  }

  static Future<List<dynamic>> getFeed() async {
    try {
      final response = await http.get(Uri.parse("$_baseUrl/api/test/feed"));
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      throw Exception("Failed to load feed");
    } catch (e) {
      debugPrint("[TestDataService] Error loading feed: $e");
      rethrow;
    }
  }

  static Future<List<dynamic>> getCreatedQuizzes() async {
    try {
      final response = await http.get(
        Uri.parse("$_baseUrl/api/test/library/created"),
      );
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      throw Exception("Failed to load created quizzes");
    } catch (e) {
      debugPrint("[TestDataService] Error loading created quizzes: $e");
      rethrow;
    }
  }

  static Future<List<dynamic>> getSavedQuizzes() async {
    try {
      final response = await http.get(
        Uri.parse("$_baseUrl/api/test/library/saved"),
      );
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      throw Exception("Failed to load saved quizzes");
    } catch (e) {
      debugPrint("[TestDataService] Error loading saved quizzes: $e");
      rethrow;
    }
  }

  static Future<List<dynamic>> getCollections() async {
    try {
      final response = await http.get(
        Uri.parse("$_baseUrl/api/test/library/collections"),
      );
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      throw Exception("Failed to load collections");
    } catch (e) {
      debugPrint("[TestDataService] Error loading collections: $e");
      rethrow;
    }
  }

  static Future<List<dynamic>> getSoloPlays() async {
    try {
      final response = await http.get(
        Uri.parse("$_baseUrl/api/test/library/solo-plays"),
      );
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      throw Exception("Failed to load solo plays");
    } catch (e) {
      debugPrint("[TestDataService] Error loading solo plays: $e");
      rethrow;
    }
  }

  static Future<List<dynamic>> getGameSessions() async {
    try {
      final response = await http.get(
        Uri.parse("$_baseUrl/api/test/library/game-sessions"),
      );
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      throw Exception("Failed to load game sessions");
    } catch (e) {
      debugPrint("[TestDataService] Error loading game sessions: $e");
      rethrow;
    }
  }

  static Future<List<dynamic>> getLiveSessions() async {
    try {
      final response = await http.get(
        Uri.parse("$_baseUrl/api/test/sessions/live"),
      );
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      throw Exception("Failed to load live sessions");
    } catch (e) {
      debugPrint("[TestDataService] Error loading live sessions: $e");
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> getProfileStats() async {
    try {
      final response = await http.get(
        Uri.parse("$_baseUrl/api/test/profile/stats"),
      );
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      throw Exception("Failed to load profile stats");
    } catch (e) {
      debugPrint("[TestDataService] Error loading profile stats: $e");
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> getProfileBio() async {
    try {
      final response = await http.get(
        Uri.parse("$_baseUrl/api/test/profile/bio"),
      );
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      throw Exception("Failed to load profile bio");
    } catch (e) {
      debugPrint("[TestDataService] Error loading profile bio: $e");
      rethrow;
    }
  }

  static Future<List<dynamic>> getProfileQuizzes() async {
    try {
      final response = await http.get(
        Uri.parse("$_baseUrl/api/test/profile/quizzes"),
      );
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      throw Exception("Failed to load profile quizzes");
    } catch (e) {
      debugPrint("[TestDataService] Error loading profile quizzes: $e");
      rethrow;
    }
  }

  static Future<List<dynamic>> getProfileSessions() async {
    try {
      final response = await http.get(
        Uri.parse("$_baseUrl/api/test/profile/sessions"),
      );
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      throw Exception("Failed to load profile sessions");
    } catch (e) {
      debugPrint("[TestDataService] Error loading profile sessions: $e");
      rethrow;
    }
  }

  static Future<List<dynamic>> getProfilePosts() async {
    try {
      final response = await http.get(
        Uri.parse("$_baseUrl/api/test/profile/posts"),
      );
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      throw Exception("Failed to load profile posts");
    } catch (e) {
      debugPrint("[TestDataService] Error loading profile posts: $e");
      rethrow;
    }
  }
}
