import 'package:flutter/material.dart';
import '../../../services/websocket_service.dart';

class SessionStatusIndicator extends StatelessWidget {
  final double size;

  const SessionStatusIndicator({super.key, this.size = 16});

  @override
  Widget build(BuildContext context) {
    final websocketService = WebSocketService();

    return StreamBuilder<LiveSession?>(
      stream: websocketService.session,
      initialData: null,
      builder: (context, snapshot) {
        final session = snapshot.data;

        if (session == null) {
          return _buildStatusIndicator(context, Colors.grey, 'No Session');
        }

        Color color;
        String tooltip;
        IconData icon;

        if (session.endedAt != null) {
          color = Colors.red;
          tooltip = 'Session Ended';
          icon = Icons.stop_circle;
        } else if (session.isLive && session.startedAt != null) {
          color = Colors.green;
          tooltip = 'Live';
          icon = Icons.play_circle;
        } else if (session.startedAt != null) {
          color = Colors.orange;
          tooltip = 'Paused';
          icon = Icons.pause_circle;
        } else {
          color = Colors.blue;
          tooltip = 'Waiting to Start';
          icon = Icons.schedule;
        }

        return Tooltip(
          message: tooltip,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: size, color: color),
              const SizedBox(width: 4),
              Text(
                tooltip,
                style: TextStyle(
                  fontSize: size * 0.75,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusIndicator(
    BuildContext context,
    Color color,
    String tooltip,
  ) {
    return Tooltip(
      message: tooltip,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
        ),
      ),
    );
  }
}

class SessionStatusCard extends StatelessWidget {
  final String? title;

  const SessionStatusCard({super.key, this.title});

  @override
  Widget build(BuildContext context) {
    final websocketService = WebSocketService();
    final theme = Theme.of(context);

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: const Color(0xFF64A7FF),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title ?? 'Session Status',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            StreamBuilder<LiveSession?>(
              stream: websocketService.session,
              initialData: null,
              builder: (context, snapshot) {
                final session = snapshot.data;

                if (session == null) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'No active session',
                        style: TextStyle(
                          color: Colors.grey,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Session title
                    Text(
                      session.title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),

                    // Status row
                    Row(
                      children: [
                        const SessionStatusIndicator(),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _getSessionStatusText(session),
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Session details
                    _buildSessionDetailRow(
                      context,
                      Icons.people,
                      'Participants',
                      '${session.participantCount}',
                    ),
                    if (session.code != null) ...[
                      const SizedBox(height: 8),
                      _buildSessionDetailRow(
                        context,
                        Icons.code,
                        'Code',
                        session.code!,
                      ),
                    ],
                    if (session.startedAt != null) ...[
                      const SizedBox(height: 8),
                      _buildSessionDetailRow(
                        context,
                        Icons.play_arrow,
                        'Started',
                        _formatDateTime(session.startedAt!),
                      ),
                    ],
                    if (session.endedAt != null) ...[
                      const SizedBox(height: 8),
                      _buildSessionDetailRow(
                        context,
                        Icons.stop,
                        'Ended',
                        _formatDateTime(session.endedAt!),
                      ),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionDetailRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          '$label:',
          style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  String _getSessionStatusText(LiveSession session) {
    if (session.endedAt != null) {
      return 'This session has ended';
    } else if (session.isLive && session.startedAt != null) {
      return 'Session is live and active';
    } else if (session.startedAt != null) {
      return 'Session is paused';
    } else {
      return 'Waiting for host to start';
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}
