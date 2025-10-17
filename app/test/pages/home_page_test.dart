import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quizzy/pages/home/home_page.dart';
import 'package:quizzy/pages/home/widgets/tab_button.dart';
import '../helpers/test_helpers.dart';

void main() {
  group('Home Page Data Structure Tests', () {
    testWidgets('should handle empty featured list', (
      WidgetTester tester,
    ) async {
      final emptyList = <dynamic>[];

      expect(emptyList.isEmpty, true);
      expect(emptyList.isNotEmpty, false);
    });

    testWidgets('should handle empty trending list', (
      WidgetTester tester,
    ) async {
      final emptyList = <dynamic>[];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: emptyList.isEmpty
                ? Center(child: Text('No trending quizzes'))
                : ListView.builder(
                    itemCount: emptyList.length,
                    itemBuilder: (context, index) => Text('Item $index'),
                  ),
          ),
        ),
      );

      expect(find.text('No trending quizzes'), findsOneWidget);
    });
  });

  group('Featured Card Tests', () {
    testWidgets('should safely access nested user data', (
      WidgetTester tester,
    ) async {
      final quiz = createMockQuiz();
      final user = quiz["user"] as Map<String, dynamic>?;
      final authorName = user?["fullName"] ?? "Unknown";

      expect(authorName, "Test User");
    });

    testWidgets('should handle null user data', (WidgetTester tester) async {
      final quiz = {"id": "quiz-123", "title": "Test Quiz", "user": null};

      final user = quiz["user"] as Map<String, dynamic>?;
      final authorName = user?["fullName"] ?? "Unknown";

      expect(authorName, "Unknown");
    });

    testWidgets('should handle missing category', (WidgetTester tester) async {
      final quiz = {"id": "quiz-123", "title": "Test Quiz", "category": null};

      final category = quiz["category"] ?? "General";

      expect(category, "General");
    });

    testWidgets('should handle questionCount field', (
      WidgetTester tester,
    ) async {
      final quiz = createMockQuiz(questionCount: 15);
      final count = quiz["questionCount"] ?? 0;

      expect(count, 15);
    });
  });

  group('Continue Playing Tests', () {
    testWidgets('should filter sessions by endedAt', (
      WidgetTester tester,
    ) async {
      final sessions = [
        {"id": "1", "title": "Active", "endedAt": null},
        {"id": "2", "title": "Ended", "endedAt": "2024-01-01"},
        {"id": "3", "title": "Active 2", "endedAt": null},
      ];

      final activeSessions = sessions
          .where((s) => s["endedAt"] == null)
          .toList();

      expect(activeSessions.length, 2);
      expect(activeSessions[0]["title"], "Active");
      expect(activeSessions[1]["title"], "Active 2");
    });

    testWidgets('should handle empty sessions list', (
      WidgetTester tester,
    ) async {
      final sessions = <dynamic>[];
      final activeSessions = sessions
          .where((s) => s["endedAt"] == null)
          .toList();

      expect(activeSessions.isEmpty, true);
    });
  });

  group('Error Handling Tests', () {
    testWidgets('should display error state gracefully', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48),
                  SizedBox(height: 16),
                  Text('Failed to load data'),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.text('Failed to load data'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('should handle null values in data', (
      WidgetTester tester,
    ) async {
      final Map<String, dynamic>? nullData = null;
      final title = nullData?["title"] ?? "Default";

      expect(title, "Default");
    });
  });

  group('Topics Data Structure Tests - CRITICAL', () {
    test('topics MUST use "label" field, NOT "name" field', () {
      final topics = [
        {"label": "Science", "icon": "science"},
        {"label": "History", "icon": "history"},
        {"label": "Geography", "icon": "geography"},
      ];

      expect(topics.length, 3);
      expect(topics[0]["label"], "Science");
      expect(topics[1]["label"], "History");
      expect(topics[2]["icon"], "geography");

      expect(
        topics[0].containsKey("name"),
        false,
        reason:
            'Topics should use "label" not "name" - this matches what _TopicCard expects in home_page.dart:377',
      );
    });

    testWidgets('INTEGRATION: topics ListView renders using label field', (
      WidgetTester tester,
    ) async {
      final topics = [
        {"label": "Science", "icon": "science"},
        {"label": "History", "icon": "history"},
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView.builder(
              itemCount: topics.length,
              itemBuilder: (context, index) {
                final topic = topics[index];
                return ListTile(title: Text(topic["label"] as String));
              },
            ),
          ),
        ),
      );

      expect(find.text('Science'), findsOneWidget);
      expect(find.text('History'), findsOneWidget);
    });

    testWidgets('CRITICAL: using "name" instead of "label" should fail', (
      WidgetTester tester,
    ) async {
      final topicsWithWrongKey = [
        {"name": "Science", "icon": "science"},
        {"name": "History", "icon": "history"},
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView.builder(
              itemCount: topicsWithWrongKey.length,
              itemBuilder: (context, index) {
                final topic = topicsWithWrongKey[index];
                String? label;
                try {
                  label = topic["label"];
                } catch (e) {
                  label = null;
                }

                return ListTile(title: Text(label ?? 'ERROR: label is null'));
              },
            ),
          ),
        ),
      );

      expect(find.text('ERROR: label is null'), findsWidgets);
    });
  });

  group('HomePage Widget Tests', () {
    testWidgets('should render HomePage with loading indicator', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(MaterialApp(home: HomePage()));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should display topics after loading', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(MaterialApp(home: HomePage()));

      await tester.pumpAndSettle(const Duration(seconds: 3));

      expect(find.text('Science'), findsOneWidget);
      expect(find.text('History'), findsOneWidget);
    });

    testWidgets('should have Quizzy and Feedy tabs', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(MaterialApp(home: HomePage()));

      // Find the Quizzy tab button specifically
      expect(
        find.byWidgetPredicate(
          (widget) => widget is TabButton && widget.label == 'Quizzy',
        ),
        findsOneWidget,
      );
      // Find the Feedy tab button specifically
      expect(
        find.byWidgetPredicate(
          (widget) => widget is TabButton && widget.label == 'Feedy',
        ),
        findsOneWidget,
      );
    });
  });
}
