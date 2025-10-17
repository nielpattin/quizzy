import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quizzy/pages/library/models/quiz.dart';
import 'package:quizzy/pages/library/models/collection.dart';
import 'package:quizzy/pages/library/models/game_session.dart';

void main() {
  group('Quiz Model Tests', () {
    test('should parse quiz from API response', () {
      final json = {
        "id": "quiz-123",
        "title": "Test Quiz",
        "questionCount": 10,
        "playCount": 100,
        "isPublic": true,
      };

      final quiz = Quiz.fromJson(json, [Colors.blue, Colors.purple]);

      expect(quiz.id, "quiz-123");
      expect(quiz.title, "Test Quiz");
      expect(quiz.questions, 10);
      expect(quiz.plays, 100);
    });

    test('should handle missing fields with defaults', () {
      final json = {"id": "quiz-123", "title": "Test Quiz"};

      final quiz = Quiz.fromJson(json, [Colors.blue]);

      expect(quiz.id, "quiz-123");
      expect(quiz.title, "Test Quiz");
      expect(quiz.questions, 0);
      expect(quiz.plays, 0);
      expect(quiz.timeAgo, "Recently");
    });

    test('should handle both playCount and plays fields', () {
      final json1 = {"id": "quiz-1", "title": "Quiz 1", "playCount": 50};

      final json2 = {"id": "quiz-2", "title": "Quiz 2", "plays": 100};

      final quiz1 = Quiz.fromJson(json1, [Colors.red]);
      final quiz2 = Quiz.fromJson(json2, [Colors.green]);

      expect(quiz1.plays, 50);
      expect(quiz2.plays, 100);
    });
  });

  group('Collection Model Tests', () {
    test('should parse collection from API response', () {
      final json = {
        "id": "col-123",
        "title": "Test Collection",
        "quizCount": 5,
      };

      final collection = Collection.fromJson(json, [Colors.orange]);

      expect(collection.id, "col-123");
      expect(collection.title, "Test Collection");
      expect(collection.quizCount, 5);
    });

    test('should handle zero quiz count', () {
      final json = {
        "id": "col-empty",
        "title": "Empty Collection",
        "quizCount": 0,
      };

      final collection = Collection.fromJson(json, [Colors.grey]);

      expect(collection.quizCount, 0);
    });
  });

  group('GameSession Model Tests', () {
    test('should parse session from API response', () {
      final json = {
        "id": "session-123",
        "title": "Test Session",
        "estimatedMinutes": 30,
        "isLive": true,
        "createdAt": "2024-01-01T00:00:00Z",
      };

      final session = GameSession.fromJson(json, [Colors.blue]);

      expect(session.id, "session-123");
      expect(session.title, "Test Session");
      expect(session.isLive, true);
    });

    test('should handle missing optional fields', () {
      final json = {"id": "session-123", "title": "Test Session"};

      final session = GameSession.fromJson(json, [Colors.green]);

      expect(session.id, "session-123");
      expect(session.title, "Test Session");
      expect(session.isLive, false);
      expect(session.joined, 0);
    });

    test('should format estimated minutes as length', () {
      final json = {
        "id": "session-123",
        "title": "Test Session",
        "estimatedMinutes": 45,
      };

      final session = GameSession.fromJson(json, [Colors.red]);

      expect(session.length, "45 min");
    });

    test('should handle participants list', () {
      final json = {
        "id": "session-123",
        "title": "Test Session",
        "participants": [
          {"id": "user-1"},
          {"id": "user-2"},
          {"id": "user-3"},
        ],
      };

      final session = GameSession.fromJson(json, [Colors.purple]);

      expect(session.joined, 3);
    });
  });

  group('Model Serialization Tests', () {
    test('quiz should serialize to JSON', () {
      final quiz = Quiz(
        id: "quiz-123",
        title: "Test Quiz",
        timeAgo: "1 day ago",
        plays: 100,
        questions: 10,
        gradient: [Colors.blue, Colors.purple],
      );

      final json = quiz.toJson();

      expect(json["id"], "quiz-123");
      expect(json["title"], "Test Quiz");
      expect(json["plays"], 100);
      expect(json["questions"], 10);
    });

    test('collection should serialize to JSON', () {
      final collection = Collection(
        id: "col-123",
        title: "Test Collection",
        quizCount: 5,
        gradient: [Colors.orange],
      );

      final json = collection.toJson();

      expect(json["id"], "col-123");
      expect(json["title"], "Test Collection");
      expect(json["quizCount"], 5);
    });
  });
}
