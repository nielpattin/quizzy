import 'dart:async';
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';
import 'websocket_service.dart';
import 'in_app_notification_service.dart';

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
  final List<RealTimeNotification> _notifications = [];

  // Stream controllers
  final _notificationController = BehaviorSubject<RealTimeNotification>();
  final _notificationsListController =
      BehaviorSubject<List<RealTimeNotification>>();
  final _unreadCountController = BehaviorSubject<int>.seeded(0);

  // Public streams
  Stream<RealTimeNotification> get notifications =>
      _notificationController.stream;
  Stream<List<RealTimeNotification>> get notificationsList =>
      _notificationsListController.stream;
  Stream<int> get unreadCount => _unreadCountController.stream;

  List<RealTimeNotification> get allNotifications =>
      List.unmodifiable(_notifications);
  int get unreadNotificationsCount =>
      _notifications.where((n) => !n.isRead).length;

  StreamSubscription? _websocketSubscription;

  void init() {
    // Listen to WebSocket messages
    _websocketSubscription = _websocketService.messages.listen((message) {
      _handleWebSocketMessage(message);
    });
  }

  void _handleWebSocketMessage(WebSocketMessage message) {
    debugPrint(
      '[RealTimeNotification] Received WebSocket message type: ${message.type}',
    );
    debugPrint('[RealTimeNotification] Message data: ${message.data}');

    if (message.type == WebSocketMessageType.notification) {
      debugPrint('[RealTimeNotification] Processing notification message');

      // message.data now contains the notification directly (not nested under 'notification')
      final notificationData = message.data;
      debugPrint('[RealTimeNotification] Notification data: $notificationData');

      if (notificationData != null) {
        debugPrint('[RealTimeNotification] Showing in-app notification');
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
        debugPrint('[RealTimeNotification] ERROR: notificationData is NULL!');
        debugPrint(
          '[RealTimeNotification] Full message.data structure: ${message.data}',
        );
      }
      return;
    }

    final notification = RealTimeNotification.fromWebSocketMessage(message);

    _notifications.insert(0, notification);

    if (_notifications.length > 50) {
      _notifications.removeRange(50, _notifications.length);
    }

    _notificationController.add(notification);
    _notificationsListController.add(List.from(_notifications));
    _updateUnreadCount();
  }

  void markAsRead(String notificationId) {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      // Create a new notification with isRead = true
      final updatedNotification = RealTimeNotification(
        id: _notifications[index].id,
        type: _notifications[index].type,
        title: _notifications[index].title,
        message: _notifications[index].message,
        data: _notifications[index].data,
        timestamp: _notifications[index].timestamp,
        isRead: true,
        icon: _notifications[index].icon,
      );

      _notifications[index] = updatedNotification;
      _notificationsListController.add(List.from(_notifications));
      _updateUnreadCount();
    }
  }

  void markAllAsRead() {
    final updatedNotifications = _notifications.map((notification) {
      return RealTimeNotification(
        id: notification.id,
        type: notification.type,
        title: notification.title,
        message: notification.message,
        data: notification.data,
        timestamp: notification.timestamp,
        isRead: true,
        icon: notification.icon,
      );
    }).toList();

    _notifications.clear();
    _notifications.addAll(updatedNotifications);
    _notificationsListController.add(List.from(_notifications));
    _updateUnreadCount();
  }

  void removeNotification(String notificationId) {
    _notifications.removeWhere((n) => n.id == notificationId);
    _notificationsListController.add(List.from(_notifications));
    _updateUnreadCount();
  }

  void clearAllNotifications() {
    _notifications.clear();
    _notificationsListController.add([]);
    _updateUnreadCount();
  }

  void _updateUnreadCount() {
    _unreadCountController.add(unreadNotificationsCount);
  }

  void dispose() {
    _websocketSubscription?.cancel();
    _notificationController.close();
    _notificationsListController.close();
    _unreadCountController.close();
  }
}
