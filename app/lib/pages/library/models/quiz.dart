import "package:flutter/material.dart";

class Quiz {
  final String id;
  final String title;
  final String timeAgo;
  final int plays;
  final int questions;
  final bool? isPublic;
  final String? imageUrl;
  final List<Color> gradient;

  Quiz({
    required this.id,
    required this.title,
    required this.timeAgo,
    required this.plays,
    required this.questions,
    this.isPublic,
    this.imageUrl,
    required this.gradient,
  });

  factory Quiz.fromJson(Map<String, dynamic> json, List<Color> gradient) {
    return Quiz(
      id: json["id"] as String,
      title: json["title"] as String,
      timeAgo: json["timeAgo"] as String? ?? "Recently",
      plays: (json["plays"] ?? json["playCount"] ?? 0) as int,
      questions: (json["questions"] ?? json["questionCount"] ?? 0) as int,
      isPublic: json["isPublic"] as bool?,
      imageUrl: json["imageUrl"] as String?,
      gradient: gradient,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "title": title,
      "timeAgo": timeAgo,
      "plays": plays,
      "questions": questions,
      "isPublic": isPublic,
      "imageUrl": imageUrl,
    };
  }
}
