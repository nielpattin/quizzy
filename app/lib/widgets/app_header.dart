import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "dart:async";
import "../services/real_time_notification_service.dart";

class AppHeader extends StatefulWidget {
  final String title;

  const AppHeader({super.key, required this.title});

  @override
  State<AppHeader> createState() => _AppHeaderState();
}

class _AppHeaderState extends State<AppHeader> {
  int _newNotificationCount = 0;
  StreamSubscription? _newCountSubscription;

  @override
  void initState() {
    super.initState();
    _listenToNewCount();
  }

  void _listenToNewCount() {
    // Listen to real-time new notification count updates
    final notificationService = RealTimeNotificationService();
    _newCountSubscription = notificationService.newCount.listen((count) {
      if (mounted) {
        setState(() {
          _newNotificationCount = count;
        });
      }
    });
  }

  @override
  void dispose() {
    _newCountSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              'images/Logo.png',
              width: 40,
              height: 40,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            widget.title,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: Icon(
              Icons.search,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            onPressed: () => context.push("/search"),
          ),
          IconButton(
            icon: Badge(
              label: Text(_newNotificationCount.toString()),
              isLabelVisible: _newNotificationCount > 0,
              child: Icon(
                Icons.notifications_outlined,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            onPressed: () async {
              // Mark as seen immediately
              final notificationService = RealTimeNotificationService();
              await notificationService.markAsSeen();

              if (!mounted) return;
              // ignore: use_build_context_synchronously
              await context.push("/notification");

              // Refetch count when returning (in case new ones arrived while page was open)
              notificationService.refreshNewCount();
            },
          ),
        ],
      ),
    );
  }
}
