import 'package:flutter/material.dart';
import '../../../services/websocket_service.dart';
import './connection_status_indicator.dart';

class LiveParticipantList extends StatelessWidget {
  final String? title;
  final double maxHeight;
  final bool showConnectionStatus;

  const LiveParticipantList({
    super.key,
    this.title,
    this.maxHeight = 200,
    this.showConnectionStatus = true,
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
                Expanded(
                  child: Text(
                    title ?? 'Participants',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (showConnectionStatus) ...[
                  const ConnectionStatusIndicator(),
                  const SizedBox(width: 8),
                ],
                StreamBuilder<List<Participant>>(
                  stream: websocketService.participants,
                  initialData: const [],
                  builder: (context, snapshot) {
                    final count = snapshot.data?.length ?? 0;
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF64A7FF).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$count',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF64A7FF),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          // Participant List
          SizedBox(
            height: maxHeight,
            child: StreamBuilder<List<Participant>>(
              stream: websocketService.participants,
              initialData: const [],
              builder: (context, snapshot) {
                final participants = snapshot.data ?? [];

                if (participants.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'No participants yet',
                        style: TextStyle(
                          color: Colors.grey,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  itemCount: participants.length,
                  itemBuilder: (context, index) {
                    final participant = participants[index];
                    return ParticipantListItem(participant: participant);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class ParticipantListItem extends StatelessWidget {
  final Participant participant;

  const ParticipantListItem({super.key, required this.participant});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFF64A7FF).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: participant.profilePictureUrl != null
                ? ClipOval(
                    child: Image.network(
                      participant.profilePictureUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          Icons.person,
                          size: 16,
                          color: const Color(0xFF64A7FF),
                        );
                      },
                    ),
                  )
                : Icon(Icons.person, size: 16, color: const Color(0xFF64A7FF)),
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
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (participant.score > 0) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Score: ${participant.score}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Rank
          if (participant.rank != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: _getRankColor(participant.rank!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '#${participant.rank}',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
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
