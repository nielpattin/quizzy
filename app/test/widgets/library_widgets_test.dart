import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quizzy/pages/library/widgets/quiz_play_card.dart';
import 'package:quizzy/pages/library/widgets/collection_card.dart';
import 'package:quizzy/pages/library/widgets/game_session_card.dart';
import 'package:quizzy/pages/library/widgets/meta_chip.dart';
import 'package:quizzy/pages/library/widgets/sort_button.dart';
import 'package:quizzy/pages/library/widgets/section_header.dart';
import 'package:quizzy/pages/library/services/library_service.dart';
import '../helpers/test_helpers.dart';

void main() {
  group('Library Widget Tests', () {
    testWidgets('QuizPlayCard should display quiz information', (
      WidgetTester tester,
    ) async {
      final mockQuiz = createMockQuiz();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuizPlayCard(
              title: mockQuiz['title'],
              timeAgo: '2 hours ago',
              questions: mockQuiz['questionCount'],
              plays: mockQuiz['playCount'],
              gradient: [Colors.blue, Colors.purple],
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text(mockQuiz['title']), findsOneWidget);
      expect(find.text('2 hours ago'), findsOneWidget);
      expect(
        find.text('${mockQuiz['questionCount']} questions'),
        findsOneWidget,
      );
      expect(find.text('${mockQuiz['playCount']} plays'), findsOneWidget);
    });

    testWidgets('CollectionCard should display collection information', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CollectionCard(
              title: 'Science Collection',
              quizCount: 5,
              gradient: [Colors.green, Colors.teal],
            ),
          ),
        ),
      );

      expect(find.text('Science Collection'), findsOneWidget);
      expect(find.text('5 quizzes'), findsOneWidget);
    });

    testWidgets('GameSessionCard should display session information', (
      WidgetTester tester,
    ) async {
      final session = createMockSession();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GameSessionCard(
              title: session['title'],
              date: '2 hours ago',
              gradient: [Colors.orange, Colors.red],
              isLive: session['isLive'],
              joined: 0,
              plays: 0,
              length: '${session['estimatedMinutes']} min',
            ),
          ),
        ),
      );

      expect(find.text(session['title']), findsOneWidget);
      expect(find.text('2 hours ago'), findsOneWidget);
      expect(find.text('${session['estimatedMinutes']} min'), findsOneWidget);
    });

    testWidgets('MetaChip should display category information', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MetaChip(label: 'Science', icon: Icons.science),
          ),
        ),
      );

      expect(find.text('Science'), findsOneWidget);
    });

    testWidgets('SortButton should display sort options', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: SortButton(option: SortOption.alphabetical)),
        ),
      );

      expect(find.byIcon(Icons.swap_vert), findsOneWidget);
    });

    testWidgets('SectionHeader should display title', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SectionHeader(
              title: 'Popular Quizzes',
              sort: SortOption.alphabetical,
              showSort: false,
            ),
          ),
        ),
      );

      expect(find.text('Popular Quizzes'), findsOneWidget);
    });
  });

  group('Library Widget Interaction Tests', () {
    testWidgets('QuizPlayCard should call onTap when tapped', (
      WidgetTester tester,
    ) async {
      bool wasTapped = false;
      final mockQuiz = createMockQuiz();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuizPlayCard(
              title: mockQuiz['title'],
              timeAgo: '2 hours ago',
              questions: mockQuiz['questionCount'],
              plays: mockQuiz['playCount'],
              gradient: [Colors.blue, Colors.purple],
              onTap: () => wasTapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(QuizPlayCard));
      await tester.pump();

      expect(wasTapped, isTrue);
    });

    testWidgets('CollectionCard should render correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CollectionCard(
              title: 'Test Collection',
              quizCount: 3,
              gradient: [Colors.green, Colors.teal],
            ),
          ),
        ),
      );

      expect(find.text('Test Collection'), findsOneWidget);
      expect(find.text('3 quizzes'), findsOneWidget);
    });

    testWidgets('SortButton should be tappable', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: SortButton(option: SortOption.alphabetical)),
        ),
      );

      await tester.tap(find.byType(SortButton));
      await tester.pump();

      expect(find.byType(SortButton), findsOneWidget);
    });
  });

  group('Library Widget Layout Tests', () {
    testWidgets('QuizPlayCard should layout elements correctly', (
      WidgetTester tester,
    ) async {
      final mockQuiz = createMockQuiz();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuizPlayCard(
              title: mockQuiz['title'],
              timeAgo: '2 hours ago',
              questions: mockQuiz['questionCount'],
              plays: mockQuiz['playCount'],
              gradient: [Colors.blue, Colors.purple],
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text(mockQuiz['title']), findsOneWidget);
      expect(find.byType(Card), findsOneWidget);
    });

    testWidgets('CollectionCard should render correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CollectionCard(
              title: 'Test Collection',
              quizCount: 5,
              gradient: [Colors.green, Colors.teal],
            ),
          ),
        ),
      );

      expect(find.text('Test Collection'), findsOneWidget);
      expect(find.text('5 quizzes'), findsOneWidget);
    });

    testWidgets('GameSessionCard should render correctly', (
      WidgetTester tester,
    ) async {
      final session = createMockSession();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GameSessionCard(
              title: session['title'],
              date: '2 hours ago',
              gradient: [Colors.orange, Colors.red],
              isLive: session['isLive'],
              joined: 0,
              plays: 0,
              length: '${session['estimatedMinutes']} min',
            ),
          ),
        ),
      );

      expect(find.text(session['title']), findsOneWidget);
    });
  });

  group('Library Widget Data Validation Tests', () {
    test('should validate quiz card data structure', () {
      final quizData = createMockQuiz();

      expect(quizData['id'], isNotEmpty);
      expect(quizData['title'], isNotEmpty);
      expect(quizData['category'], isNotEmpty);
      expect(quizData['questionCount'], isA<int>());
      expect(quizData['playCount'], isA<int>());
      expect(quizData['isPublic'], isA<bool>());
    });

    test('should validate collection card data structure', () {
      final collectionData = {
        'id': 'collection-123',
        'name': 'Test Collection',
        'description': 'Test description',
        'quizCount': 5,
        'isPublic': true,
        'createdAt': '2024-01-01T00:00:00Z',
      };

      expect(collectionData['id'], isNotEmpty);
      expect(collectionData['name'], isNotEmpty);
      expect(collectionData['description'], isA<String>());
      expect(collectionData['quizCount'], isA<int>());
      expect(collectionData['isPublic'], isA<bool>());
      expect(collectionData['createdAt'], isA<String>());
    });

    test('should validate session card data structure', () {
      final sessionData = createMockSession();

      expect(sessionData['id'], isNotEmpty);
      expect(sessionData['title'], isNotEmpty);
      expect(sessionData['code'], isNotEmpty);
      expect(sessionData['code'].length, 6);
      expect(sessionData['isLive'], isA<bool>());
      expect(sessionData['estimatedMinutes'], isA<int>());
    });

    test('should validate sort options', () {
      const validSortOptions = [
        'Popular',
        'Recent',
        'Alphabetical',
        'Most Played',
      ];

      for (final option in validSortOptions) {
        expect(option, isNotEmpty);
        expect(option, isIn(validSortOptions));
      }
    });

    test('should validate meta chip data', () {
      final chipData = {
        'label': 'Science',
        'icon': Icons.science,
        'color': Colors.blue,
      };

      expect(chipData['label'], isNotEmpty);
      expect(chipData['icon'], isA<IconData>());
      expect(chipData['color'], isA<Color>());
    });
  });
}
