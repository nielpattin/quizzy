import "package:flutter/material.dart";
import "../../services/api_service.dart";
import "../home/widgets/trending_card.dart";

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
                    final category = item["category"] as Map<String, dynamic>?;
                    return TrendingCard(
                      quizId: item["id"] ?? "",
                      title: item["title"] ?? "Untitled",
                      author: user?["fullName"] ?? "Unknown",
                      category: category?["name"] ?? "General",
                      count: item["questionCount"] ?? 0,
                      imageUrl: item["imageUrl"],
                      profilePictureUrl: user?["profilePictureUrl"],
                      playCount: item["playCount"] ?? 0,
                      createdAt: item["createdAt"],
                      isSessions: false,
                    );
                  },
                ),
              ),
            ),
    );
  }
}
