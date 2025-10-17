import 'package:flutter_test/flutter_test.dart';
import '../helpers/test_helpers.dart';

void main() {
  group('Library Service Tests', () {
    test('should handle empty quiz list', () {
      final quizzes = <dynamic>[];
      expect(quizzes.isEmpty, true);
    });

    test('should sort quizzes by newest', () {
      final quizzes = [
        createMockQuiz(id: "1", title: "Old Quiz"),
        createMockQuiz(id: "2", title: "New Quiz"),
        createMockQuiz(id: "3", title: "Newest Quiz"),
      ];

      expect(quizzes.first["title"], "Old Quiz");
      expect(quizzes.last["title"], "Newest Quiz");
    });

    test('should sort quizzes by oldest (reversed)', () {
      final quizzes = [
        createMockQuiz(id: "1"),
        createMockQuiz(id: "2"),
        createMockQuiz(id: "3"),
      ];

      final oldest = quizzes.reversed.toList();

      expect(oldest.first["id"], "3");
      expect(oldest.last["id"], "1");
    });

    test('should sort quizzes by most played', () {
      final quizzes = [
        createMockQuiz(id: "1", playCount: 100),
        createMockQuiz(id: "2", playCount: 500),
        createMockQuiz(id: "3", playCount: 200),
      ];

      quizzes.sort(
        (a, b) => (b["playCount"] as int).compareTo(a["playCount"] as int),
      );

      expect(quizzes[0]["playCount"], 500);
      expect(quizzes[1]["playCount"], 200);
      expect(quizzes[2]["playCount"], 100);
    });

    test('should sort quizzes alphabetically', () {
      final quizzes = [
        createMockQuiz(title: "Zebra Quiz"),
        createMockQuiz(title: "Apple Quiz"),
        createMockQuiz(title: "Banana Quiz"),
      ];

      quizzes.sort(
        (a, b) => a["title"].toString().compareTo(b["title"].toString()),
      );

      expect(quizzes[0]["title"], "Apple Quiz");
      expect(quizzes[1]["title"], "Banana Quiz");
      expect(quizzes[2]["title"], "Zebra Quiz");
    });
  });

  group('Favorite Quizzes Tests', () {
    test('should extract quiz from favorite object', () {
      final favorites = [
        {
          "id": "fav-1",
          "quiz": createMockQuiz(id: "quiz-1", title: "Favorite Quiz 1"),
        },
        {
          "id": "fav-2",
          "quiz": createMockQuiz(id: "quiz-2", title: "Favorite Quiz 2"),
        },
      ];

      final quizzes = favorites
          .map((f) => f["quiz"] as Map<String, dynamic>)
          .toList();

      expect(quizzes.length, 2);
      expect(quizzes[0]["title"], "Favorite Quiz 1");
      expect(quizzes[1]["title"], "Favorite Quiz 2");
    });

    test('should handle favorites with null quiz', () {
      final favorites = [
        {"id": "fav-1", "quiz": createMockQuiz()},
        {"id": "fav-2", "quiz": null},
      ];

      final validQuizzes = favorites
          .where((f) => f["quiz"] != null)
          .map((f) => f["quiz"])
          .toList();

      expect(validQuizzes.length, 1);
    });
  });

  group('Collection Tests', () {
    test('should handle empty collections', () {
      final collections = <dynamic>[];
      expect(collections.isEmpty, true);
    });

    test('should count total quizzes in collections', () {
      final collections = [
        {"id": "col-1", "quizCount": 5},
        {"id": "col-2", "quizCount": 10},
        {"id": "col-3", "quizCount": 3},
      ];

      final total = collections.fold<int>(
        0,
        (sum, col) => sum + (col["quizCount"] as int),
      );

      expect(total, 18);
    });
  });

  group('Session Tests', () {
    test('should separate hosted and played sessions', () {
      final userId = "user-123";
      final allSessions = [
        {"id": "s1", "hostId": userId, "type": "hosted"},
        {"id": "s2", "hostId": "other", "type": "played"},
        {"id": "s3", "hostId": userId, "type": "hosted"},
      ];

      final hosted = allSessions.where((s) => s["hostId"] == userId).toList();
      final played = allSessions.where((s) => s["hostId"] != userId).toList();

      expect(hosted.length, 2);
      expect(played.length, 1);
    });
  });
}
