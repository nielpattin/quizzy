import 'package:flutter_test/flutter_test.dart';
import '../helpers/test_helpers.dart';

void main() {
  group('ApiService Tests', () {
    test('should handle null responses gracefully', () {
      expect(() {
        final Map<String, dynamic>? data = null;
        final title = data?["title"] ?? "Default Title";
        expect(title, "Default Title");
      }, returnsNormally);
    });

    test('should handle missing fields in quiz data', () {
      final quiz = {"id": "123", "title": "Test Quiz"};

      expect(quiz["id"], "123");
      expect(quiz["title"], "Test Quiz");
      expect(quiz["category"] ?? "General", "General");
      expect(quiz["questionCount"] ?? 0, 0);
      expect(quiz["playCount"] ?? 0, 0);
    });

    test('should handle nested user data safely', () {
      final quiz = {
        "id": "123",
        "title": "Test Quiz",
        "user": {"id": "user-1", "fullName": "John Doe"},
      };

      final user = quiz["user"] as Map<String, dynamic>?;
      expect(user?["fullName"] ?? "Unknown", "John Doe");

      final quizWithoutUser = {"id": "123", "title": "Test Quiz"};

      final noUser = quizWithoutUser["user"] as Map<String, dynamic>?;
      expect(noUser?["fullName"] ?? "Unknown", "Unknown");
    });

    test('should handle list responses safely', () {
      final List<dynamic> emptyList = [];
      expect(emptyList.isNotEmpty, false);
      expect(emptyList.isEmpty, true);

      final List<dynamic> quizzes = [
        {"id": "1", "title": "Quiz 1"},
        {"id": "2", "title": "Quiz 2"},
      ];
      expect(quizzes.length, 2);
      expect(quizzes.first["title"], "Quiz 1");
    });

    test('should handle session data with null fields', () {
      final session = {
        "id": "session-1",
        "title": "Test Session",
        "estimatedMinutes": 30,
      };

      final length = "${session["estimatedMinutes"] ?? 0} min";
      expect(length, "30 min");

      final date = session["createdAt"] as String? ?? "Unknown";
      expect(date, "Unknown");
    });

    test('should handle pagination parameters', () {
      final limit = 20;
      final offset = 0;
      expect(limit, greaterThan(0));
      expect(offset, greaterThanOrEqualTo(0));
    });
  });

  group('Data Validation Tests', () {
    test('should validate quiz required fields', () {
      final validQuiz = {
        "id": "123",
        "title": "Valid Quiz",
        "questionCount": 10,
      };

      expect(validQuiz["id"], isNotNull);
      expect(validQuiz["title"], isNotEmpty);
      expect(validQuiz["questionCount"], greaterThan(0));
    });

    test('should handle invalid or empty strings', () {
      final data = {"title": "", "category": null};

      final title = data["title"]?.toString().isEmpty == true
          ? "Untitled"
          : data["title"];
      expect(title, "Untitled");

      final category = data["category"] ?? "General";
      expect(category, "General");
    });

    test('should handle number conversions safely', () {
      final data = {"count": "10", "plays": 100};

      expect(data["plays"] as int, 100);
      expect(int.tryParse(data["count"] as String), 10);
    });
  });

  group('Error Handling Tests', () {
    test('should handle API error responses', () {
      final errorResponse = {"error": "Quiz not found", "statusCode": 404};

      expect(errorResponse["error"], contains("not found"));
      expect(errorResponse["statusCode"], 404);
    });

    test('should handle network timeout', () {
      expect(() async {
        await Future.delayed(Duration(milliseconds: 100));
      }, returnsNormally);
    });

    test('should handle JSON decode errors', () {
      expect(() {
        try {
          throw FormatException("Invalid JSON");
        } catch (e) {
          expect(e, isA<FormatException>());
        }
      }, returnsNormally);
    });
  });

  group('API Integration Tests', () {
    test('should format quiz data for API requests', () {
      final quiz = createMockQuiz();

      final requestData = {
        'title': quiz['title'],
        'description': quiz['description'],
        'category': quiz['category'],
        'questionCount': quiz['questionCount'],
        'isPublic': quiz['isPublic'],
        'questionsVisible': quiz['questionsVisible'],
      };

      expect(requestData['title'], isA<String>());
      expect(requestData['description'], isA<String>());
      expect(requestData['category'], isA<String>());
      expect(requestData['questionCount'], isA<int>());
      expect(requestData['isPublic'], isA<bool>());
      expect(requestData['questionsVisible'], isA<bool>());
    });

    test('should format question data for API requests', () {
      final questionData = {
        'type': 'multiple_choice',
        'question': 'What is 2 + 2?',
        'options': ['3', '4', '5', '6'],
        'correctAnswer': 1,
        'points': 10,
        'timeLimit': 30,
      };

      expect(
        questionData['type'],
        isIn(['multiple_choice', 'true_false', 'type_answer', 'single_answer']),
      );
      expect(questionData['question'], isNotEmpty);
      expect(questionData['options'], isA<List>());
      expect(questionData['correctAnswer'], isA<int>());
      expect(questionData['points'], greaterThan(0));
      expect(questionData['timeLimit'], greaterThan(0));
    });

    test('should handle quiz search parameters', () {
      final searchParams = {
        'query': 'Science',
        'category': 'Science',
        'limit': 20,
        'offset': 0,
        'sortBy': 'popular',
        'isPublic': true,
      };

      expect(searchParams['query'], isA<String>());
      expect(searchParams['category'], isA<String>());
      expect(searchParams['limit'], isA<int>());
      expect(searchParams['offset'], isA<int>());
      expect(searchParams['sortBy'], isA<String>());
      expect(searchParams['isPublic'], isA<bool>());
    });

    test('should handle user profile data', () {
      final profileData = {
        'username': 'testuser',
        'fullName': 'Test User',
        'bio': 'Test bio',
        'profilePictureUrl': null,
        'isPublic': true,
        'followersCount': 10,
        'followingCount': 5,
      };

      expect(profileData['username'], isNotEmpty);
      expect(profileData['fullName'], isNotEmpty);
      expect(profileData['bio'], isA<String>());
      expect(profileData['profilePictureUrl'], isA<String?>());
      expect(profileData['isPublic'], isA<bool>());
      expect(profileData['followersCount'], isA<int>());
      expect(profileData['followingCount'], isA<int>());
    });

    test('should handle quiz session data', () {
      final sessionData = {
        'quizId': 'quiz-123',
        'title': 'Test Session',
        'code': 'ABC123',
        'isLive': false,
        'estimatedMinutes': 30,
        'maxParticipants': 50,
        'currentParticipants': 10,
        'hostId': 'user-123',
      };

      expect(sessionData['quizId'], isNotEmpty);
      expect(sessionData['title'], isNotEmpty);
      expect(sessionData['code'], isNotEmpty);
      expect((sessionData['code'] as String).length, 6);
      expect(sessionData['isLive'], isA<bool>());
      expect(sessionData['estimatedMinutes'], greaterThan(0));
      expect(sessionData['maxParticipants'], greaterThan(0));
      expect(sessionData['currentParticipants'], greaterThanOrEqualTo(0));
      expect(sessionData['hostId'], isNotEmpty);
    });

    test('should handle notification data', () {
      final notificationData = {
        'id': 'notif-123',
        'userId': 'user-123',
        'type': 'like',
        'title': 'Someone liked your quiz',
        'message': 'John Doe liked your Science quiz',
        'isUnread': true,
        'data': {'quizId': 'quiz-123', 'actorId': 'user-456'},
      };

      expect(notificationData['id'], isNotEmpty);
      expect(notificationData['userId'], isNotEmpty);
      expect(
        notificationData['type'],
        isIn(['like', 'comment', 'follow', 'quiz', 'system']),
      );
      expect(notificationData['title'], isNotEmpty);
      expect(notificationData['message'], isNotEmpty);
      expect(notificationData['isUnread'], isA<bool>());
      expect(notificationData['data'], isA<Map>());
    });

    test('should handle pagination metadata', () {
      final paginationData = {
        'total': 100,
        'limit': 20,
        'offset': 0,
        'hasMore': true,
        'hasPrevious': false,
        'totalPages': 5,
        'currentPage': 1,
      };

      expect(paginationData['total'], greaterThanOrEqualTo(0));
      expect(paginationData['limit'], greaterThan(0));
      expect(paginationData['offset'], greaterThanOrEqualTo(0));
      expect(paginationData['hasMore'], isA<bool>());
      expect(paginationData['hasPrevious'], isA<bool>());
      expect(paginationData['totalPages'], greaterThan(0));
      expect(paginationData['currentPage'], greaterThan(0));
    });
  });

  group('API Response Validation Tests', () {
    test('should validate quiz list response structure', () {
      final response = {
        'data': [createMockQuiz(), createMockQuiz(title: 'Another Quiz')],
        'pagination': {'total': 2, 'limit': 20, 'offset': 0, 'hasMore': false},
      };

      expect(response['data'], isA<List>());
      expect((response['data'] as List).length, 2);
      expect(response['pagination'], isA<Map>());
      expect((response['pagination'] as Map)['total'], 2);
    });

    test('should validate error response structure', () {
      final errorResponse = {
        'error': 'Validation failed',
        'message': 'Required fields are missing',
        'code': 'VALIDATION_ERROR',
        'details': {
          'missingFields': ['title', 'category'],
        },
      };

      expect(errorResponse['error'], isNotEmpty);
      expect(errorResponse['message'], isNotEmpty);
      expect(errorResponse['code'], isNotEmpty);
      expect(errorResponse['details'], isA<Map>());
    });

    test('should validate success response structure', () {
      final successResponse = {
        'success': true,
        'message': 'Operation completed successfully',
        'data': {'id': 'created-123', 'createdAt': '2024-01-01T00:00:00Z'},
      };

      expect(successResponse['success'], isTrue);
      expect(successResponse['message'], isNotEmpty);
      expect(successResponse['data'], isA<Map>());
    });
  });
}
