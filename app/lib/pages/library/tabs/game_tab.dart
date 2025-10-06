import "package:flutter/material.dart";
import "../widgets/game_sub_tabs.dart";
import "../widgets/section_header.dart";
import "../widgets/quiz_play_card.dart";
import "../widgets/game_session_card.dart";

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
          count: widget.selectedSubTab == 0 ? 6 : 12,
          showSort: true,
          sort: widget.sort,
          onSortTap: widget.onSortTap,
        ),
        Expanded(
          child: _GameList(mine: widget.selectedSubTab == 0, sort: widget.sort),
        ),
      ],
    );
  }
}

class _GameList extends StatelessWidget {
  final bool mine;
  final SortOption sort;
  const _GameList({required this.mine, required this.sort});

  @override
  Widget build(BuildContext context) {
    final quizPlays = [
      (
        title: "Daily Geography Sprint",
        time: "1d",
        qs: 10,
        plays: 234,
        gradient: [Colors.orange[300]!, Colors.brown[400]!],
      ),
      (
        title: "Quick Space Facts",
        time: "2d",
        qs: 8,
        plays: 156,
        gradient: [Colors.blue[300]!, Colors.indigo[400]!],
      ),
      (
        title: "Music Year Match",
        time: "4d",
        qs: 12,
        plays: 89,
        gradient: [Colors.purple[300]!, Colors.blue[400]!],
      ),
    ];
    final sessionData = [
      (
        title:
            "World History Marathon: Ancient Civilizations Through Modern Times",
        topic: "History",
        length: "25 Questions",
        date: "1d",
        isOngoing: true,
        joined: 142,
        gradient: [Colors.deepOrange[400]!, Colors.brown[700]!],
      ),
      (
        title: "Quick Math Challenge",
        topic: "Mathematics",
        length: "10 Questions",
        date: "2d",
        isOngoing: false,
        joined: 67,
        gradient: [Colors.blue[400]!, Colors.indigo[700]!],
      ),
      (
        title: "Ultimate Pop Culture Trivia Night Extravaganza 2024 Edition",
        topic: "Entertainment",
        length: "30 Questions",
        date: "3d",
        isOngoing: true,
        joined: 201,
        gradient: [Colors.pink[400]!, Colors.purple[700]!],
      ),
      (
        title: "Science Lightning Round",
        topic: "Science",
        length: "15 Questions",
        date: "5d",
        isOngoing: false,
        joined: 156,
        gradient: [Colors.green[400]!, Colors.teal[700]!],
      ),
      (
        title:
            "Geography Expert Challenge: Exploring Every Continent and Ocean",
        topic: "Geography",
        length: "40 Questions",
        date: "7d",
        isOngoing: false,
        joined: 289,
        gradient: [Colors.cyan[400]!, Colors.blue[800]!],
      ),
    ];

    final data =
        <
          ({
            String kind,
            String title,
            String time,
            int qs,
            List<Color> gradient,
            bool? live,
            int? joined,
            String? length,
            int? plays,
          })
        >[];
    if (mine) {
      for (final s in sessionData) {
        data.add((
          kind: 'session',
          title: s.title,
          time: s.date,
          qs: int.tryParse(s.length.split(' ').first) ?? 0,
          gradient: s.gradient,
          live: s.isOngoing,
          joined: s.joined,
          length: s.length,
          plays: null,
        ));
      }
    } else {
      for (final q in quizPlays) {
        data.add((
          kind: 'quiz',
          title: q.title,
          time: q.time,
          qs: q.qs,
          gradient: q.gradient,
          live: null,
          joined: null,
          length: null,
          plays: q.plays,
        ));
      }
      for (final s in sessionData) {
        data.add((
          kind: 'session',
          title: s.title,
          time: s.date,
          qs: int.tryParse(s.length.split(' ').first) ?? 0,
          gradient: s.gradient,
          live: s.isOngoing,
          joined: s.joined,
          length: s.length,
          plays: null,
        ));
      }
      data.sort((a, b) {
        final na =
            int.tryParse(a.time.replaceAll(RegExp(r'[^0-9]'), '')) ?? 9999;
        final nb =
            int.tryParse(b.time.replaceAll(RegExp(r'[^0-9]'), '')) ?? 9999;
        return na.compareTo(nb);
      });
    }

    final crossAxisCount = 2;
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.65,
      ),
      itemCount: data.length,
      itemBuilder: (context, i) {
        final item = data[i];
        if (item.kind == 'session') {
          return GameSessionCard(
            title: item.title,
            length: item.length ?? "${item.qs} Questions",
            date: item.time,
            isLive: item.live ?? false,
            joined: item.joined ?? 0,
            gradient: item.gradient,
          );
        }
        return QuizPlayCard(
          title: item.title,
          timeAgo: item.time,
          questions: item.qs,
          plays: item.plays,
          gradient: item.gradient,
        );
      },
    );
  }
}
