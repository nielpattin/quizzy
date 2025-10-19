import "package:flutter/material.dart";
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
                if (widget.selectedSubTab == 0 && _myGamesCount != count) {
                  setState(() => _myGamesCount = count);
                } else if (widget.selectedSubTab == 1 &&
                    _recentGamesCount != count) {
                  setState(() => _recentGamesCount = count);
                }
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
  bool _isLoading = true;
  List<Quiz> _soloPlays = [];
  List<GameSession> _sessions = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void didUpdateWidget(_GameList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sort != widget.sort || oldWidget.mine != widget.mine) {
      _loadData();
    }
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });
    try {
      if (widget.mine) {
        final sessions = await LibraryService.fetchMySessions(widget.sort);
        if (mounted) {
          setState(() {
            _sessions = sessions;
            _soloPlays = [];
            _isLoading = false;
          });
          widget.onCountChanged(_sessions.length);
        }
      } else {
        final results = await Future.wait([
          LibraryService.fetchSoloPlays(),
          LibraryService.fetchRecentSessions(widget.sort),
        ]);
        if (mounted) {
          setState(() {
            _soloPlays = results[0] as List<Quiz>;
            _sessions = results[1] as List<GameSession>;
            _isLoading = false;
          });
          widget.onCountChanged(_soloPlays.length + _sessions.length);
        }
      }
    } catch (e) {
      debugPrint("[GameTab] Error loading data: $e");
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

    final data = <dynamic>[];
    if (widget.mine) {
      data.addAll(_sessions);
    } else {
      data.addAll(_soloPlays);
      data.addAll(_sessions);
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
            gradient: item.gradient,
          );
        }
        final quiz = item as Quiz;
        return QuizPlayCard(
          title: quiz.title,
          timeAgo: quiz.timeAgo,
          questions: quiz.questions,
          plays: quiz.plays,
          gradient: quiz.gradient,
        );
      },
    );
  }
}
