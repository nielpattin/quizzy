import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "../widgets/section_header.dart";
import "../widgets/quiz_play_card.dart";
import "../services/library_service.dart";
import "../models/quiz.dart";

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

class _FavoritesList extends StatefulWidget {
  final SortOption sort;
  const _FavoritesList({required this.sort});

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
      }
    } catch (e) {
      debugPrint("[SavedTab] Error loading saved quizzes: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
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
          onTap: () => context.push("/quiz/${i % 2 == 0 ? '2' : '3'}"),
        );
      },
    );
  }
}
