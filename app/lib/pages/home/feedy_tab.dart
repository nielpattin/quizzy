import "package:flutter/material.dart";
import "../../services/api_service.dart";
import "widgets/feed_card.dart";

class FeedyTab extends StatefulWidget {
  const FeedyTab({super.key});

  @override
  State<FeedyTab> createState() => _FeedyTabState();
}

class _FeedyTabState extends State<FeedyTab> {
  bool _isLoading = true;
  List<dynamic> _feedItems = [];
  int _currentPage = 0;
  final int _pageSize = 20;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadFeed();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  Future<void> _loadFeed({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 0;
      setState(() {
        _feedItems = [];
        _isLoading = true;
      });
    }

    try {
      final data = await ApiService.getFeedPosts(
        limit: _pageSize,
        offset: _currentPage * _pageSize,
      );
      if (mounted) {
        setState(() {
          if (refresh) {
            _feedItems = data;
          } else {
            _feedItems.addAll(data);
          }
          _currentPage++;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("[FeedyTab] Error loading feed: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadMore() async {
    if (_isLoading) return;

    try {
      final data = await ApiService.getFeedPosts(
        limit: _pageSize,
        offset: _currentPage * _pageSize,
      );
      if (mounted && data.isNotEmpty) {
        setState(() {
          _feedItems.addAll(data);
          _currentPage++;
        });
      }
    } catch (e) {
      debugPrint("[FeedyTab] Error loading more feed: $e");
    }
  }

  Future<void> _refreshFeed() async {
    debugPrint("[FeedyTab] Refreshing feed...");
    await _loadFeed(refresh: true);
  }

  Future<void> _toggleLike(String postId, bool isLiked) async {
    try {
      if (isLiked) {
        await ApiService.unlikePost(postId);
      } else {
        await ApiService.likePost(postId);
      }

      setState(() {
        final post = _feedItems.firstWhere((p) => p["id"] == postId);
        post["likesCount"] = (post["likesCount"] ?? 0) + (isLiked ? -1 : 1);
        post["isLiked"] = !isLiked;
      });
    } catch (e) {
      debugPrint("[FeedyTab] Error toggling like: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _feedItems.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_feedItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.feed_outlined,
              size: 80,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              "No feed items available",
              style: TextStyle(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.6),
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Follow more users to see their posts",
              style: TextStyle(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.5),
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshFeed,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _feedItems.length + (_isLoading ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _feedItems.length) {
            return const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final item = _feedItems[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: FeedCard(
              postId: item["id"],
              author: item["user"]?["fullName"] ?? "Unknown",
              text: item["text"] ?? "",
              likes: item["likesCount"] ?? 0,
              comments: item["commentsCount"] ?? 0,
              isLiked: item["isLiked"] ?? false,
              onLike: () => _toggleLike(item["id"], item["isLiked"] ?? false),
              onTap: () {
                // Navigate to post details or user profile
                debugPrint("Tapped post: ${item["id"]}");
              },
            ),
          );
        },
      ),
    );
  }
}
