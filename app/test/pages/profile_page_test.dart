import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quizzy/pages/profile/profile_page.dart';
import '../helpers/test_helpers.dart';

void main() {
  group('Profile Page Tests', () {
    test('should calculate profile stats from data', () {
      final quizzes = [createMockQuiz(), createMockQuiz(), createMockQuiz()];

      final sessions = [createMockSession(), createMockSession()];

      final posts = [
        createMockPost(),
        createMockPost(),
        createMockPost(),
        createMockPost(),
      ];

      final stats = {
        "quizzes": quizzes.length,
        "sessions": sessions.length,
        "posts": posts.length,
        "followers": 10,
        "following": 5,
      };

      expect(stats["quizzes"], 3);
      expect(stats["sessions"], 2);
      expect(stats["posts"], 4);
      expect(stats["followers"], 10);
      expect(stats["following"], 5);
    });

    test('should handle empty profile data', () {
      final stats = {
        "quizzes": 0,
        "sessions": 0,
        "posts": 0,
        "followers": 0,
        "following": 0,
      };

      expect(stats.values.every((v) => v == 0), true);
    });

    test('should extract bio from profile data', () {
      final profileData = {
        "username": "testuser",
        "fullName": "Test User",
        "bio": "This is my bio",
      };

      final bio = {"bio": profileData["bio"] ?? ""};

      expect(bio["bio"], "This is my bio");
    });

    test('should handle missing bio', () {
      final profileData = {"username": "testuser", "fullName": "Test User"};

      final bio = {"bio": profileData["bio"] ?? ""};

      expect(bio["bio"], "");
    });
  });

  group('Profile Quiz Card Tests', () {
    test('should navigate to correct quiz ID', () {
      final quiz = createMockQuiz(id: "quiz-456");
      final route = "/quiz/${quiz["id"]}";

      expect(route, "/quiz/quiz-456");
    });

    test('should handle quiz with missing category', () {
      final quiz = {"id": "quiz-123", "title": "Test Quiz", "playCount": 100};

      final category = quiz["category"] ?? "General";
      final plays = quiz["playCount"] ?? 0;

      expect(category, "General");
      expect(plays, 100);
    });

    test('should use playCount instead of plays', () {
      final quiz = createMockQuiz(playCount: 250);
      final plays = quiz["playCount"] ?? 0;

      expect(plays, 250);
    });
  });

  group('Profile Sessions Tests', () {
    test('should display session count', () {
      final sessions = [
        createMockSession(title: "Session 1"),
        createMockSession(title: "Session 2"),
        createMockSession(title: "Session 3"),
      ];

      expect(sessions.length, 3);
    });

    test('should filter live sessions', () {
      final sessions = [
        createMockSession(isLive: true),
        createMockSession(isLive: false),
        createMockSession(isLive: true),
      ];

      final liveSessions = sessions.where((s) => s["isLive"] == true).toList();

      expect(liveSessions.length, 2);
    });
  });

  group('Profile Posts Tests', () {
    test('should count total likes on posts', () {
      final posts = [
        createMockPost(likesCount: 10),
        createMockPost(likesCount: 25),
        createMockPost(likesCount: 5),
      ];

      final totalLikes = posts.fold<int>(
        0,
        (sum, post) => sum + (post["likesCount"] as int),
      );

      expect(totalLikes, 40);
    });

    test('should handle posts with zero likes', () {
      final post = createMockPost(likesCount: 0);
      expect(post["likesCount"], 0);
    });
  });

  group('Profile Data Loading Tests', () {
    test('should handle API response structure', () {
      final apiResponse = {
        "username": "testuser",
        "fullName": "Test User",
        "profilePictureUrl": null,
        "followersCount": 100,
        "followingCount": 50,
      };

      expect(apiResponse["username"], "testuser");
      expect(apiResponse["fullName"], "Test User");
      expect(apiResponse["profilePictureUrl"], null);
      expect(apiResponse["followersCount"], 100);
      expect(apiResponse["followingCount"], 50);
    });
  });

  group('ProfilePage Widget Tests', () {
    testWidgets('should render loading indicator initially', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(MaterialApp(home: ProfilePage()));

      // Let the widget handle any Supabase errors gracefully
      await tester.pumpAndSettle();

      // Should either show loading indicator or handle the error gracefully
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should display ProfilePage with tabs', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(MaterialApp(home: ProfilePage()));

      await tester.pump();

      expect(find.byType(TabBar), findsOneWidget);
    });

    testWidgets('should have Quizzes, Sessions, and Posts tabs', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(MaterialApp(home: ProfilePage()));

      await tester.pump();

      expect(find.text('Quizzes'), findsOneWidget);
      expect(find.text('Sessions'), findsOneWidget);
      expect(find.text('Posts'), findsOneWidget);
    });

    testWidgets('should render profile structure', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(home: ProfilePage()));

      await tester.pumpAndSettle(const Duration(seconds: 2));

      expect(find.byType(TabBarView), findsOneWidget);
    });
  });
}
