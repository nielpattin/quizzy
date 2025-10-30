import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "../../../models/post.dart";
import "../../../widgets/user_avatar.dart";
import "../../../widgets/optimized_image.dart";

class FeedCard extends StatefulWidget {
  final String postId;
  final String author;
  final String? username;
  final String? profilePictureUrl;
  final String text;
  final PostType postType;
  final String? imageUrl;
  final String? questionText;
  final bool hasAnswered;
  final int likes;
  final int comments;
  final bool isLiked;
  final bool isOwner;
  final String authorId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final VoidCallback onLike;
  final VoidCallback? onTap;
  final VoidCallback? onComment;
  final VoidCallback? onDelete;
  final VoidCallback? onQuizTap;
  final VoidCallback? onShare;

  const FeedCard({
    super.key,
    required this.postId,
    required this.author,
    this.username,
    this.profilePictureUrl,
    required this.text,
    this.postType = PostType.text,
    this.imageUrl,
    this.questionText,
    this.hasAnswered = false,
    required this.likes,
    required this.comments,
    required this.isLiked,
    this.isOwner = false,
    required this.authorId,
    required this.createdAt,
    required this.updatedAt,
    required this.onLike,
    this.onTap,
    this.onComment,
    this.onDelete,
    this.onQuizTap,
    this.onShare,
  });

  @override
  State<FeedCard> createState() => _FeedCardState();
}

class _FeedCardState extends State<FeedCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _likeAnimationController;
  late Animation<double> _likeScaleAnimation;

  @override
  void initState() {
    super.initState();
    _likeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _likeScaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.0,
          end: 1.3,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.3,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.elasticOut)),
        weight: 50,
      ),
    ]).animate(_likeAnimationController);
  }

  @override
  void dispose() {
    _likeAnimationController.dispose();
    super.dispose();
  }

  void _handleLike() {
    if (mounted) {
      _likeAnimationController.forward(from: 0.0);
      widget.onLike();
    }
  }

  void _showPostInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Post Information'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildInfoRow('Post ID', widget.postId),
              _buildInfoRow('Post Type', widget.postType.toJson()),
              if (widget.imageUrl != null)
                _buildInfoRow('Image URL', widget.imageUrl!, isUrl: true),
              if (widget.postType == PostType.quiz &&
                  widget.questionText != null)
                _buildInfoRow('Question', widget.questionText!),
              _buildInfoRow('Author ID', widget.authorId),
              _buildInfoRow('Author Name', widget.author),
              if (widget.username != null)
                _buildInfoRow('Username', '@${widget.username}'),
              _buildInfoRow('Likes', widget.likes.toString()),
              _buildInfoRow('Comments', widget.comments.toString()),
              _buildInfoRow(
                'Created At',
                widget.createdAt.toLocal().toString().split('.')[0],
              ),
              _buildInfoRow(
                'Updated At',
                widget.updatedAt.toLocal().toString().split('.')[0],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isUrl = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(fontSize: 13, color: isUrl ? Colors.blue : null),
            maxLines: isUrl ? 2 : null,
            overflow: isUrl ? TextOverflow.ellipsis : null,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: widget.onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
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
                  GestureDetector(
                    onTap: () {
                      context.push("/profile/${widget.authorId}");
                    },
                    child: Row(
                      children: [
                        UserAvatar(
                          imageUrl: widget.profilePictureUrl,
                          radius: 20,
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.author,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (widget.username != null)
                              Text(
                                '@${widget.username}',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onSurface
                                      .withValues(alpha: 0.6),
                                  fontSize: 14,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'info') {
                        _showPostInfo(context);
                      } else if (value == 'delete') {
                        widget.onDelete!();
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'info',
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, size: 20),
                            SizedBox(width: 8),
                            Text('Post Info'),
                          ],
                        ),
                      ),
                      if (widget.isOwner && widget.onDelete != null)
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, color: Colors.red, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Delete',
                                style: TextStyle(color: Colors.red),
                              ),
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
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                widget.text,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 16,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (widget.postType == PostType.image && widget.imageUrl != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: OptimizedImage(
                  imageUrl: widget.imageUrl!,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            if (widget.postType == PostType.quiz) ...[
              if (widget.imageUrl != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: OptimizedImage(
                    imageUrl: widget.imageUrl!,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              if (widget.imageUrl != null) const SizedBox(height: 12),
              if (!widget.hasAnswered)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: ElevatedButton.icon(
                    onPressed: widget.onQuizTap,
                    icon: const Icon(Icons.quiz, size: 20),
                    label: const Text('Tap to Answer Quiz'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      minimumSize: const Size(double.infinity, 44),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              if (widget.hasAnswered)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green, width: 1.5),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle, color: Colors.green, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Answered ✓',
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  Expanded(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _handleLike,
                        borderRadius: BorderRadius.circular(20),
                        child: Ink(
                          padding: const EdgeInsets.all(12),
                          child: AnimatedBuilder(
                            animation: _likeScaleAnimation,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: _likeScaleAnimation.value,
                                child: child,
                              );
                            },
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  widget.isLiked
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  color: widget.isLiked
                                      ? Colors.red
                                      : Theme.of(context).colorScheme.onSurface
                                            .withValues(alpha: 0.7),
                                  size: 24,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  "${widget.likes}",
                                  style: TextStyle(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.7),
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: widget.onComment,
                        borderRadius: BorderRadius.circular(20),
                        child: Ink(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.comment_outlined,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: 0.7),
                                size: 24,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                "${widget.comments}",
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onSurface
                                      .withValues(alpha: 0.7),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: widget.onShare,
                        borderRadius: BorderRadius.circular(20),
                        child: Ink(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.share_outlined,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: 0.7),
                                size: 24,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                "Share",
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onSurface
                                      .withValues(alpha: 0.7),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
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
