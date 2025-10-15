import "dart:async";
import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "feedy_page.dart";
import "../../widgets/bottom_nav.dart";
import "../../services/test_data_service.dart";

class HomePage extends StatefulWidget {
  final bool showBottomNav;
  const HomePage({super.key, this.showBottomNav = true});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedTab = 0;
  bool _isLoading = true;
  List<dynamic> _featured = [];
  List<dynamic> _trending = [];
  List<dynamic> _continuePlaying = [];
  List<dynamic> _topics = [];
  late PageController _featuredPageController;
  Timer? _autoPlayTimer;

  @override
  void initState() {
    super.initState();
    _featuredPageController = PageController(initialPage: 10000);
    _loadData();
  }

  void _startAutoPlay() {
    _autoPlayTimer?.cancel();
    _autoPlayTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_featuredPageController.hasClients && _featured.isNotEmpty) {
        final nextPage = (_featuredPageController.page ?? 0) + 1;
        _featuredPageController.animateToPage(
          nextPage.toInt(),
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _stopAutoPlay() {
    _autoPlayTimer?.cancel();
  }

  @override
  void dispose() {
    _stopAutoPlay();
    _featuredPageController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        TestDataService.getFeatured(),
        TestDataService.getTrending(),
        TestDataService.getContinuePlaying(),
        TestDataService.getTopics(),
      ]);

      if (mounted) {
        setState(() {
          _featured = results[0];
          _trending = results[1];
          _continuePlaying = results[2];
          _topics = results[3];
          _isLoading = false;
        });
        if (_featured.isNotEmpty) {
          _startAutoPlay();
        }
      }
    } catch (e) {
      debugPrint("[HomePage] Error loading data: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _refreshQuizzyTab() async {
    debugPrint("[HomePage] Refreshing Quizzy tab...");
    await _loadData();
  }

  IconData _getIconFromString(String iconName) {
    switch (iconName) {
      case "school":
        return Icons.school;
      case "games":
        return Icons.games;
      case "business":
        return Icons.business;
      case "science":
        return Icons.science;
      case "sports":
        return Icons.sports_soccer;
      case "music":
        return Icons.music_note;
      case "art":
        return Icons.palette;
      case "history":
        return Icons.history_edu;
      case "geography":
        return Icons.public;
      case "technology":
        return Icons.computer;
      default:
        return Icons.category;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.quiz,
                      color: Theme.of(context).colorScheme.onSurface,
                      size: 24,
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    "Quizzy",
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(
                      Icons.search,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    onPressed: () => context.push("/search"),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.notifications_outlined,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    onPressed: () => context.push("/notification"),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  _TabButton(
                    label: "Quizzy",
                    isSelected: _selectedTab == 0,
                    onTap: () => setState(() => _selectedTab = 0),
                  ),
                  SizedBox(width: 12),
                  _TabButton(
                    label: "Feedy",
                    isSelected: _selectedTab == 1,
                    onTap: () => setState(() => _selectedTab = 1),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24),
            Expanded(
              child: _selectedTab == 0
                  ? _isLoading
                        ? Center(child: CircularProgressIndicator())
                        : RefreshIndicator(
                            onRefresh: _refreshQuizzyTab,
                            child: SingleChildScrollView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16.0,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Featured Today",
                                    style: TextStyle(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurface,
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 16),
                                  if (_featured.isNotEmpty)
                                    GestureDetector(
                                      onPanDown: (_) => _stopAutoPlay(),
                                      onPanEnd: (_) => _startAutoPlay(),
                                      child: SizedBox(
                                        height: 220,
                                        child: Stack(
                                          children: [
                                            PageView.builder(
                                              controller:
                                                  _featuredPageController,
                                              itemCount: null,
                                              padEnds: false,
                                              pageSnapping: true,
                                              itemBuilder: (context, index) {
                                                final actualIndex =
                                                    index % _featured.length;
                                                return Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                        bottom: 20.0,
                                                        left: 8.0,
                                                        right: 8.0,
                                                      ),
                                                  child: _FeaturedCard(
                                                    data:
                                                        _featured[actualIndex],
                                                  ),
                                                );
                                              },
                                            ),
                                            Positioned(
                                              bottom: 0,
                                              left: 0,
                                              right: 0,
                                              child: AnimatedBuilder(
                                                animation:
                                                    _featuredPageController,
                                                builder: (context, child) {
                                                  double page = 0;
                                                  if (_featuredPageController
                                                      .hasClients) {
                                                    page =
                                                        _featuredPageController
                                                            .page ??
                                                        0;
                                                  }
                                                  final currentIndex =
                                                      (page % _featured.length)
                                                          .round();
                                                  return Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: List.generate(
                                                      _featured.length,
                                                      (index) {
                                                        final isActive =
                                                            index ==
                                                            currentIndex;
                                                        return AnimatedContainer(
                                                          duration:
                                                              const Duration(
                                                                milliseconds:
                                                                    300,
                                                              ),
                                                          curve: Curves.easeOut,
                                                          margin:
                                                              const EdgeInsets.symmetric(
                                                                horizontal: 4,
                                                              ),
                                                          width: isActive
                                                              ? 24
                                                              : 8,
                                                          height: 8,
                                                          decoration: BoxDecoration(
                                                            color: isActive
                                                                ? Theme.of(
                                                                        context,
                                                                      )
                                                                      .colorScheme
                                                                      .primary
                                                                : Theme.of(
                                                                        context,
                                                                      )
                                                                      .colorScheme
                                                                      .onSurface
                                                                      .withValues(
                                                                        alpha:
                                                                            0.3,
                                                                      ),
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  4,
                                                                ),
                                                          ),
                                                        );
                                                      },
                                                    ),
                                                  );
                                                },
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  SizedBox(height: 32),
                                  Text(
                                    "Browse Topics",
                                    style: TextStyle(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurface,
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 16),
                                  SizedBox(
                                    height: 100,
                                    child: ListView.separated(
                                      scrollDirection: Axis.horizontal,
                                      itemCount: _topics.length,
                                      separatorBuilder: (context, index) =>
                                          SizedBox(width: 12),
                                      itemBuilder: (context, index) {
                                        final topic = _topics[index];
                                        return SizedBox(
                                          width: 120,
                                          child: _TopicCard(
                                            label: topic["label"],
                                            icon: _getIconFromString(
                                              topic["icon"],
                                            ),
                                            onTap: () => context.push(
                                              "/category/${topic["label"]}",
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  SizedBox(height: 32),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        "Trending Now",
                                        style: TextStyle(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSurface,
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            context.push("/trending"),
                                        child: Row(
                                          children: [
                                            Text(
                                              "View all",
                                              style: TextStyle(
                                                color: Theme.of(
                                                  context,
                                                ).colorScheme.primary,
                                              ),
                                            ),
                                            SizedBox(width: 4),
                                            Icon(
                                              Icons.arrow_forward,
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.primary,
                                              size: 16,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 16),
                                  SizedBox(
                                    height: 200,
                                    child: ListView.separated(
                                      scrollDirection: Axis.horizontal,
                                      itemCount: _trending.length,
                                      separatorBuilder: (context, index) =>
                                          SizedBox(width: 12),
                                      itemBuilder: (context, index) {
                                        final item = _trending[index];
                                        return _TrendingCard(
                                          title: item["title"],
                                          author: item["author"],
                                          category: item["category"],
                                          count: item["count"],
                                          isSessions:
                                              item["isSessions"] ?? false,
                                        );
                                      },
                                    ),
                                  ),
                                  SizedBox(height: 32),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        "Continue Playing",
                                        style: TextStyle(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSurface,
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            context.push("/continue-playing"),
                                        child: Row(
                                          children: [
                                            Text(
                                              "View all",
                                              style: TextStyle(
                                                color: Theme.of(
                                                  context,
                                                ).colorScheme.primary,
                                              ),
                                            ),
                                            SizedBox(width: 4),
                                            Icon(
                                              Icons.arrow_forward,
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.primary,
                                              size: 16,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 16),
                                  ..._continuePlaying.map(
                                    (item) => Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 12.0,
                                      ),
                                      child: _ContinuePlayingItem(
                                        title: item["title"],
                                        author: item["author"],
                                        category: item["category"],
                                        count: item["count"],
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 24),
                                ],
                              ),
                            ),
                          )
                  : const FeedyPage(),
            ),
          ],
        ),
      ),
      bottomNavigationBar: widget.showBottomNav
          ? const BottomNav(selectedIndex: 0)
          : null,
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: isSelected
              ? null
              : Border.all(
                  color: Theme.of(context).colorScheme.primary,
                  width: 2,
                ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? Colors.white
                : Theme.of(context).colorScheme.primary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _FeaturedCard extends StatelessWidget {
  final Map<String, dynamic> data;

  const _FeaturedCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.push("/quiz/${data["id"] ?? "1"}"),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.grey[700]!, Colors.grey[900]!],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          data["category"],
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ),
                      const Spacer(),
                      if (data["type"] == "session")
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            "Sessions",
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    data["title"],
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        child: Icon(
                          Icons.person,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(width: 8),
                      Text(
                        data["author"],
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 14,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.copy, size: 12, color: Colors.white),
                            SizedBox(width: 4),
                            Text(
                              "${data["count"]}",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopicCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onTap;

  const _TopicCard({required this.label, required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: Theme.of(context).colorScheme.onSurface,
              size: 32,
            ),
            SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrendingCard extends StatelessWidget {
  final String title;
  final String author;
  final String category;
  final int count;
  final bool isSessions;

  const _TrendingCard({
    required this.title,
    required this.author,
    required this.category,
    required this.count,
    this.isSessions = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.push("/quiz/1"),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 160,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 100,
              decoration: BoxDecoration(
                color: Colors.grey[700],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        category,
                        style: TextStyle(color: Colors.white, fontSize: 11),
                      ),
                    ),
                  ),
                  if (isSessions)
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          "Sessions",
                          style: TextStyle(color: Colors.white, fontSize: 11),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                    ),
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 8,
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        child: Icon(
                          Icons.person,
                          size: 10,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          author,
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.6),
                            fontSize: 11,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.copy, size: 10, color: Colors.white),
                            SizedBox(width: 4),
                            Text(
                              "$count",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContinuePlayingItem extends StatelessWidget {
  final String title;
  final String author;
  final String category;
  final int count;

  const _ContinuePlayingItem({
    required this.title,
    required this.author,
    required this.category,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.push("/quiz/1"),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.grey[700],
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      category,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    title,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 8,
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        child: Icon(
                          Icons.person,
                          size: 10,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(width: 6),
                      Text(
                        author,
                        style: TextStyle(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.6),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.copy, size: 12, color: Colors.white),
                  SizedBox(width: 4),
                  Text(
                    "$count",
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
