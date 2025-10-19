import 'package:flutter/material.dart';
import '../../../services/websocket_service.dart';

class LiveLeaderboard extends StatelessWidget {
  final String? title;
  final int maxItems;
  final bool showTopThreeOnly;

  const LiveLeaderboard({
    super.key,
    this.title,
    this.maxItems = 10,
    this.showTopThreeOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    final websocketService = WebSocketService();
    final theme = Theme.of(context);

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.emoji_events, color: Colors.amber, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title ?? 'Leaderboard',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                StreamBuilder<List<Participant>>(
                  stream: websocketService.leaderboard,
                  initialData: const [],
                  builder: (context, snapshot) {
                    final count = snapshot.data?.length ?? 0;
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$count',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.amber[700],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          // Leaderboard List
          StreamBuilder<List<Participant>>(
            stream: websocketService.leaderboard,
            initialData: const [],
            builder: (context, snapshot) {
              final leaderboard = snapshot.data ?? [];

              if (leaderboard.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'No scores yet',
                      style: TextStyle(
                        color: Colors.grey,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                );
              }

              final displayList = showTopThreeOnly
                  ? leaderboard.take(3).toList()
                  : leaderboard.take(maxItems).toList();

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: displayList.length,
                itemBuilder: (context, index) {
                  final participant = displayList[index];
                  final rank = index + 1;
                  return LeaderboardItem(
                    participant: participant,
                    rank: rank,
                    isCurrentUser: false, // TODO: Add current user detection
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

class LeaderboardItem extends StatelessWidget {
  final Participant participant;
  final int rank;
  final bool isCurrentUser;

  const LeaderboardItem({
    super.key,
    required this.participant,
    required this.rank,
    this.isCurrentUser = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isCurrentUser
            ? const Color(0xFF64A7FF).withValues(alpha: 0.1)
            : (rank <= 3 ? _getRankColor(rank).withValues(alpha: 0.1) : null),
        borderRadius: BorderRadius.circular(8),
        border: isCurrentUser
            ? Border.all(color: const Color(0xFF64A7FF), width: 2)
            : null,
      ),
      child: Row(
        children: [
          // Rank
          SizedBox(
            width: 32,
            child: Text(
              '#$rank',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: rank <= 3 ? _getRankColor(rank) : Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 12),

          // Avatar
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _getRankColor(rank).withValues(alpha: 0.2),
              shape: BoxShape.circle,
              border: rank <= 3
                  ? Border.all(color: _getRankColor(rank), width: 2)
                  : null,
            ),
            child: participant.profilePictureUrl != null
                ? ClipOval(
                    child: Image.network(
                      participant.profilePictureUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          Icons.person,
                          size: 18,
                          color: _getRankColor(rank),
                        );
                      },
                    ),
                  )
                : Icon(Icons.person, size: 18, color: _getRankColor(rank)),
          ),
          const SizedBox(width: 12),

          // User info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  participant.fullName ?? participant.username,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: isCurrentUser
                        ? FontWeight.bold
                        : FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (isCurrentUser) ...[
                  const SizedBox(height: 2),
                  Text(
                    'You',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF64A7FF),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Score
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${participant.score}',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF64A7FF),
                ),
              ),
              Text(
                'pts',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getRankColor(int rank) {
    if (rank == 1) return Colors.amber;
    if (rank == 2) return Colors.grey[400]!;
    if (rank == 3) return Colors.brown[400]!;
    return Colors.grey[600]!;
  }
}
