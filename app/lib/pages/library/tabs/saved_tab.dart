import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "../widgets/section_header.dart";
import "../widgets/quiz_play_card.dart";
import "../utils/gradients.dart";

class SavedTab extends StatelessWidget {
  final SortOption sort;
  final VoidCallback onSortTap;
  const SavedTab({super.key, required this.sort, required this.onSortTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey("saved_tab"),
      children: [
        SectionHeader(
          title: "Saved",
          count: 18,
          showSort: true,
          sort: sort,
          onSortTap: onSortTap,
        ),
        Expanded(child: _FavoritesList(sort: sort)),
      ],
    );
  }
}

class _FavoritesList extends StatelessWidget {
  final SortOption sort;
  const _FavoritesList({required this.sort});

  @override
  Widget build(BuildContext context) {
    final favs = [
      ("World Capitals Master", "2d", 526, 20),
      ("Classic Literature Quiz", "3d", 1052, 20),
      ("90s Movies Trivia", "4d", 1578, 20),
      ("Ancient Civilizations", "5d", 893, 20),
      ("Modern Tech Innovations", "6d", 742, 20),
      ("Food & Cuisine Around the World", "7d", 431, 20),
    ];
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.65,
      ),
      itemCount: favs.length,
      itemBuilder: (context, i) {
        final f = favs[i];
        return QuizPlayCard(
          title: f.$1,
          timeAgo: f.$2,
          questions: f.$4,
          plays: f.$3,
          gradient: gradientForIndex(i + 3),
          onTap: () => context.push("/quiz/${i % 2 == 0 ? '2' : '3'}"),
        );
      },
    );
  }
}
