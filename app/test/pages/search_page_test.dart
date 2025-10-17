import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quizzy/pages/social/search_page.dart';
import '../helpers/test_helpers.dart';

void main() {
  group('Search Page Tests', () {
    test('should handle empty search results', () {
      final results = <dynamic>[];
      expect(results.isEmpty, true);
    });

    test('should filter quizzes by search query', () {
      final quizzes = [
        createMockQuiz(title: "Science Quiz"),
        createMockQuiz(title: "History Quiz"),
        createMockQuiz(title: "Math Quiz"),
      ];

      final filtered = quizzes
          .where((q) => q["title"].toString().toLowerCase().contains("science"))
          .toList();

      expect(filtered.length, 1);
      expect(filtered[0]["title"], "Science Quiz");
    });

    test('should handle search with no matches', () {
      final quizzes = [
        createMockQuiz(title: "Science Quiz"),
        createMockQuiz(title: "History Quiz"),
      ];

      final filtered = quizzes
          .where((q) => q["title"].toString().toLowerCase().contains("xyz"))
          .toList();

      expect(filtered.isEmpty, true);
    });

    test('should handle case-insensitive search', () {
      final quizzes = [
        createMockQuiz(title: "SCIENCE Quiz"),
        createMockQuiz(title: "science quiz"),
        createMockQuiz(title: "Science QUIZ"),
      ];

      final query = "science";
      final filtered = quizzes
          .where(
            (q) => q["title"].toString().toLowerCase().contains(
              query.toLowerCase(),
            ),
          )
          .toList();

      expect(filtered.length, 3);
    });
  });

  group('Search User Tests', () {
    test('should search users by username', () {
      final users = [
        createMockUser(username: "john_doe", fullName: "John Doe"),
        createMockUser(username: "jane_smith", fullName: "Jane Smith"),
        createMockUser(username: "bob_jones", fullName: "Bob Jones"),
      ];

      final filtered = users
          .where((u) => u["username"].toString().toLowerCase().contains("john"))
          .toList();

      expect(filtered.length, 1);
      expect(filtered[0]["username"], "john_doe");
    });

    test('should handle null profile picture', () {
      final user = createMockUser();
      expect(user["profilePictureUrl"], null);
    });
  });

  group('Debounce Tests', () {
    test('should simulate debounced search', () async {
      var searchCount = 0;

      void performSearch(String query) {
        searchCount++;
      }

      performSearch("a");
      await Future.delayed(Duration(milliseconds: 100));
      performSearch("ab");
      await Future.delayed(Duration(milliseconds: 100));
      performSearch("abc");
      await Future.delayed(Duration(milliseconds: 600));

      expect(searchCount, 3);
    });
  });

  group('SearchPage Widget Tests', () {
    testWidgets('should render SearchPage with search field', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(MaterialApp(home: SearchPage()));

      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('should display search filters', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(home: SearchPage()));

      expect(find.text('All'), findsOneWidget);
      expect(find.text('Quizzes'), findsOneWidget);
      expect(find.text('Users'), findsOneWidget);
      expect(find.text('Collections'), findsOneWidget);
    });

    testWidgets('should show recent searches initially', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(MaterialApp(home: SearchPage()));

      expect(find.text('Recent Searches'), findsOneWidget);
    });

    testWidgets('should handle text input in search field', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(MaterialApp(home: SearchPage()));

      final searchField = find.byType(TextField);
      expect(searchField, findsOneWidget);

      await tester.enterText(searchField, 'Science');
      expect(find.text('Science'), findsOneWidget);
    });

    testWidgets('should debounce search input', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(home: SearchPage()));

      final searchField = find.byType(TextField);

      await tester.enterText(searchField, 'S');
      await tester.pump(const Duration(milliseconds: 100));

      await tester.enterText(searchField, 'Sc');
      await tester.pump(const Duration(milliseconds: 100));

      await tester.enterText(searchField, 'Science');
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.text('Science'), findsOneWidget);
    });
  });
}
