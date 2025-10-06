import "package:flutter/material.dart";
import "meta_chip.dart";

class QuizPlayCard extends StatelessWidget {
  final String title;
  final String timeAgo;
  final int questions;
  final int? plays;
  final List<Color> gradient;
  final VoidCallback? onTap;
  const QuizPlayCard({
    super.key,
    required this.title,
    required this.timeAgo,
    required this.questions,
    required this.plays,
    required this.gradient,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
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
                          MetaChip(icon: Icons.schedule, label: timeAgo),
                          MetaChip(icon: Icons.quiz, label: "$questions Qs"),
                          if (plays != null)
                            MetaChip(
                              icon: Icons.play_arrow,
                              label: "$plays plays",
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
