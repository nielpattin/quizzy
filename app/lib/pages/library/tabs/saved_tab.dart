import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "../widgets/section_header.dart";
import "../widgets/quiz_play_card.dart";
import "../services/library_service.dart";
import "../models/quiz.dart";

class SavedTab extends StatefulWidget {
  final SortOption sort;
  final VoidCallback onSortTap;
  const SavedTab({super.key, required this.sort, required this.onSortTap});

  @override
  State<SavedTab> createState() => _SavedTabState();
}

class _SavedTabState extends State<SavedTab> {
  int? _savedCount;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey("saved_tab"),
      children: [
        SectionHeader(
          title: "Saved",
          count: _savedCount,
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
                  if (mounted && _savedCount != count) {
                    setState(() => _savedCount = count);
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

class _FavoritesListState extends State<_FavoritesList>
    with AutomaticKeepAliveClientMixin {
  Future<List<Quiz>>? _quizzesFuture;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _quizzesFuture = LibraryService.fetchSavedQuizzes(widget.sort);
  }

  @override
  void didUpdateWidget(_FavoritesList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sort != widget.sort) {
      setState(() {
        _quizzesFuture = LibraryService.fetchSavedQuizzes(widget.sort);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return FutureBuilder<List<Quiz>>(
      future: _quizzesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingSkeleton();
        }

        if (snapshot.hasError) {
          debugPrint(
            "[SavedTab] Error loading saved quizzes: ${snapshot.error}",
          );
          widget.onCountChanged(0);
          return Center(
            child: Text(
              "Error loading saved quizzes",
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
              "No saved quizzes yet",
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
