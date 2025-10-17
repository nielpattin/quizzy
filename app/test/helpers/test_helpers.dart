import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

Widget createTestApp(Widget child) {
  final router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (context, state) => child),
      GoRoute(
        path: '/quiz/:id',
        builder: (context, state) =>
            Scaffold(body: Text('Quiz ${state.pathParameters['id']}')),
      ),
      GoRoute(
        path: '/profile/:id',
        builder: (context, state) =>
            Scaffold(body: Text('Profile ${state.pathParameters['id']}')),
      ),
    ],
  );

  return MaterialApp.router(routerConfig: router, theme: ThemeData.dark());
}

Map<String, dynamic> createMockQuiz({
  String? id,
  String? title,
  String? category,
  int? questionCount,
  int? playCount,
}) {
  return {
    "id": id ?? "quiz-123",
    "title": title ?? "Test Quiz",
    "description": "A test quiz description",
    "category": category ?? "Science",
    "questionCount": questionCount ?? 10,
    "playCount": playCount ?? 100,
    "favoriteCount": 50,
    "isPublic": true,
    "questionsVisible": true,
    "createdAt": "2024-01-01T00:00:00Z",
    "user": {
      "id": "user-123",
      "username": "testuser",
      "fullName": "Test User",
      "profilePictureUrl": null,
    },
  };
}

Map<String, dynamic> createMockUser({
  String? id,
  String? username,
  String? fullName,
}) {
  return {
    "id": id ?? "user-123",
    "username": username ?? "testuser",
    "fullName": fullName ?? "Test User",
    "profilePictureUrl": null,
    "bio": "Test bio",
    "followersCount": 10,
    "followingCount": 5,
  };
}

Map<String, dynamic> createMockSession({
  String? id,
  String? title,
  bool? isLive,
}) {
  return {
    "id": id ?? "session-123",
    "title": title ?? "Test Session",
    "code": "ABC123",
    "isLive": isLive ?? false,
    "estimatedMinutes": 30,
    "createdAt": "2024-01-01T00:00:00Z",
    "host": {"id": "user-123", "fullName": "Test User"},
  };
}

Map<String, dynamic> createMockPost({
  String? id,
  String? text,
  int? likesCount,
}) {
  return {
    "id": id ?? "post-123",
    "text": text ?? "Test post content",
    "likesCount": likesCount ?? 10,
    "commentsCount": 5,
    "isLiked": false,
    "createdAt": "2024-01-01T00:00:00Z",
    "user": {"id": "user-123", "fullName": "Test User"},
  };
}

Map<String, dynamic> createMockNotification({
  String? id,
  String? title,
  bool? isUnread,
}) {
  return {
    "id": id ?? "notif-123",
    "title": title ?? "Test Notification",
    "message": "Test message",
    "type": "like",
    "isUnread": isUnread ?? true,
    "createdAt": "2024-01-01T00:00:00Z",
  };
}
