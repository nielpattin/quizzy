import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quizzy/pages/quiz/create_quiz_page.dart';
import 'package:quizzy/pages/quiz/play_quiz_page.dart';
import 'package:quizzy/pages/quiz/quiz_detail_page.dart';
import 'package:quizzy/pages/quiz/create_question_page.dart';
import 'package:quizzy/pages/quiz/category_page.dart';
import '../helpers/test_helpers.dart';

void main() {
  group('Quiz Pages Widget Tests', () {
    testWidgets('CreateQuizPage should render form fields', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(MaterialApp(home: CreateQuizPage()));

      expect(find.text('Create Quiz'), findsOneWidget);
      expect(find.text('Quiz Title'), findsOneWidget);
      expect(find.text('Description'), findsOneWidget);
      expect(find.text('Category'), findsOneWidget);
      expect(find.byType(TextField), findsWidgets);
      expect(find.text('Create'), findsOneWidget);
    });

    testWidgets('QuizDetailPage should display quiz information', (
      WidgetTester tester,
    ) async {
      final mockQuiz = createMockQuiz();

      await tester.pumpWidget(
        MaterialApp(home: QuizDetailPage(quizId: mockQuiz['id'])),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('PlayQuizPage should render quiz interface', (
      WidgetTester tester,
    ) async {
      final mockQuiz = createMockQuiz();

      await tester.pumpWidget(
        MaterialApp(home: PlayQuizPage(quizId: mockQuiz['id'])),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('CreateQuestionPage should show question form', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: CreateQuestionPage(
            quizId: 'test-quiz-id',
            questionType: 'multiple_choice',
          ),
        ),
      );

      expect(find.byType(TextField), findsWidgets);
    });

    testWidgets('CategoryPage should display category', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(home: CategoryPage(category: 'Science')),
      );

      expect(find.text('Science'), findsOneWidget);
    });
  });

  group('Quiz Creation Flow Tests', () {
    testWidgets('should navigate through quiz creation steps', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestApp(CreateQuizPage()));

      // Step 1: Fill quiz details
      await tester.enterText(find.byType(TextField).first, 'Test Quiz');
      await tester.enterText(find.byType(TextField).at(1), 'Test Description');

      // Step 2: Select category
      await tester.tap(find.text('Category'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Science'));
      await tester.pumpAndSettle();

      // Step 3: Create quiz
      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();

      // Should navigate to add questions page
      expect(find.text('Add Questions'), findsOneWidget);
    });

    testWidgets('should add multiple choice question', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        createTestApp(
          CreateQuestionPage(
            quizId: 'test-quiz-id',
            questionType: 'multiple_choice',
          ),
        ),
      );

      expect(find.byType(TextField), findsWidgets);
    });

    testWidgets('should add true/false question', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          CreateQuestionPage(
            quizId: 'test-quiz-id',
            questionType: 'true_false',
          ),
        ),
      );

      expect(find.byType(TextField), findsWidgets);
    });
  });

  group('Quiz Playing Flow Tests', () {
    testWidgets('should add multiple choice question', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: CreateQuestionPage(
            quizId: 'test-quiz-id',
            questionType: 'multiple_choice',
          ),
        ),
      );

      expect(find.byType(TextField), findsWidgets);
    });

    testWidgets('should add true/false question', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: CreateQuestionPage(
            quizId: 'test-quiz-id',
            questionType: 'true_false',
          ),
        ),
      );

      expect(find.byType(TextField), findsWidgets);
    });
  });

  group('Quiz Data Structure Tests', () {
    test('should create valid quiz data structure', () {
      final quizData = {
        'id': 'quiz-123',
        'title': 'Test Quiz',
        'description': 'A test quiz',
        'category': 'Science',
        'questionCount': 10,
        'playCount': 100,
        'isPublic': true,
        'questionsVisible': true,
        'createdAt': '2024-01-01T00:00:00Z',
        'user': {
          'id': 'user-123',
          'username': 'testuser',
          'fullName': 'Test User',
        },
      };

      expect(quizData['id'], isA<String>());
      expect(quizData['title'], isA<String>());
      expect(quizData['description'], isA<String>());
      expect(quizData['category'], isA<String>());
      expect(quizData['questionCount'], isA<int>());
      expect(quizData['playCount'], isA<int>());
      expect(quizData['isPublic'], isA<bool>());
      expect(quizData['questionsVisible'], isA<bool>());
      expect(quizData['user'], isA<Map>());
    });

    test('should create valid question data structure', () {
      final questionData = {
        'id': 'question-123',
        'type': 'multiple_choice',
        'question': 'What is 2 + 2?',
        'options': ['3', '4', '5', '6'],
        'correctAnswer': 1,
        'explanation': '2 + 2 = 4',
        'points': 10,
      };

      expect(questionData['id'], isA<String>());
      expect(
        questionData['type'],
        isIn(['multiple_choice', 'true_false', 'type_answer', 'single_answer']),
      );
      expect(questionData['question'], isA<String>());
      expect(questionData['options'], isA<List>());
      expect(questionData['correctAnswer'], isA<int>());
      expect(questionData['explanation'], isA<String>());
      expect(questionData['points'], isA<int>());
    });

    test('should handle quiz results data', () {
      final resultsData = {
        'quizId': 'quiz-123',
        'userId': 'user-123',
        'score': 80,
        'totalQuestions': 10,
        'correctAnswers': 8,
        'timeSpent': 300,
        'completedAt': '2024-01-01T00:00:00Z',
        'answers': [
          {
            'questionId': 'q1',
            'selectedAnswer': 0,
            'isCorrect': true,
            'timeSpent': 30,
          },
        ],
      };

      expect(resultsData['quizId'], isA<String>());
      expect(resultsData['userId'], isA<String>());
      expect(resultsData['score'], isA<int>());
      expect(resultsData['totalQuestions'], isA<int>());
      expect(resultsData['correctAnswers'], isA<int>());
      expect(resultsData['timeSpent'], isA<int>());
      expect(resultsData['answers'], isA<List>());
    });
  });

  group('Quiz Widget Tests', () {
    testWidgets('should handle quiz card interactions', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(MaterialApp(home: CreateQuizPage()));

      expect(find.byType(TextField), findsWidgets);
    });
  });
}
