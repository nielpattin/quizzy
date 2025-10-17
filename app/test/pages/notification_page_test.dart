import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quizzy/pages/common/notification_page.dart';
import '../helpers/test_helpers.dart';

void main() {
  group('Notification Page Data Tests', () {
    test('should handle empty notifications', () {
      final notifications = <dynamic>[];
      expect(notifications.isEmpty, true);
    });

    test('should filter unread notifications', () {
      final notifications = [
        createMockNotification(isUnread: true),
        createMockNotification(isUnread: false),
        createMockNotification(isUnread: true),
      ];

      final unread = notifications.where((n) => n["isUnread"] == true).toList();

      expect(unread.length, 2);
    });

    test('should format notification time', () {
      final now = DateTime.now();
      final twoMinutesAgo = now.subtract(Duration(minutes: 2));
      final oneHourAgo = now.subtract(Duration(hours: 1));
      final twoDaysAgo = now.subtract(Duration(days: 2));

      String formatTime(DateTime createdAt) {
        final difference = now.difference(createdAt);

        if (difference.inMinutes < 60) {
          return "${difference.inMinutes}m ago";
        } else if (difference.inHours < 24) {
          return "${difference.inHours}h ago";
        } else if (difference.inDays < 7) {
          return "${difference.inDays}d ago";
        } else {
          return "${(difference.inDays / 7).floor()}w ago";
        }
      }

      expect(formatTime(twoMinutesAgo), "2m ago");
      expect(formatTime(oneHourAgo), "1h ago");
      expect(formatTime(twoDaysAgo), "2d ago");
    });

    test('should handle notification types', () {
      final types = ["like", "comment", "follow", "quiz"];

      for (final type in types) {
        final notification = createMockNotification();
        notification["type"] = type;
        expect(notification["type"], type);
      }
    });

    test('should mark notification as read', () {
      final notification = createMockNotification(isUnread: true);
      expect(notification["isUnread"], true);

      notification["isUnread"] = false;
      expect(notification["isUnread"], false);
    });
  });

  group('Notification Actions Tests', () {
    test('should mark all as read', () {
      final notifications = [
        createMockNotification(isUnread: true),
        createMockNotification(isUnread: true),
        createMockNotification(isUnread: true),
      ];

      for (var notif in notifications) {
        notif["isUnread"] = false;
      }

      final allRead = notifications.every((n) => n["isUnread"] == false);
      expect(allRead, true);
    });

    test('should delete notification from list', () {
      final notifications = [
        createMockNotification(id: "1"),
        createMockNotification(id: "2"),
        createMockNotification(id: "3"),
      ];

      notifications.removeWhere((n) => n["id"] == "2");

      expect(notifications.length, 2);
      expect(notifications.any((n) => n["id"] == "2"), false);
    });
  });

  group('NotificationPage Widget Tests', () {
    testWidgets('should render loading indicator initially', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(MaterialApp(home: NotificationPage()));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should display NotificationPage title', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(MaterialApp(home: NotificationPage()));

      // Find the AppBar title specifically (larger font size)
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Text &&
              widget.data == 'Notifications' &&
              widget.style?.fontSize == 20.0,
        ),
        findsOneWidget,
      );
    });

    testWidgets('should have Notifications and Friend Requests tabs', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(MaterialApp(home: NotificationPage()));

      expect(
        find.text('Notifications'),
        findsAtLeastNWidgets(2),
      ); // Title + tab
      expect(find.text('Friend Requests'), findsOneWidget);
    });

    testWidgets('should render empty state when no notifications', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(MaterialApp(home: NotificationPage()));

      await tester.pumpAndSettle(const Duration(seconds: 2));

      expect(find.textContaining('No notifications'), findsAny);
    });
  });
}
