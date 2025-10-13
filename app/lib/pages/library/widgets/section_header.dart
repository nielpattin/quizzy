import "package:flutter/material.dart";
import "sort_button.dart";
import "../services/library_service.dart" show SortOption;

extension SortOptionX on SortOption {
  String get label => switch (this) {
    SortOption.newest => "Newest",
    SortOption.oldest => "Oldest",
    SortOption.mostPlayed => "Most Played",
    SortOption.alphabetical => "A–Z",
  };
  IconData get icon => switch (this) {
    SortOption.newest => Icons.fiber_new,
    SortOption.oldest => Icons.history,
    SortOption.mostPlayed => Icons.leaderboard,
    SortOption.alphabetical => Icons.sort_by_alpha,
  };
}

class SectionHeader extends StatelessWidget {
  final String title;
  final int? count;
  final bool showSort;
  final SortOption sort;
  final VoidCallback? onSortTap;
  final Widget? trailing;
  const SectionHeader({
    super.key,
    required this.title,
    required this.showSort,
    required this.sort,
    this.count,
    this.onSortTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: Row(
        children: [
          Expanded(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: scheme.onSurface,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (count != null) ...[
                  const SizedBox(width: 8),
                  _CountBadge(count: count!),
                ],
              ],
            ),
          ),
          if (showSort) SortButton(option: sort, onTap: onSortTap),
          if (trailing != null) ...[const SizedBox(width: 8), trailing!],
        ],
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  final int count;
  const _CountBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: scheme.primary.withValues(alpha: 0.35),
          width: 1,
        ),
      ),
      child: Text(
        count.toString(),
        style: TextStyle(
          color: scheme.primary,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
