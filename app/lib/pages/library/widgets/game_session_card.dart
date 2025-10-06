import "package:flutter/material.dart";
import "meta_chip.dart";

class GameSessionCard extends StatelessWidget {
  final String title;
  final String length;
  final String date;
  final bool isLive;
  final int joined;
  final List<Color> gradient;
  final String? topic;
  const GameSessionCard({
    super.key,
    required this.title,
    required this.length,
    required this.date,
    required this.isLive,
    required this.joined,
    required this.gradient,
    this.topic,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final questions = int.tryParse(length.split(' ').first);
    return Container(
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
          Expanded(
            flex: 6,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(14),
                ),
                gradient: LinearGradient(
                  colors: gradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Row(
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
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            flex: 5,
            child: Padding(
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
                  Flexible(
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        MetaChip(icon: Icons.schedule, label: date),
                        MetaChip(
                          icon: Icons.quiz,
                          label: questions != null ? "$questions Qs" : length,
                        ),
                        MetaChip(icon: Icons.group, label: "$joined joined"),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
