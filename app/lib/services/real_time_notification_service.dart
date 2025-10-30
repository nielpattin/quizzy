import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';
import 'package:http/http.dart' as http;
import 'websocket_service.dart';
import 'in_app_notification_service.dart';
import 'http_client.dart';

// Notification types
enum NotificationType {
  quizCompleted,
  highScore,
  participantJoined,
  participantLeft,
  sessionStarted,
  sessionEnded,
  leaderboardUpdate,
  invitationReceived,
  general,
}

// Notification model
class RealTimeNotification {
  final String id;
  final NotificationType type;
  final String title;
  final String message;
  final Map<String, dynamic>? data;
  final DateTime timestamp;
  final bool isRead;
  final Widget? icon;

  RealTimeNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    this.data,
    DateTime? timestamp,
    this.isRead = false,
    this.icon,
  }) : timestamp = timestamp ?? DateTime.now();

  factory RealTimeNotification.fromWebSocketMessage(WebSocketMessage message) {
    String id =
        'notif_${DateTime.now().millisecondsSinceEpoch}_${message.type}';
    String title = '';
    String messageText = '';
    NotificationType type = NotificationType.general;
    Widget? icon;

    switch (message.type) {
      case WebSocketMessageType.sessionEnded:
        type = NotificationType.quizCompleted;
        title = 'Quiz Completed!';
        final score = message.data?['score'] ?? 0;
        final total = message.data?['totalQuestions'] ?? 0;
        final percentage = message.data?['percentage'] ?? '0';
        messageText = 'Someone scored $score/$total ($percentage%)!';
        icon = const Icon(Icons.emoji_events, color: Colors.amber, size: 24);
        break;

      case WebSocketMessageType.participantJoined:
        type = NotificationType.participantJoined;
        title = 'New Player';
        final username = message.data?['username'] ?? 'Someone';
        messageText = '$username joined the quiz!';
        icon = const Icon(Icons.person_add, color: Colors.green, size: 24);
        break;

      case WebSocketMessageType.participantLeft:
        type = NotificationType.participantLeft;
        title = 'Player Left';
        final username = message.data?['username'] ?? 'Someone';
        messageText = '$username left the quiz.';
        icon = const Icon(Icons.person_remove, color: Colors.orange, size: 24);
        break;

      case WebSocketMessageType.sessionStarted:
        type = NotificationType.sessionStarted;
        title = 'Quiz Started!';
        messageText = 'The live quiz session has begun.';
        icon = const Icon(Icons.play_arrow, color: Colors.green, size: 24);
        break;

      case WebSocketMessageType.leaderboardUpdate:
        type = NotificationType.leaderboardUpdate;
        title = 'Leaderboard Updated';
        messageText = 'Check out the latest rankings!';
        icon = const Icon(Icons.leaderboard, color: Colors.blue, size: 24);
        break;

      default:
        type = NotificationType.general;
        title = 'Notification';
        messageText = message.message ?? 'New notification received.';
        icon = const Icon(Icons.notifications, color: Colors.grey, size: 24);
    }

    return RealTimeNotification(
      id: id,
      type: type,
      title: title,
      message: messageText,
      data: message.data,
      icon: icon,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.toString(),
      'title': title,
      'message': message,
      'data': data,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
    };
  }
}

// Real-time Notification Service
class RealTimeNotificationService {
  static final RealTimeNotificationService _instance =
      RealTimeNotificationService._internal();
  factory RealTimeNotificationService() => _instance;
  RealTimeNotificationService._internal();

  final WebSocketService _websocketService = WebSocketService();

  // Stream controllers
  final _notificationController = BehaviorSubject<RealTimeNotification>();
  final _newCountController = BehaviorSubject<int>.seeded(0);

  // Public streams
  Stream<RealTimeNotification> get notifications =>
      _notificationController.stream;
  Stream<int> get newCount => _newCountController.stream;

  StreamSubscription? _websocketSubscription;
  StreamSubscription? _connectionSubscription;

  void init() {
    // Listen to WebSocket connection status
    _connectionSubscription = _websocketService.connectionStatus.listen((
      status,
    ) {
      if (status == ConnectionStatus.connected) {
        debugPrint(
          '[RealTimeNotification] WebSocket connected, fetching new count',
        );
        refreshNewCount();
      }
    });

    // Listen to WebSocket messages
    _websocketSubscription = _websocketService.messages.listen((message) {
      _handleWebSocketMessage(message);
    });
  }

  void _handleWebSocketMessage(WebSocketMessage message) {
    // Only log and process notification type messages for this service
    if (message.type == WebSocketMessageType.notification) {
      debugPrint('[RealTimeNotification] 🔔 Notification received');
      debugPrint('[RealTimeNotification] Data: ${message.data}');

      // message.data now contains the notification directly (not nested under 'notification')
      final notificationData = message.data;

      if (notificationData != null) {
        // Show popup banner ONLY for follow notifications
        if (notificationData['type'] == 'follow') {
          debugPrint(
            '[RealTimeNotification] Showing in-app notification for FOLLOW',
          );
          debugPrint(
            '[RealTimeNotification] Title: ${notificationData['title']}',
          );
          debugPrint(
            '[RealTimeNotification] Subtitle: ${notificationData['subtitle']}',
          );

          InAppNotificationService.showInAppNotification(
            title: notificationData['title'] ?? 'New Notification',
            body: notificationData['subtitle'] ?? '',
            payload: {
              'type': notificationData['type'],
              'relatedPostId': notificationData['relatedPostId'],
              'relatedUserId': notificationData['relatedUserId'],
              'relatedQuizId': notificationData['relatedQuizId'],
            },
          );
        } else {
          debugPrint(
            '[RealTimeNotification] Skipping popup for type: ${notificationData['type']}',
          );
        }
      } else {
        debugPrint(
          '[RealTimeNotification] ⚠️ ERROR: notificationData is NULL!',
        );
      }

      // Always refresh new count for ALL notification types
      refreshNewCount();
    }

    // Still create notification object for internal tracking (but don't log for non-notification types)
    final notification = RealTimeNotification.fromWebSocketMessage(message);
    _notificationController.add(notification);
  }

  // Refresh new notification count from database
  Future<void> refreshNewCount() async {
    try {
      final headers = await HttpClient.getHeaders();
      final response = await http.get(
        Uri.parse('${HttpClient.baseUrl}/api/notification/new-count'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _newCountController.add(data['count'] as int);
        debugPrint(
          '[RealTimeNotification] New count updated: ${data['count']}',
        );
      }
    } catch (e) {
      debugPrint('[RealTimeNotification] Error refreshing new count: $e');
    }
  }

  // Mark notifications as seen (resets "new since last seen" counter)
  Future<void> markAsSeen() async {
    try {
      final headers = await HttpClient.getHeaders();
      await http.put(
        Uri.parse('${HttpClient.baseUrl}/api/notification/seen'),
        headers: headers,
      );
      // Reset count to 0 after marking seen
      _newCountController.add(0);
      debugPrint('[RealTimeNotification] Marked notifications as seen');
    } catch (e) {
      debugPrint('[RealTimeNotification] Error marking as seen: $e');
    }
  }

  void dispose() {
    _websocketSubscription?.cancel();
    _connectionSubscription?.cancel();
    _notificationController.close();
    _newCountController.close();
  }
}
