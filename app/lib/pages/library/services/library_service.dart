import "../models/quiz.dart";
import "../models/collection.dart";
import "../models/game_session.dart";
import "../utils/gradients.dart";
import "mock_data.dart";

enum SortOption {
  newest("Newest", 0),
  oldest("Oldest", 1),
  mostPlayed("Most Played", 2),
  alphabetical("A-Z", 3);

  final String label;
  final int value;
  const SortOption(this.label, this.value);
}

class LibraryService {
  static Future<List<Quiz>> fetchCreatedQuizzes(SortOption sort) async {
    await Future.delayed(const Duration(milliseconds: 500));

    final quizzes = MockLibraryData.createdQuizzes
        .asMap()
        .entries
        .map((e) => Quiz.fromJson(e.value, gradientForIndex(e.key)))
        .toList();

    switch (sort) {
      case SortOption.oldest:
        return quizzes.reversed.toList();
      case SortOption.mostPlayed:
        quizzes.sort((a, b) => b.plays.compareTo(a.plays));
        return quizzes;
      case SortOption.alphabetical:
        quizzes.sort((a, b) => a.title.compareTo(b.title));
        return quizzes;
      case SortOption.newest:
        return quizzes;
    }
  }

  static Future<List<Quiz>> fetchSavedQuizzes(SortOption sort) async {
    await Future.delayed(const Duration(milliseconds: 500));

    final quizzes = MockLibraryData.savedQuizzes
        .asMap()
        .entries
        .map((e) => Quiz.fromJson(e.value, gradientForIndex(e.key + 3)))
        .toList();

    switch (sort) {
      case SortOption.oldest:
        return quizzes.reversed.toList();
      case SortOption.mostPlayed:
        quizzes.sort((a, b) => b.plays.compareTo(a.plays));
        return quizzes;
      case SortOption.alphabetical:
        quizzes.sort((a, b) => a.title.compareTo(b.title));
        return quizzes;
      case SortOption.newest:
        return quizzes;
    }
  }

  static Future<List<Collection>> fetchCollections() async {
    await Future.delayed(const Duration(milliseconds: 500));

    return MockLibraryData.collections
        .asMap()
        .entries
        .map((e) => Collection.fromJson(e.value, gradientForIndex(e.key + 10)))
        .toList();
  }

  static Future<List<Quiz>> fetchSoloPlays() async {
    await Future.delayed(const Duration(milliseconds: 500));

    return MockLibraryData.soloPlays
        .asMap()
        .entries
        .map((e) => Quiz.fromJson(e.value, gradientForIndex(e.key)))
        .toList();
  }

  static Future<List<GameSession>> fetchMySessions(SortOption sort) async {
    await Future.delayed(const Duration(milliseconds: 500));

    final sessions = MockLibraryData.gameSessions
        .asMap()
        .entries
        .map((e) => GameSession.fromJson(e.value, gradientForIndex(e.key)))
        .toList();

    return sessions;
  }

  static Future<List<GameSession>> fetchRecentSessions(SortOption sort) async {
    await Future.delayed(const Duration(milliseconds: 500));

    final sessions = MockLibraryData.gameSessions
        .asMap()
        .entries
        .map((e) => GameSession.fromJson(e.value, gradientForIndex(e.key)))
        .toList();

    return sessions;
  }
}
