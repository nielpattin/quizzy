import "package:flutter/material.dart";

class Collection {
  final String id;
  final String title;
  final int quizCount;
  final String? imageUrl;
  final List<Color> gradient;

  Collection({
    required this.id,
    required this.title,
    required this.quizCount,
    this.imageUrl,
    required this.gradient,
  });

  factory Collection.fromJson(Map<String, dynamic> json, List<Color> gradient) {
    return Collection(
      id: json["id"] as String,
      title: json["title"] as String,
      quizCount: json["quizCount"] as int,
      imageUrl: json["imageUrl"] as String?,
      gradient: gradient,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "title": title,
      "quizCount": quizCount,
      "imageUrl": imageUrl,
    };
  }
}
