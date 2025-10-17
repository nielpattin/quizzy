import "../models/quiz.dart";
import "../models/collection.dart";
import "../models/game_session.dart";
import "../utils/gradients.dart";
import "../../../services/api_service.dart";
import "package:supabase_flutter/supabase_flutter.dart";

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
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return [];

    final data = await ApiService.getUserQuizzes(userId);

    final quizzes = data
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
    final data = await ApiService.getFavorites();

    final quizzes = data.asMap().entries.map((e) {
      final quizData = e.value["quiz"];
      return Quiz.fromJson(quizData, gradientForIndex(e.key + 3));
    }).toList();

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
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return [];

    final data = await ApiService.getUserCollections(userId);

    return data
        .asMap()
        .entries
        .map((e) => Collection.fromJson(e.value, gradientForIndex(e.key + 10)))
        .toList();
  }

  static Future<List<Quiz>> fetchSoloPlays() async {
    return [];
  }

  static Future<List<GameSession>> fetchMySessions(SortOption sort) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return [];

    final data = await ApiService.getHostedSessions(userId);

    final sessions = data
        .asMap()
        .entries
        .map((e) => GameSession.fromJson(e.value, gradientForIndex(e.key)))
        .toList();

    return sessions;
  }

  static Future<List<GameSession>> fetchRecentSessions(SortOption sort) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return [];

    final data = await ApiService.getPlayedSessions(userId);

    final sessions = data
        .asMap()
        .entries
        .map((e) => GameSession.fromJson(e.value, gradientForIndex(e.key)))
        .toList();

    return sessions;
  }
}
