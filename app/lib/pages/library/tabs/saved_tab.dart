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
              if (mounted && _savedCount != count) {
                setState(() => _savedCount = count);
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
  bool _isLoading = true;
  List<Quiz> _quizzes = [];

  @override
  void initState() {
    super.initState();
    _loadQuizzes();
  }

  @override
  void didUpdateWidget(_FavoritesList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sort != widget.sort) {
      _loadQuizzes();
    }
  }

  Future<void> _loadQuizzes() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final quizzes = await LibraryService.fetchSavedQuizzes(widget.sort);
      if (mounted) {
        setState(() {
          _quizzes = quizzes;
          _isLoading = false;
        });
        widget.onCountChanged(_quizzes.length);
      }
    } catch (e) {
      debugPrint("[SavedTab] Error loading saved quizzes: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        widget.onCountChanged(0);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (_quizzes.isEmpty) {
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
      itemCount: _quizzes.length,
      itemBuilder: (context, i) {
        final quiz = _quizzes[i];
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
  }
}
