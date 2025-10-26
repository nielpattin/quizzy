import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "dart:async";
import "quizzy_tab.dart";
import "feedy_tab.dart";
import "widgets/tab_button.dart";
import "../../services/real_time_notification_service.dart";

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedTab = 0;
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
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
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
                  SizedBox(width: 12),
                  Text(
                    "Quizzy",
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
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  TabButton(
                    label: "Quizzy",
                    isSelected: _selectedTab == 0,
                    onTap: () => setState(() => _selectedTab = 0),
                  ),
                  SizedBox(width: 12),
                  TabButton(
                    label: "Feedy",
                    isSelected: _selectedTab == 1,
                    onTap: () => setState(() => _selectedTab = 1),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24),
            Expanded(
              child: _selectedTab == 0 ? const QuizzyTab() : const FeedyTab(),
            ),
          ],
        ),
      ),
    );
  }
}
