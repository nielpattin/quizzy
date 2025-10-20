import "package:flutter/material.dart";

class ProfileStats extends StatelessWidget {
  final Map<String, dynamic>? stats;
  final VoidCallback onFollowersPressed;
  final VoidCallback onFollowingPressed;
  final VoidCallback onQuizzesPressed;
  final VoidCallback onSessionsPressed;

  const ProfileStats({
    super.key,
    this.stats,
    required this.onFollowersPressed,
    required this.onFollowingPressed,
    required this.onQuizzesPressed,
    required this.onSessionsPressed,
  });

  @override
  Widget build(BuildContext context) {
    if (stats == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _StatItem(count: "...", label: "Followers", onTap: () {}),
            _StatItem(count: "...", label: "Following", onTap: () {}),
            _StatItem(count: "...", label: "Quizzes", onTap: () {}),
            _StatItem(count: "...", label: "Sessions", onTap: () {}),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatItem(
            count: "${stats!["followers"]}",
            label: "Followers",
            onTap: onFollowersPressed,
          ),
          _StatItem(
            count: "${stats!["following"]}",
            label: "Following",
            onTap: onFollowingPressed,
          ),
          _StatItem(
            count: "${stats!["quizzes"]}",
            label: "Quizzes",
            onTap: onQuizzesPressed,
          ),
          _StatItem(
            count: "${stats!["sessions"]}",
            label: "Sessions",
            onTap: onSessionsPressed,
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String count;
  final String label;
  final VoidCallback onTap;

  const _StatItem({
    required this.count,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
        child: Column(
          children: [
            Text(
              count,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.6),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
