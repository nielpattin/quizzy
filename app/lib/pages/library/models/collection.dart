import "package:flutter/material.dart";

class Collection {
  final String id;
  final String title;
  final int quizCount;
  final List<Color> gradient;

  Collection({
    required this.id,
    required this.title,
    required this.quizCount,
    required this.gradient,
  });

  factory Collection.fromJson(Map<String, dynamic> json, List<Color> gradient) {
    return Collection(
      id: json["id"] as String,
      title: json["title"] as String,
      quizCount: json["quizCount"] as int,
      gradient: gradient,
    );
  }

  Map<String, dynamic> toJson() {
    return {"id": id, "title": title, "quizCount": quizCount};
  }
}
