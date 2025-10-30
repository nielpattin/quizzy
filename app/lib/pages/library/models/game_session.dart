import "package:flutter/material.dart";

class GameSession {
  final String id;
  final String title;
  final String? topic;
  final String length;
  final String date;
  final bool isLive;
  final int joined; // playerCount - unique users who joined
  final int plays; // participantCount - total attempts/plays
  final int? questions;
  final String? imageUrl;
  final List<Color> gradient;

  GameSession({
    required this.id,
    required this.title,
    this.topic,
    required this.length,
    required this.date,
    required this.isLive,
    required this.joined,
    required this.plays,
    this.questions,
    this.imageUrl,
    required this.gradient,
  });

  static String _formatDate(String? dateStr) {
    if (dateStr == null) return "Unknown";
    try {
      final date = DateTime.parse(dateStr);
      final months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      return "${months[date.month - 1]} ${date.day}, ${date.year}";
    } catch (e) {
      return dateStr;
    }
  }

  factory GameSession.fromJson(
    Map<String, dynamic> json,
    List<Color> gradient,
  ) {
    // Calculate question count from estimatedMinutes if available
    final estimatedMinutes = json["estimatedMinutes"] as int?;
    final questionCount = estimatedMinutes != null
        ? (estimatedMinutes / 2)
              .round() // Assuming 2 min per question
        : json["questions"] as int?;

    // Get player count (unique users) and play count (total attempts)
    final playerCount = json["playerCount"] as int? ?? 0;

    final participantCount =
        json["participantCount"] as int? ??
        json["joined"] as int? ??
        (json["participants"] as List?)?.length ??
        0;

    return GameSession(
      id: json["id"] as String,
      title: json["title"] as String? ?? "Untitled Session",
      topic: json["topic"] as String?,
      length: questionCount != null
          ? "$questionCount Qs"
          : "${estimatedMinutes ?? 0} min",
      date: _formatDate(
        json["createdAt"] as String? ?? json["date"] as String?,
      ),
      isLive: json["isLive"] as bool? ?? false,
      joined: playerCount, // Unique users
      plays: participantCount, // Total plays
      questions: questionCount,
      imageUrl: json["imageUrl"] as String?,
      gradient: gradient,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "title": title,
      "topic": topic,
      "length": length,
      "date": date,
      "isLive": isLive,
      "joined": joined,
      "plays": plays,
      "questions": questions,
      "imageUrl": imageUrl,
    };
  }
}
