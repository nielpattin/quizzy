import "dart:io";
import "package:flutter/material.dart";
import "package:flutter_local_notifications/flutter_local_notifications.dart";
import "package:go_router/go_router.dart";

class InAppNotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  static BuildContext? _context;

  static Future<void> initialize(BuildContext context) async {
    _context = context;

    const androidSettings = AndroidInitializationSettings(
      "@mipmap/ic_launcher",
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _notifications.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
      onDidReceiveNotificationResponse: _handleNotificationTap,
    );

    await requestPermissions();
  }

  static Future<bool> requestPermissions() async {
    if (Platform.isAndroid) {
      final androidPlugin = _notifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

      if (androidPlugin != null) {
        final granted = await androidPlugin.requestNotificationsPermission();
        return granted ?? false;
      }
    }
    return true;
  }

  static Future<void> showInAppNotification({
    required String title,
    required String body,
    required Map<String, dynamic> payload,
  }) async {
    debugPrint('[InAppNotification] showInAppNotification called');
    debugPrint('[InAppNotification] Title: $title');
    debugPrint('[InAppNotification] Body: $body');
    debugPrint('[InAppNotification] Payload: $payload');

    const androidDetails = AndroidNotificationDetails(
      "in_app_notifications",
      "In-App Notifications",
      channelDescription: "Real-time in-app notifications",
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    try {
      await _notifications.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title,
        body,
        details,
        payload: _encodePayload(payload),
      );
      debugPrint('[InAppNotification] Notification shown successfully');
    } catch (e) {
      debugPrint('[InAppNotification] ERROR showing notification: $e');
    }
  }

  static void _handleNotificationTap(NotificationResponse response) {
    if (_context == null || !_context!.mounted) return;

    final payload = _decodePayload(response.payload);
    if (payload == null) return;

    _navigateToContent(_context!, payload);
  }

  static void _navigateToContent(
    BuildContext context,
    Map<String, dynamic> payload,
  ) {
    final type = payload["type"] as String?;
    final relatedPostId = payload["relatedPostId"] as String?;
    final relatedUserId = payload["relatedUserId"] as String?;
    final relatedQuizId = payload["relatedQuizId"] as String?;

    switch (type) {
      case "like":
      case "comment":
      case "quiz_answer":
        if (relatedPostId != null) {
          context.push("/post/$relatedPostId");
        }
        break;
      case "follow":
      case "follow_request":
        if (relatedUserId != null) {
          context.push("/profile/$relatedUserId");
        }
        break;
      case "quiz_share":
      case "game_invite":
        if (relatedQuizId != null) {
          context.push("/quiz/$relatedQuizId");
        }
        break;
    }
  }

  static String _encodePayload(Map<String, dynamic> payload) {
    final buffer = StringBuffer();
    payload.forEach((key, value) {
      if (buffer.isNotEmpty) buffer.write("&");
      buffer.write("$key=${Uri.encodeComponent(value?.toString() ?? '')}");
    });
    return buffer.toString();
  }

  static Map<String, dynamic>? _decodePayload(String? payload) {
    if (payload == null || payload.isEmpty) return null;

    final map = <String, dynamic>{};
    for (final pair in payload.split("&")) {
      final parts = pair.split("=");
      if (parts.length == 2) {
        map[parts[0]] = Uri.decodeComponent(parts[1]);
      }
    }
    return map;
  }
}
