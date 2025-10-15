import "package:flutter/material.dart";
import "../../services/test_data_service.dart";

class FeedyPage extends StatefulWidget {
  const FeedyPage({super.key});

  @override
  State<FeedyPage> createState() => _FeedyPageState();
}

class _FeedyPageState extends State<FeedyPage> {
  bool _isLoading = true;
  List<dynamic> _feedItems = [];

  @override
  void initState() {
    super.initState();
    _loadFeed();
  }

  Future<void> _loadFeed() async {
    try {
      final data = await TestDataService.getFeed();
      if (mounted) {
        setState(() {
          _feedItems = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("[FeedyPage] Error loading feed: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _refreshFeed() async {
    debugPrint("[FeedyPage] Refreshing feed...");
    setState(() {
      _isLoading = true;
    });
    await _loadFeed();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (_feedItems.isEmpty) {
      return Center(
        child: Text(
          "No feed items available",
          style: TextStyle(
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshFeed,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _feedItems.length,
        itemBuilder: (context, index) {
          final item = _feedItems[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: _FeedCard(
              author: item["author"],
              category: item["category"],
              question: item["question"],
              likes: item["likes"],
              comments: item["comments"],
              isAnswered: item["isAnswered"] ?? false,
            ),
          );
        },
      ),
    );
  }
}

class _FeedCard extends StatelessWidget {
  final String author;
  final String category;
  final String question;
  final int likes;
  final int comments;
  final bool isAnswered;

  const _FeedCard({
    required this.author,
    required this.category,
    required this.question,
    required this.likes,
    required this.comments,
    this.isAnswered = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: Icon(
                    Icons.person,
                    color: Theme.of(context).colorScheme.onSurface,
                    size: 24,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    author,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.54),
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    category,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              question,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 16,
                height: 1.4,
              ),
            ),
          ),
          SizedBox(height: 16),
          Container(
            height: 200,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.onSurface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Stack(
              children: [
                Center(
                  child: Icon(
                    Icons.pets,
                    size: 120,
                    color: Theme.of(context).colorScheme.surface,
                  ),
                ),
                if (isAnswered)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Icon(Icons.close, size: 100, color: Colors.red),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.favorite_border,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.7),
                      size: 24,
                    ),
                    SizedBox(width: 8),
                    Text(
                      "$likes",
                      style: TextStyle(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.7),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                SizedBox(width: 24),
                Row(
                  children: [
                    Icon(
                      Icons.chat_bubble_outline,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.7),
                      size: 24,
                    ),
                    SizedBox(width: 8),
                    Text(
                      "$comments",
                      style: TextStyle(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.7),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Icon(
                  Icons.share,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.7),
                  size: 24,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
