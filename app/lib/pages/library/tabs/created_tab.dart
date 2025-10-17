import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "../widgets/created_sub_tabs.dart";
import "../widgets/section_header.dart";
import "../widgets/collection_card.dart";
import "../widgets/quiz_play_card.dart";
import "../services/library_service.dart";
import "../models/quiz.dart";
import "../models/collection.dart";

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

class _QuizzesList extends StatefulWidget {
  final SortOption sort;
  const _QuizzesList({required this.sort});

  @override
  State<_QuizzesList> createState() => _QuizzesListState();
}

class _QuizzesListState extends State<_QuizzesList> {
  bool _isLoading = true;
  List<Quiz> _quizzes = [];

  @override
  void initState() {
    super.initState();
    _loadQuizzes();
  }

  @override
  void didUpdateWidget(_QuizzesList oldWidget) {
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
      final quizzes = await LibraryService.fetchCreatedQuizzes(widget.sort);
      if (mounted) {
        setState(() {
          _quizzes = quizzes;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("[CreatedTab] Error loading quizzes: $e");
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
          "No quizzes yet",
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

class _CollectionsList extends StatefulWidget {
  const _CollectionsList();

  @override
  State<_CollectionsList> createState() => _CollectionsListState();
}

class _CollectionsListState extends State<_CollectionsList> {
  bool _isLoading = true;
  List<Collection> _collections = [];

  @override
  void initState() {
    super.initState();
    _loadCollections();
  }

  Future<void> _loadCollections() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final collections = await LibraryService.fetchCollections();
      if (mounted) {
        setState(() {
          _collections = collections;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("[CreatedTab] Error loading collections: $e");
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

    if (_collections.isEmpty) {
      return Center(
        child: Text(
          "No collections yet",
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
        childAspectRatio: 0.85,
      ),
      itemCount: _collections.length,
      itemBuilder: (context, i) {
        final collection = _collections[i];
        return CollectionCard(
          title: collection.title,
          quizCount: collection.quizCount,
          gradient: collection.gradient,
        );
      },
    );
  }
}
