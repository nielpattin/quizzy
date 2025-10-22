import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "package:supabase_flutter/supabase_flutter.dart";
import "../../services/api_service.dart";
import "../../models/post.dart";
import "widgets/feed_card.dart";
import "widgets/quick_question_modal.dart";
import "../social/widgets/post_type_selector_modal.dart";

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
  Map<String, dynamic>? _currentUserProfile;

  @override
  void initState() {
    super.initState();
    _loadCurrentUserProfile();
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

  Future<void> _loadCurrentUserProfile() async {
    try {
      final profile = await ApiService.getCurrentUserProfile();
      if (mounted) {
        setState(() {
          _currentUserProfile = profile;
        });
      }
    } catch (e) {
      debugPrint("[FeedyTab] Error loading current user profile: $e");
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
    _currentPage = 0;
    setState(() {
      _feedItems = [];
      _isLoading = true;
    });

    try {
      final data = await ApiService.getFeedPosts(limit: _pageSize, offset: 0);
      if (mounted) {
        setState(() {
          _feedItems = data;
          _currentPage = 1;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("[FeedyTab] Error refreshing feed: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _createPost(Map<String, dynamic> postData) async {
    try {
      final realPost = await ApiService.createPost(
        postData['text'],
        postType: postData['postType'],
        imageUrl: postData['imageUrl'],
        questionType: postData['questionType'],
        questionText: postData['questionText'],
        questionData: postData['questionData'],
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Post created"),
            action: SnackBarAction(
              label: "View",
              onPressed: () {
                context.push("/post/details", extra: realPost['id']);
              },
            ),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      debugPrint("[FeedyTab] Error creating post: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to create post: $e"),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _navigateToCreatePost() async {
    final postType = await showModalBottomSheet<PostTypeChoice>(
      context: context,
      builder: (context) => const PostTypeSelectorModal(),
    );

    if (postType == null) return;

    final route = postType == PostTypeChoice.quiz
        ? "/create-post/quiz"
        : "/create-post";

    final postData = await context.push<Map<String, dynamic>>(route);
    if (postData != null) {
      _createPost(postData);
    }
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

  Future<void> _deletePost(String postId) async {
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text(
                'Delete Post',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w500,
                ),
              ),
              onTap: () => Navigator.pop(context, true),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true) {
      try {
        await ApiService.deletePost(postId);
        setState(() {
          _feedItems.removeWhere((p) => p["id"] == postId);
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Post deleted successfully')),
          );
        }
      } catch (e) {
        debugPrint("[FeedyTab] Error deleting post: $e");
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Failed to delete post: $e')));
        }
      }
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
      child: Stack(
        children: [
          ListView.builder(
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
              final currentUserId =
                  Supabase.instance.client.auth.currentUser?.id;
              final postOwnerId = item["user"]?["id"];
              final isOwner =
                  currentUserId != null && currentUserId == postOwnerId;

              final post = Post.fromJson(item);

              return Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: FeedCard(
                  postId: post.id,
                  author: post.user.fullName ?? "Unknown",
                  profilePictureUrl: post.user.profilePictureUrl,
                  text: post.text,
                  postType: post.postType,
                  imageUrl: post.imageUrl,
                  questionText: post.questionText,
                  hasAnswered: post.hasAnswered,
                  likes: post.likesCount,
                  comments: post.commentsCount,
                  isLiked: post.isLiked,
                  isOwner: isOwner,
                  onLike: () => _toggleLike(post.id, post.isLiked),
                  onComment: () {
                    context.push("/post/details", extra: post.id);
                  },
                  onTap: () {
                    context.push("/post/details", extra: post.id);
                  },
                  onDelete: isOwner ? () => _deletePost(post.id) : null,
                  onShare: () {
                    debugPrint("Share post: ${post.id}");
                  },
                  onQuizTap: post.postType == PostType.quiz && !post.hasAnswered
                      ? () async {
                          await showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            builder: (context) => QuickQuestionModal(
                              post: post,
                              onAnswered: () {
                                setState(() {
                                  final index = _feedItems.indexWhere(
                                    (p) => p["id"] == post.id,
                                  );
                                  if (index != -1) {
                                    _feedItems[index]["hasAnswered"] = true;
                                  }
                                });
                              },
                            ),
                          );
                        }
                      : null,
                ),
              );
            },
          ),
          Positioned(
            right: 16,
            bottom: 16,
            child: FloatingActionButton(
              onPressed: _navigateToCreatePost,
              child: const Icon(Icons.add),
            ),
          ),
        ],
      ),
    );
  }
}
