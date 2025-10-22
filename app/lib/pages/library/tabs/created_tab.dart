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
  int? _quizzesCount;
  int? _collectionsCount;

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
          count: widget.selectedSubTab == 0 ? _quizzesCount : _collectionsCount,
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
              ? _QuizzesList(
                  sort: widget.sort,
                  onCountChanged: (count) {
                    if (mounted) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted && _quizzesCount != count) {
                          setState(() => _quizzesCount = count);
                        }
                      });
                    }
                  },
                )
              : _CollectionsList(
                  onCountChanged: (count) {
                    if (mounted) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted && _collectionsCount != count) {
                          setState(() => _collectionsCount = count);
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

class _QuizzesList extends StatefulWidget {
  final SortOption sort;
  final Function(int) onCountChanged;
  const _QuizzesList({required this.sort, required this.onCountChanged});

  @override
  State<_QuizzesList> createState() => _QuizzesListState();
}

class _QuizzesListState extends State<_QuizzesList>
    with AutomaticKeepAliveClientMixin {
  Future<List<Quiz>>? _quizzesFuture;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _quizzesFuture = LibraryService.fetchCreatedQuizzes(widget.sort);
  }

  @override
  void didUpdateWidget(_QuizzesList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sort != widget.sort) {
      setState(() {
        _quizzesFuture = LibraryService.fetchCreatedQuizzes(widget.sort);
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
          debugPrint("[CreatedTab] Error loading quizzes: ${snapshot.error}");
          widget.onCountChanged(0);
          return Center(
            child: Text(
              "Error loading quizzes",
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
          itemCount: quizzes.length,
          itemBuilder: (context, i) {
            final quiz = quizzes[i];
            return QuizPlayCard(
              title: quiz.title,
              timeAgo: quiz.timeAgo,
              questions: quiz.questions,
              plays: quiz.plays,
              imageUrl: quiz.imageUrl,
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

class _CollectionsList extends StatefulWidget {
  final Function(int) onCountChanged;
  const _CollectionsList({required this.onCountChanged});

  @override
  State<_CollectionsList> createState() => _CollectionsListState();
}

class _CollectionsListState extends State<_CollectionsList>
    with AutomaticKeepAliveClientMixin {
  Future<List<Collection>>? _collectionsFuture;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _collectionsFuture = LibraryService.fetchCollections();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return FutureBuilder<List<Collection>>(
      future: _collectionsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingSkeleton();
        }

        if (snapshot.hasError) {
          debugPrint(
            "[CreatedTab] Error loading collections: ${snapshot.error}",
          );
          widget.onCountChanged(0);
          return Center(
            child: Text(
              "Error loading collections",
              style: TextStyle(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          );
        }

        final collections = snapshot.data ?? [];
        widget.onCountChanged(collections.length);

        if (collections.isEmpty) {
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
          itemCount: collections.length,
          itemBuilder: (context, i) {
            final collection = collections[i];
            return CollectionCard(
              title: collection.title,
              quizCount: collection.quizCount,
              gradient: collection.gradient,
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
        childAspectRatio: 0.85,
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
