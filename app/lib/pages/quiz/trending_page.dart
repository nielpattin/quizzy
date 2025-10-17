import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "../../services/api_service.dart";

class TrendingPage extends StatefulWidget {
  const TrendingPage({super.key});

  @override
  State<TrendingPage> createState() => _TrendingPageState();
}

class _TrendingPageState extends State<TrendingPage> {
  bool _isLoading = true;
  List<dynamic> _trending = [];

  @override
  void initState() {
    super.initState();
    _loadTrendingQuizzes();
  }

  Future<void> _loadTrendingQuizzes() async {
    try {
      final trending = await ApiService.getTrendingQuizzes();
      if (mounted) {
        setState(() {
          _trending = trending;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("[TrendingPage] Error loading trending quizzes: $e");
      if (mounted) {
        setState(() {
          _trending = [];
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _refresh() async {
    await _loadTrendingQuizzes();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Trending Now",
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
      ),
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _trending.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.trending_up,
                      size: 80,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      "No Trending Quizzes",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "Check back later for the hottest quizzes!",
                      style: TextStyle(
                        fontSize: 16,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          : RefreshIndicator(
              onRefresh: _refresh,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.7,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: _trending.length,
                  itemBuilder: (context, index) {
                    final item = _trending[index];
                    final user = item["user"] as Map<String, dynamic>?;
                    return _TrendingCard(
                      title: item["title"] ?? "Untitled",
                      author: user?["fullName"] ?? "Unknown",
                      category: item["category"] ?? "General",
                      count: item["playCount"] ?? 0,
                      isSessions: item["isSessions"] ?? false,
                      onTap: () => context.push("/quiz/${item["id"] ?? "1"}"),
                    );
                  },
                ),
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
  final VoidCallback onTap;

  const _TrendingCard({
    required this.title,
    required this.author,
    required this.category,
    required this.count,
    this.isSessions = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
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
            ),
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 8,
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.primary,
                          child: Icon(
                            Icons.person,
                            size: 10,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 6),
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
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.copy, size: 10, color: Colors.white),
                          const SizedBox(width: 4),
                          Text(
                            "$count",
                            style: TextStyle(color: Colors.white, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
