import "package:flutter/material.dart";
import "package:go_router/go_router.dart";

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.onSurface),
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
            icon: Icon(Icons.done_all, color: Theme.of(context).colorScheme.onSurface),
            tooltip: "Mark all as read",
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: _TabButton(
                    label: "Notifications",
                    isSelected: _selectedTab == 0,
                    onTap: () => setState(() => _selectedTab = 0),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _TabButton(
                    label: "Friend Requests",
                    isSelected: _selectedTab == 1,
                    onTap: () => setState(() => _selectedTab = 1),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _selectedTab == 0
                ? _buildNotifications()
                : _buildFriendRequests(),
          ),
        ],
      ),
    );
  }

  Widget _buildNotifications() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: 10,
      itemBuilder: (context, index) {
        final isUnread = index < 3;
        return _NotificationItem(
          avatar: Icons.person,
          avatarColor: Colors.primaries[index % Colors.primaries.length],
          title: _getNotificationTitle(index),
          subtitle: _getNotificationSubtitle(index),
          time: _getNotificationTime(index),
          isUnread: isUnread,
          icon: _getNotificationIcon(index),
        );
      },
    );
  }

  Widget _buildFriendRequests() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: 5,
      itemBuilder: (context, index) {
        return _FriendRequestItem(
          name: "User ${index + 1}",
          username: "@user${index + 1}",
          mutualFriends: (index + 1) * 3,
          avatarColor: Colors.primaries[index % Colors.primaries.length],
        );
      },
    );
  }

  String _getNotificationTitle(int index) {
    final titles = [
      "Ly Nguyên liked your quiz",
      "Nhat Vi commented on your post",
      "New quiz in History collection",
      "You earned a new badge!",
      "Nhat Bao started following you",
      "Your quiz reached 1K plays",
      "Ly Nguyên invited you to a quiz",
      "New comment on your quiz",
      "Weekly summary is ready",
      "Nhat Simon shared your quiz",
    ];
    return titles[index % titles.length];
  }

  String _getNotificationSubtitle(int index) {
    final subtitles = [
      "Modern Art or Just Scribbles?",
      "That's an interesting take!",
      "Check out new quizzes in your favorite collection",
      "You've completed 50 quizzes!",
      "Nhat Bao is now following you",
      "Congratulations! Your quiz is trending",
      "Join the quiz challenge now",
      "Someone commented on What is the world of",
      "See how you performed this week",
      "Your quiz was shared 10 times",
    ];
    return subtitles[index % subtitles.length];
  }

  String _getNotificationTime(int index) {
    final times = [
      "2m ago",
      "15m ago",
      "1h ago",
      "2h ago",
      "5h ago",
      "1d ago",
      "2d ago",
      "3d ago",
      "1w ago",
      "2w ago",
    ];
    return times[index % times.length];
  }

  IconData _getNotificationIcon(int index) {
    final icons = [
      Icons.favorite,
      Icons.comment,
      Icons.collections_bookmark,
      Icons.military_tech,
      Icons.person_add,
      Icons.trending_up,
      Icons.mail,
      Icons.comment,
      Icons.bar_chart,
      Icons.share,
    ];
    return icons[index % icons.length];
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: isSelected ? null : Border.all(color: Theme.of(context).colorScheme.primary, width: 2),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Theme.of(context).colorScheme.primary,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
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

  const _NotificationItem({
    required this.avatar,
    required this.avatarColor,
    required this.title,
    required this.subtitle,
    required this.time,
    required this.isUnread,
    required this.icon,
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
                child: Icon(avatar, color: Theme.of(context).colorScheme.onSurface, size: 24),
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
                  child: Icon(icon, color: Theme.of(context).colorScheme.onSurface, size: 12),
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
                          fontWeight: isUnread ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ),
                    Text(
                      time,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
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

class _FriendRequestItem extends StatelessWidget {
  final String name;
  final String username;
  final int mutualFriends;
  final Color avatarColor;

  const _FriendRequestItem({
    required this.name,
    required this.username,
    required this.mutualFriends,
    required this.avatarColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: avatarColor,
                child: Icon(Icons.person, color: Theme.of(context).colorScheme.onSurface, size: 28),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      username,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      "$mutualFriends mutual friends",
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(
                    "Accept",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.surface,
                    foregroundColor: Theme.of(context).colorScheme.primary,
                    side: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(
                    "Decline",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
