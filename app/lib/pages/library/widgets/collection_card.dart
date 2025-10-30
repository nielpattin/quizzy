import "package:flutter/material.dart";
import "meta_chip.dart";
import "../../../widgets/optimized_image.dart";

class CollectionCard extends StatelessWidget {
  final String title;
  final int quizCount;
  final String? imageUrl;
  final List<Color> gradient;
  const CollectionCard({
    super.key,
    required this.title,
    required this.quizCount,
    this.imageUrl,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
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
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 120,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(14),
              ),
            ),
            child: imageUrl != null && imageUrl!.isNotEmpty
                ? OptimizedImage(
                    imageUrl: imageUrl!,
                    width: double.infinity,
                    height: 120,
                    fit: BoxFit.cover,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(14),
                    ),
                  )
                : Container(
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
          Padding(
            padding: const EdgeInsets.all(12),
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
                MetaChip(icon: Icons.quiz, label: "$quizCount quizzes"),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
