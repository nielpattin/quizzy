import "package:flutter/material.dart";

class GameSession {
  final String id;
  final String title;
  final String? topic;
  final String length;
  final String date;
  final bool isLive;
  final int joined;
  final int? questions;
  final List<Color> gradient;

  GameSession({
    required this.id,
    required this.title,
    this.topic,
    required this.length,
    required this.date,
    required this.isLive,
    required this.joined,
    this.questions,
    required this.gradient,
  });

  factory GameSession.fromJson(
    Map<String, dynamic> json,
    List<Color> gradient,
  ) {
    return GameSession(
      id: json["id"] as String,
      title: json["title"] as String,
      topic: json["topic"] as String?,
      length: json["length"] as String,
      date: json["date"] as String,
      isLive: json["isLive"] as bool,
      joined: json["joined"] as int,
      questions: json["questions"] as int?,
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
      "questions": questions,
    };
  }
}
