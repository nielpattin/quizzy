import "package:flutter/material.dart";
import "meta_chip.dart";

class GameSessionCard extends StatelessWidget {
  final String title;
  final String length;
  final String date;
  final bool isLive;
  final int joined; // playerCount - unique users
  final int plays; // participantCount - total plays
  final List<Color> gradient;
  final String? topic;
  final String? imageUrl;
  final VoidCallback? onTap;
  final VoidCallback? onHost;
  final VoidCallback? onEdit;
  const GameSessionCard({
    super.key,
    required this.title,
    required this.length,
    required this.date,
    required this.isLive,
    required this.joined,
    required this.plays,
    required this.gradient,
    this.topic,
    this.imageUrl,
    this.onTap,
    this.onHost,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final questions = int.tryParse(length.split(' ').first);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: scheme.primary.withValues(alpha: 0.08),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(14),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (imageUrl != null && imageUrl!.isNotEmpty)
                      Image.network(imageUrl!, fit: BoxFit.cover)
                    else
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: gradient,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                      ),
                    // Overlay gradient for readability
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.black.withValues(alpha: 0.1),
                            Colors.black.withValues(alpha: 0.0),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isLive ? Colors.green : Colors.grey[600],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              isLive ? "LIVE" : "ENDED",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          _OverflowMenu(
                            onHost: onHost,
                            onEdit: onEdit,
                            onView: onTap,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: scheme.onSurface,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      MetaChip(icon: Icons.schedule, label: date),
                      MetaChip(
                        icon: Icons.quiz,
                        label: questions != null ? "$questions Qs" : length,
                      ),
                      MetaChip(icon: Icons.people, label: "$joined joined"),
                      MetaChip(icon: Icons.play_circle, label: "$plays plays"),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OverflowMenu extends StatelessWidget {
  final VoidCallback? onHost;
  final VoidCallback? onEdit;
  final VoidCallback? onView;
  const _OverflowMenu({this.onHost, this.onEdit, this.onView});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: PopupMenuButton<String>(
        tooltip: 'More actions',
        icon: const Icon(Icons.more_vert, color: Colors.white, size: 18),
        itemBuilder: (context) {
          final items = <PopupMenuEntry<String>>[];
          if (onHost != null) {
            items.add(
              const PopupMenuItem<String>(
                value: 'host',
                child: ListTile(
                  leading: Icon(Icons.play_circle),
                  title: Text('Host'),
                ),
              ),
            );
          }
          if (onEdit != null) {
            items.add(
              const PopupMenuItem<String>(
                value: 'edit',
                child: ListTile(
                  leading: Icon(Icons.edit),
                  title: Text('Edit Session'),
                ),
              ),
            );
          }
          // Always allow viewing details as a fallback action
          items.add(
            const PopupMenuItem<String>(
              value: 'view',
              child: ListTile(
                leading: Icon(Icons.visibility),
                title: Text('View details'),
              ),
            ),
          );
          return items;
        },
        onSelected: (value) {
          if (value == 'host' && onHost != null) onHost!();
          if (value == 'edit' && onEdit != null) onEdit!();
          if (value == 'view') {
            if (onView != null) onView!();
          }
        },
      ),
    );
  }
}
