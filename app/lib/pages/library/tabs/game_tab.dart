import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "../widgets/game_sub_tabs.dart";
import "../widgets/section_header.dart";
import "../widgets/quiz_play_card.dart";
import "../widgets/game_session_card.dart";
import "../services/library_service.dart";
import "../models/quiz.dart";
import "../models/game_session.dart";

class GameTab extends StatefulWidget {
  final int selectedSubTab;
  final Function(int) onSubTabChanged;
  final SortOption sort;
  final VoidCallback onSortTap;
  const GameTab({
    super.key,
    required this.selectedSubTab,
    required this.onSubTabChanged,
    required this.sort,
    required this.onSortTap,
  });

  @override
  State<GameTab> createState() => _GameTabState();
}

class _GameTabState extends State<GameTab> {
  int? _myGamesCount;
  int? _recentGamesCount;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey("game_tab"),
      children: [
        GameSubTabs(
          selected: widget.selectedSubTab,
          onChanged: widget.onSubTabChanged,
        ),
        SectionHeader(
          title: widget.selectedSubTab == 0 ? "My Games" : "Recent Games",
          count: widget.selectedSubTab == 0 ? _myGamesCount : _recentGamesCount,
          showSort: true,
          sort: widget.sort,
          onSortTap: widget.onSortTap,
        ),
        Expanded(
          child: _GameList(
            mine: widget.selectedSubTab == 0,
            sort: widget.sort,
            onCountChanged: (count) {
              if (mounted) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    if (widget.selectedSubTab == 0 && _myGamesCount != count) {
                      setState(() => _myGamesCount = count);
                    } else if (widget.selectedSubTab == 1 &&
                        _recentGamesCount != count) {
                      setState(() => _recentGamesCount = count);
                    }
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

class _GameList extends StatefulWidget {
  final bool mine;
  final SortOption sort;
  final Function(int) onCountChanged;
  const _GameList({
    required this.mine,
    required this.sort,
    required this.onCountChanged,
  });

  @override
  State<_GameList> createState() => _GameListState();
}

class _GameListState extends State<_GameList> {
  Future<Map<String, dynamic>>? _dataFuture;

  @override
  void initState() {
    super.initState();
    _dataFuture = _loadData();
  }

  @override
  void didUpdateWidget(_GameList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sort != widget.sort || oldWidget.mine != widget.mine) {
      setState(() {
        _dataFuture = _loadData();
      });
    }
  }

  Future<Map<String, dynamic>> _loadData() async {
    if (widget.mine) {
      final sessions = await LibraryService.fetchMySessions(widget.sort);
      return {'sessions': sessions, 'soloPlays': <Quiz>[]};
    } else {
      final results = await Future.wait([
        LibraryService.fetchSoloPlays(),
        LibraryService.fetchRecentSessions(widget.sort),
      ]);
      return {
        'soloPlays': results[0] as List<Quiz>,
        'sessions': results[1] as List<GameSession>,
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _dataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingSkeleton();
        }

        if (snapshot.hasError) {
          debugPrint("[GameTab] Error loading data: ${snapshot.error}");
          widget.onCountChanged(0);
          return Center(
            child: Text(
              "Error loading games",
              style: TextStyle(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          );
        }

        final gameData = snapshot.data ?? {};
        final soloPlays = gameData['soloPlays'] as List<Quiz>? ?? [];
        final sessions = gameData['sessions'] as List<GameSession>? ?? [];
        widget.onCountChanged(
          widget.mine ? sessions.length : soloPlays.length + sessions.length,
        );

        final data = <dynamic>[];
        if (widget.mine) {
          data.addAll(sessions);
        } else {
          data.addAll(soloPlays);
          data.addAll(sessions);
        }

        if (data.isEmpty) {
          return Center(
            child: Text(
              widget.mine ? "No games yet" : "No recent games",
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
          itemCount: data.length,
          itemBuilder: (context, i) {
            final item = data[i];
            if (item is GameSession) {
              return GameSessionCard(
                title: item.title,
                length: item.length,
                date: item.date,
                isLive: item.isLive,
                joined: item.joined,
                plays: item.plays,
                gradient: item.gradient,
                imageUrl: item.imageUrl,
                onTap: () {
                  // Always navigate to Session Details
                  context.go('/quiz/session/detail/${item.id}');
                },
                // Remove "Host" action - Session Detail now has host controls
                onHost: null,
                onEdit: widget.mine
                    ? () => context.push('/quiz/session/edit/${item.id}')
                    : null,
              );
            }

            final quiz = item as Quiz;
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
