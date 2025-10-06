import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "../widgets/created_sub_tabs.dart";
import "../widgets/section_header.dart";
import "../widgets/collection_card.dart";
import "../widgets/quiz_play_card.dart";
import "../utils/gradients.dart";

class CreatedTab extends StatefulWidget {
  final int selectedSubTab;
  final Function(int) onSubTabChanged;
  final SortOption sort;
  final VoidCallback onSortTap;
  const CreatedTab({
    super.key,
    required this.selectedSubTab,
    required this.onSubTabChanged,
    required this.sort,
    required this.onSortTap,
  });

  @override
  State<CreatedTab> createState() => _CreatedTabState();
}

class _CreatedTabState extends State<CreatedTab> {
  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey("created_tab"),
      children: [
        CreatedSubTabs(
          selected: widget.selectedSubTab,
          onChanged: widget.onSubTabChanged,
        ),
        SectionHeader(
          title: widget.selectedSubTab == 0 ? "Quizzes" : "Collections",
          count: widget.selectedSubTab == 0 ? 30 : 5,
          showSort: widget.selectedSubTab == 0,
          sort: widget.sort,
          onSortTap: widget.onSortTap,
          trailing: widget.selectedSubTab == 1
              ? IconButton(
                  icon: Icon(
                    Icons.add_circle_outline,
                    color: Theme.of(context).colorScheme.primary,
                    size: 26,
                  ),
                  onPressed: () {},
                  tooltip: "New Collection",
                )
              : null,
        ),
        Expanded(
          child: widget.selectedSubTab == 0
              ? _QuizzesList(sort: widget.sort)
              : const _CollectionsList(),
        ),
      ],
    );
  }
}

class _QuizzesList extends StatelessWidget {
  final SortOption sort;
  const _QuizzesList({required this.sort});

  @override
  Widget build(BuildContext context) {
    final items = [
      (
        title: "Having Fun & Always Smile!",
        time: "1d",
        plays: 10,
        qs: 16,
        pub: true,
      ),
      (
        title: "Identify the Famous Painting",
        time: "2d",
        plays: 20,
        qs: 16,
        pub: false,
      ),
      (
        title: "Science Facts Everyone Gets Wrong",
        time: "3d",
        plays: 30,
        qs: 16,
        pub: true,
      ),
      (
        title: "Pop Culture Trivia 2024",
        time: "4d",
        plays: 40,
        qs: 16,
        pub: false,
      ),
      (title: "Geography Challenge", time: "5d", plays: 50, qs: 16, pub: true),
      (title: "Movie Quotes Master", time: "6d", plays: 60, qs: 16, pub: false),
      (title: "Music Legends Quiz", time: "7d", plays: 70, qs: 16, pub: true),
      (title: "Sports History", time: "8d", plays: 80, qs: 16, pub: false),
    ];

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.65,
      ),
      itemCount: items.length,
      itemBuilder: (context, i) {
        final it = items[i];
        return QuizPlayCard(
          title: it.title,
          timeAgo: it.time,
          questions: it.qs,
          plays: it.plays,
          gradient: gradientForIndex(i),
          onTap: () => context.push("/quiz/1"),
        );
      },
    );
  }
}

class _CollectionsList extends StatelessWidget {
  const _CollectionsList();

  @override
  Widget build(BuildContext context) {
    final cols = [
      ("Tech & Science", 24),
      ("Entertainment", 18),
      ("General Knowledge", 30),
      ("Sports & Games", 12),
      ("History & Geography", 16),
    ];
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: cols.length,
      itemBuilder: (context, i) {
        final c = cols[i];
        return CollectionCard(
          title: c.$1,
          quizCount: c.$2,
          gradient: gradientForIndex(i + 10),
        );
      },
    );
  }
}
