import "dart:async";
import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "package:supabase_flutter/supabase_flutter.dart";
import "../../services/api_service.dart";
import "widgets/featured_card.dart";
import "widgets/topic_card.dart";
import "widgets/trending_card.dart";
import "widgets/continue_playing_item.dart";

class QuizzyTab extends StatefulWidget {
  const QuizzyTab({super.key});

  @override
  State<QuizzyTab> createState() => _QuizzyTabState();
}

class _QuizzyTabState extends State<QuizzyTab>
    with AutomaticKeepAliveClientMixin {
  Future<Map<String, dynamic>>? _dataFuture;
  late PageController _featuredPageController;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _featuredPageController = PageController(initialPage: 10000);
    _dataFuture = _loadData();
  }

  @override
  void dispose() {
    _featuredPageController.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>> _loadData() async {
    final featured = await ApiService.getFeaturedQuizzes();
    final trending = await ApiService.getTrendingQuizzes();
    final categories = await ApiService.getCategories();
    final userId = Supabase.instance.client.auth.currentUser?.id;

    List<dynamic> continuePlaying = [];
    if (userId != null) {
      try {
        final playedSessions = await ApiService.getPlayedSessions(userId);
        continuePlaying = playedSessions
            .where((s) => s["endedAt"] == null)
            .toList();
      } catch (e) {
        debugPrint("[QuizzyTab] Error loading continue playing: $e");
      }
    }

    return {
      'featured': featured,
      'trending': trending,
      'continuePlaying': continuePlaying,
      'categories': categories,
    };
  }

  Future<void> _refresh() async {
    debugPrint("[QuizzyTab] Refreshing Quizzy tab...");
    setState(() {
      _dataFuture = _loadData();
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return FutureBuilder<Map<String, dynamic>>(
      future: _dataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(strokeWidth: 2));
        }

        if (snapshot.hasError) {
          debugPrint("[QuizzyTab] Error loading data: ${snapshot.error}");
          return Center(
            child: Text(
              'Error loading data',
              style: TextStyle(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          );
        }

        final data = snapshot.data ?? {};
        final featured = data['featured'] as List<dynamic>? ?? [];
        final trending = data['trending'] as List<dynamic>? ?? [];
        final continuePlaying = data['continuePlaying'] as List<dynamic>? ?? [];
        final categories = data['categories'] as List<dynamic>? ?? [];

        return RefreshIndicator(
          onRefresh: _refresh,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.only(left: 16.0, right: 16.0, bottom: 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Featured Today",
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 16),
                if (featured.isNotEmpty)
                  SizedBox(
                    height: 220,
                    child: Stack(
                      children: [
                        PageView.builder(
                          controller: _featuredPageController,
                          itemCount: null,
                          padEnds: false,
                          pageSnapping: true,
                          itemBuilder: (context, index) {
                            final actualIndex = index % featured.length;
                            return Padding(
                              padding: const EdgeInsets.only(
                                bottom: 20.0,
                                left: 8.0,
                                right: 8.0,
                              ),
                              child: FeaturedCard(data: featured[actualIndex]),
                            );
                          },
                        ),
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: AnimatedBuilder(
                            animation: _featuredPageController,
                            builder: (context, child) {
                              double page = 0;
                              if (_featuredPageController.hasClients) {
                                page = _featuredPageController.page ?? 0;
                              }
                              final currentIndex = (page % featured.length)
                                  .round();
                              return Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(featured.length, (
                                  index,
                                ) {
                                  final isActive = index == currentIndex;
                                  return AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeOut,
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                    ),
                                    width: isActive ? 24 : 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: isActive
                                          ? Theme.of(
                                              context,
                                            ).colorScheme.primary
                                          : Theme.of(context)
                                                .colorScheme
                                                .onSurface
                                                .withValues(alpha: 0.3),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  );
                                }),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                SizedBox(height: 32),
                Text(
                  "Browse Categories",
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 16),
                SizedBox(
                  height: 100,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: categories.length,
                    separatorBuilder: (context, index) => SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final category = categories[index];
                      return SizedBox(
                        width: 120,
                        child: TopicCard(
                          label: category["name"] ?? "Unknown",
                          imageUrl: category["imageUrl"],
                          onTap: () =>
                              context.push("/category/${category["slug"]}"),
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Trending Now",
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.push("/trending"),
                      child: Row(
                        children: [
                          Text(
                            "View all",
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward,
                            color: Theme.of(context).colorScheme.primary,
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                SizedBox(
                  height: 180,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: trending.length,
                    separatorBuilder: (context, index) => SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final item = trending[index];
                      final user = item["user"] as Map<String, dynamic>?;
                      return TrendingCard(
                        title: item["title"] ?? "Untitled",
                        author: user?["fullName"] ?? "Unknown",
                        category: item["category"]?["name"] ?? "General",
                        count: item["questionCount"] ?? 0,
                        isSessions: item["isSessions"] ?? false,
                        quizId: item["id"]?.toString() ?? "1",
                        imageUrl: item["imageUrl"],
                        profilePictureUrl: user?["profilePictureUrl"],
                      );
                    },
                  ),
                ),
                SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Continue Playing",
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.push("/continue-playing"),
                      child: Row(
                        children: [
                          Text(
                            "View all",
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward,
                            color: Theme.of(context).colorScheme.primary,
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                if (continuePlaying.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest
                          .withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(
                          context,
                        ).colorScheme.outline.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.play_circle_outline,
                          size: 48,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.4),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No sessions in progress',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.8),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Start playing quizzes to see them here!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  ...continuePlaying.map((item) {
                    final session = item as Map<String, dynamic>;
                    final participant =
                        session["participant"] as Map<String, dynamic>?;
                    final isSoloSession =
                        session["hostId"] == null || participant != null;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: ContinuePlayingItem(
                        sessionId: session["id"]?.toString() ?? "",
                        title: session["title"] ?? "Untitled",
                        author: isSoloSession ? "You" : "Multiplayer",
                        category: isSoloSession ? "Solo" : "Multiplayer",
                        count: participant?["score"] ?? 0,
                        isLive: session["isLive"] ?? false,
                        score: participant?["score"],
                        rank: participant?["rank"],
                        code: session["code"],
                        estimatedMinutes: session["estimatedMinutes"],
                        joinedCount: session["joinedCount"],
                      ),
                    );
                  }),
                SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }
}
