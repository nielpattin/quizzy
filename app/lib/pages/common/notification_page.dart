import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "dart:async";
import "../../services/api_service.dart";
import "../../services/real_time_notification_service.dart";

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  List<dynamic> _notifications = [];
  bool _isLoading = true;
  final ScrollController _scrollController = ScrollController();
  int _currentOffset = 0;
  final int _pageSize = 10;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoading && _hasMore) {
        _loadMore();
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
      _currentOffset = 0;
      _notifications = [];
    });

    try {
      final notifications = await ApiService.getNotifications(
        limit: _pageSize,
        offset: 0,
      );
      setState(() {
        _notifications = notifications;
        _isLoading = false;
        _hasMore = notifications.length == _pageSize;
        _currentOffset = _pageSize;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error loading notifications: ${e.toString()}"),
          ),
        );
      }
    }
  }

  Future<void> _loadMore() async {
    if (_isLoading || !_hasMore) return;

    setState(() => _isLoading = true);

    try {
      final moreNotifications = await ApiService.getNotifications(
        limit: _pageSize,
        offset: _currentOffset,
      );

      setState(() {
        _notifications.addAll(moreNotifications);
        _currentOffset += _pageSize;
        _hasMore = moreNotifications.length == _pageSize;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _markAsRead(String notificationId) async {
    try {
      await ApiService.markAsRead(notificationId);
      setState(() {
        final index = _notifications.indexWhere(
          (n) => n["id"] == notificationId,
        );
        if (index != -1) {
          _notifications[index]["isUnread"] = false;
        }
      });

      // Refresh new count to update badge
      final notificationService = RealTimeNotificationService();
      notificationService.refreshNewCount();
    } catch (e) {
      // Silently ignore errors when marking as read
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      await ApiService.markAllAsRead();
      setState(() {
        for (var notification in _notifications) {
          notification["isUnread"] = false;
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: ${e.toString()}")));
      }
    }
  }

  Future<void> _deleteNotification(String notificationId) async {
    try {
      await ApiService.deleteNotification(notificationId);
      setState(() {
        _notifications.removeWhere((n) => n["id"] == notificationId);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: ${e.toString()}")));
      }
    }
  }

  void _navigateToRelatedContent(Map<String, dynamic> notification) {
    final type = notification["type"] as String?;
    final relatedPostId = notification["relatedPostId"] as String?;
    final relatedUserId = notification["relatedUserId"] as String?;
    final relatedQuizId = notification["relatedQuizId"] as String?;

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
          context.go("/profile/$relatedUserId");
        }
        break;
      case "quiz_share":
      case "game_invite":
        if (relatedQuizId != null) {
          context.push("/quiz/$relatedQuizId");
        }
        break;
      default:
        break;
    }
  }

  String _formatTime(String timestamp) {
    try {
      final createdAt = DateTime.parse(timestamp);
      final now = DateTime.now();
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
    } catch (e) {
      return "";
    }
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case "like":
        return Icons.favorite;
      case "comment":
        return Icons.comment;
      case "follow":
        return Icons.person_add;
      case "quiz_share":
        return Icons.share;
      case "game_invite":
        return Icons.gamepad;
      case "quiz_answer":
        return Icons.quiz;
      case "mention":
        return Icons.alternate_email;
      case "follow_request":
        return Icons.person_add_alt_1;
      case "system":
        return Icons.info;
      default:
        return Icons.notifications;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          "Notifications",
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.done_all,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            tooltip: "Mark all as read",
            onPressed: _markAllAsRead,
          ),
        ],
      ),
      body: _buildNotifications(),
    );
  }

  Widget _buildNotifications() {
    if (_isLoading && _notifications.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_off_outlined,
              size: 64,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              "No notifications",
              style: TextStyle(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.6),
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _notifications.length + (_isLoading && _hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        // Show loading indicator at the bottom
        if (index == _notifications.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            ),
          );
        }

        final notification = _notifications[index];
        return Dismissible(
          key: Key(notification["id"]),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          onDismissed: (_) => _deleteNotification(notification["id"]),
          child: GestureDetector(
            onTap: () {
              if (notification["isUnread"]) {
                _markAsRead(notification["id"]);
              }
              _navigateToRelatedContent(notification);
            },
            child: _NotificationItem(
              avatar: Icons.person,
              avatarColor: Theme.of(context).colorScheme.primary,
              title: notification["title"] ?? "",
              subtitle: notification["subtitle"] ?? "",
              time: _formatTime(notification["createdAt"]),
              isUnread: notification["isUnread"] ?? false,
              icon: _getNotificationIcon(notification["type"] ?? ""),
              relatedUser: notification["relatedUser"],
            ),
          ),
        );
      },
    );
  }
}

class _NotificationItem extends StatelessWidget {
  final IconData avatar;
  final Color avatarColor;
  final String title;
  final String subtitle;
  final String time;
  final bool isUnread;
  final IconData icon;
  final Map<String, dynamic>? relatedUser;

  const _NotificationItem({
    required this.avatar,
    required this.avatarColor,
    required this.title,
    required this.subtitle,
    required this.time,
    required this.isUnread,
    required this.icon,
    this.relatedUser,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isUnread
            ? Theme.of(context).colorScheme.surface
            : Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isUnread
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)
              : Colors.transparent,
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: avatarColor,
                backgroundImage: relatedUser?["profilePictureUrl"] != null
                    ? NetworkImage(relatedUser!["profilePictureUrl"])
                    : null,
                child: relatedUser?["profilePictureUrl"] == null
                    ? Icon(
                        avatar,
                        color: Theme.of(context).colorScheme.onSurface,
                        size: 24,
                      )
                    : null,
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    icon,
                    color: Theme.of(context).colorScheme.onSurface,
                    size: 12,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 15,
                          fontWeight: isUnread
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                    Text(
                      time,
                      style: TextStyle(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.54),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.6),
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (relatedUser != null) ...[
                  SizedBox(height: 4),
                  Text(
                    relatedUser!["username"] ??
                        relatedUser!["fullName"] ??
                        "User",
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (isUnread) ...[
            SizedBox(width: 8),
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
