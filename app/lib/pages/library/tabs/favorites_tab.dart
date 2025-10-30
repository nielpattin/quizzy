import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "../widgets/section_header.dart";
import "../widgets/quiz_play_card.dart";
import "../services/library_service.dart";
import "../models/quiz.dart";

class FavoritesTab extends StatefulWidget {
  final SortOption sort;
  final VoidCallback onSortTap;
  const FavoritesTab({super.key, required this.sort, required this.onSortTap});

  @override
  State<FavoritesTab> createState() => _FavoritesTabState();
}

class _FavoritesTabState extends State<FavoritesTab> {
  int? _favoritesCount;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey("favorites_tab"),
      children: [
        SectionHeader(
          title: "Favorites",
          count: _favoritesCount,
          showSort: true,
          sort: widget.sort,
          onSortTap: widget.onSortTap,
        ),
        Expanded(
          child: _FavoritesList(
            sort: widget.sort,
            onCountChanged: (count) {
              if (mounted) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted && _favoritesCount != count) {
                    setState(() => _favoritesCount = count);
                  }
                });
              }
            },
          ),
        ),
      ],
    );
  }
}

class _FavoritesList extends StatefulWidget {
  final SortOption sort;
  final Function(int) onCountChanged;
  const _FavoritesList({required this.sort, required this.onCountChanged});

  @override
  State<_FavoritesList> createState() => _FavoritesListState();
}

class _FavoritesListState extends State<_FavoritesList> {
  Future<List<Quiz>>? _quizzesFuture;

  @override
  void initState() {
    super.initState();
    _quizzesFuture = LibraryService.fetchFavoriteQuizzes(widget.sort);
  }

  @override
  void didUpdateWidget(_FavoritesList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sort != widget.sort) {
      setState(() {
        _quizzesFuture = LibraryService.fetchFavoriteQuizzes(widget.sort);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Quiz>>(
      future: _quizzesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingSkeleton();
        }

        if (snapshot.hasError) {
          debugPrint(
            "[FavoritesTab] Error loading favorite quizzes: ${snapshot.error}",
          );
          widget.onCountChanged(0);
          return Center(
            child: Text(
              "Error loading favorite quizzes",
              style: TextStyle(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          );
        }

        final quizzes = snapshot.data ?? [];
        widget.onCountChanged(quizzes.length);

        if (quizzes.isEmpty) {
          return Center(
            child: Text(
              "No favorite quizzes yet",
              style: TextStyle(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.65,
          ),
          itemCount: quizzes.length,
          itemBuilder: (context, i) {
            final quiz = quizzes[i];
            return QuizPlayCard(
              title: quiz.title,
              timeAgo: quiz.timeAgo,
              questions: quiz.questions,
              plays: quiz.plays,
              gradient: quiz.gradient,
              onTap: () => context.push("/quiz/${quiz.id}"),
            );
          },
        );
      },
    );
  }

  Widget _buildLoadingSkeleton() {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.65,
      ),
      itemCount: 6,
      itemBuilder: (context, i) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
          ),
        );
      },
    );
  }
}
