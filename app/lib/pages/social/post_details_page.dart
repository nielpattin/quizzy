import "dart:math";
import "package:flutter/material.dart";
import "package:cached_network_image/cached_network_image.dart";
import "package:supabase_flutter/supabase_flutter.dart";
import "../../services/api_service.dart";
import "../../models/post.dart";
import "../home/widgets/quick_question_modal.dart";

class PostDetailsPage extends StatefulWidget {
  final String postId;

  const PostDetailsPage({super.key, required this.postId});

  @override
  State<PostDetailsPage> createState() => _PostDetailsPageState();
}

class _PostDetailsPageState extends State<PostDetailsPage> {
  final TextEditingController _commentController = TextEditingController();
  bool _isLoadingPost = true;
  bool _isLoadingComments = true;
  bool _isSubmitting = false;
  Map<String, dynamic>? _post;
  List<dynamic> _comments = [];

  @override
  void initState() {
    super.initState();
    _loadPostAndComments();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadPostAndComments() async {
    setState(() {
      _isLoadingPost = true;
      _isLoadingComments = true;
    });

    try {
      final results = await Future.wait([
        ApiService.getPost(widget.postId),
        ApiService.getPostComments(widget.postId),
      ]);

      if (mounted) {
        setState(() {
          _post = results[0] as Map<String, dynamic>;
          _comments = results[1] as List<dynamic>;
          _isLoadingPost = false;
          _isLoadingComments = false;
        });
      }
    } catch (e) {
      debugPrint("[PostDetailsPage] Error loading: $e");
      if (mounted) {
        setState(() {
          _isLoadingPost = false;
          _isLoadingComments = false;
        });
      }
    }
  }

  Future<void> _submitComment() async {
    if (_commentController.text.trim().isEmpty) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      await ApiService.addComment(widget.postId, _commentController.text);
      _commentController.clear();
      await _loadPostAndComments();
    } catch (e) {
      debugPrint("[PostDetailsPage] Error submitting comment: $e");
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Failed to post comment: $e")));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _toggleLike() async {
    if (_post == null) return;

    final isLiked = _post!["isLiked"] ?? false;

    try {
      if (isLiked) {
        await ApiService.unlikePost(widget.postId);
      } else {
        await ApiService.likePost(widget.postId);
      }

      setState(() {
        _post!["likesCount"] = (_post!["likesCount"] ?? 0) + (isLiked ? -1 : 1);
        _post!["isLiked"] = !isLiked;
      });
    } catch (e) {
      debugPrint("[PostDetailsPage] Error toggling like: $e");
    }
  }

  Future<void> _deletePost() async {
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
        await ApiService.deletePost(widget.postId);
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Post deleted successfully')),
          );
        }
      } catch (e) {
        debugPrint("[PostDetailsPage] Error deleting post: $e");
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
    return Scaffold(
      appBar: AppBar(title: const Text("Post")),
      body: _isLoadingPost
          ? const Center(child: CircularProgressIndicator())
          : _post == null
          ? const Center(child: Text("Post not found"))
          : Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildPostContent(),
                      const SizedBox(height: 24),
                      const Divider(),
                      const SizedBox(height: 16),
                      Text(
                        "Comments (${_post!["commentsCount"] ?? 0})",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (_isLoadingComments)
                        const Center(child: CircularProgressIndicator())
                      else if (_comments.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32.0),
                            child: Text(
                              "No comments yet. Be the first!",
                              style: TextStyle(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: 0.6),
                              ),
                            ),
                          ),
                        )
                      else
                        ..._comments.map(_buildCommentItem),
                    ],
                  ),
                ),
                _buildCommentInput(),
              ],
            ),
    );
  }

  Widget _buildPostContent() {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    final postOwnerId = _post!["user"]?["id"];
    final isOwner = currentUserId != null && currentUserId == postOwnerId;

    final post = Post.fromJson(_post!);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Theme.of(context).colorScheme.primary,
                child: const Icon(Icons.person, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  post.user.fullName ?? "Unknown",
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (isOwner)
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'delete') {
                      _deletePost();
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red, size: 20),
                          SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                  icon: Icon(
                    Icons.more_vert,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            post.text,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 16,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          if (post.postType == PostType.image && post.imageUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CachedNetworkImage(
                imageUrl: post.imageUrl!,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  height: 200,
                  width: double.infinity,
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: const Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (context, url, error) => Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.broken_image_outlined,
                      size: 48,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.3),
                    ),
                  ),
                ),
              ),
            ),
          if (post.postType == PostType.quiz) ...[
            if (post.imageUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(
                  imageUrl: post.imageUrl!,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    height: 200,
                    width: double.infinity,
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                  errorWidget: (context, url, error) => Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.broken_image_outlined,
                        size: 48,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.3),
                      ),
                    ),
                  ),
                ),
              ),
            if (post.imageUrl != null) const SizedBox(height: 12),
            InkWell(
              onTap: !post.hasAnswered
                  ? () async {
                      await showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        builder: (context) => QuickQuestionModal(
                          post: post,
                          onAnswered: _loadPostAndComments,
                        ),
                      );
                    }
                  : null,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.quiz,
                      color: Theme.of(context).colorScheme.primary,
                      size: 32,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            post.questionText ?? "Quiz Question",
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onPrimaryContainer,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            post.hasAnswered ? "Answered ✓" : "Tap to answer",
                            style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onPrimaryContainer
                                  .withValues(alpha: 0.7),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!post.hasAnswered)
                      Icon(
                        Icons.arrow_forward_ios,
                        color: Theme.of(context).colorScheme.primary,
                        size: 16,
                      ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              InkWell(
                onTap: _toggleLike,
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        post.isLiked ? Icons.favorite : Icons.favorite_border,
                        color: (_post!["isLiked"] ?? false)
                            ? Colors.red
                            : Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.7),
                        size: 20,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        "${_post!["likesCount"] ?? 0}",
                        style: TextStyle(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.7),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 24),
              Row(
                children: [
                  Icon(
                    Icons.comment_outlined,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.7),
                    size: 20,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    "${_post!["commentsCount"] ?? 0}",
                    style: TextStyle(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.7),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _toggleCommentLike(String commentId, bool isLiked) async {
    try {
      if (isLiked) {
        await ApiService.unlikeComment(commentId);
      } else {
        await ApiService.likeComment(commentId);
      }

      setState(() {
        final comment = _comments.firstWhere((c) => c["id"] == commentId);
        comment["likesCount"] =
            (comment["likesCount"] ?? 0) + (isLiked ? -1 : 1);
        comment["isLiked"] = !isLiked;
      });
    } catch (e) {
      debugPrint("[PostDetailsPage] Error toggling comment like: $e");
    }
  }

  Future<void> _deleteComment(String commentId) async {
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
                'Delete Comment',
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
        await ApiService.deleteComment(commentId);
        setState(() {
          _comments.removeWhere((c) => c["id"] == commentId);
          if (_post != null) {
            _post!["commentsCount"] = max(
              0,
              (_post!["commentsCount"] ?? 0) - 1,
            );
          }
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Comment deleted successfully')),
          );
        }
      } catch (e) {
        debugPrint("[PostDetailsPage] Error deleting comment: $e");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete comment: $e')),
          );
        }
      }
    }
  }

  Widget _buildCommentItem(dynamic comment) {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    final commentOwnerId = comment["user"]?["id"];
    final isOwner = currentUserId != null && currentUserId == commentOwnerId;

    return GestureDetector(
      onLongPress: isOwner ? () => _deleteComment(comment["id"]) : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: const Icon(
                    Icons.person,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    comment["user"]?["fullName"] ?? "Unknown",
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    comment["content"] ?? "",
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: () => _toggleCommentLike(
                    comment["id"],
                    comment["isLiked"] ?? false,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 4,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          (comment["isLiked"] ?? false)
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: (comment["isLiked"] ?? false)
                              ? Colors.red
                              : Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: 0.6),
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "${comment["likesCount"] ?? 0}",
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.6),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentInput() {
    return Container(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _commentController,
              decoration: InputDecoration(
                hintText: "Add a comment...",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _submitComment(),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: _isSubmitting ? null : _submitComment,
            icon: _isSubmitting
                ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  )
                : Icon(
                    Icons.send,
                    color: Theme.of(context).colorScheme.primary,
                  ),
          ),
        ],
      ),
    );
  }
}
