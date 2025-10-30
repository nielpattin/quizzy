import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "../../../widgets/optimized_image.dart";

class ContinuePlayingItem extends StatelessWidget {
  final String sessionId;
  final String title;
  final String author;
  final String? authorProfileUrl;
  final String category;
  final int count;
  final bool isLive;
  final String? imageUrl;
  final int? rank;
  final int? participantCount;

  const ContinuePlayingItem({
    super.key,
    required this.sessionId,
    required this.title,
    required this.author,
    this.authorProfileUrl,
    required this.category,
    required this.count,
    this.isLive = false,
    this.imageUrl,
    this.rank,
    this.participantCount,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _handleTap(context),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            imageUrl != null
                ? OptimizedImage(
                    imageUrl: imageUrl!,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    borderRadius: BorderRadius.circular(8),
                  )
                : Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: isLive ? Colors.red[400] : Colors.grey[700],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      isLive ? Icons.play_circle : Icons.quiz,
                      color: Colors.white,
                      size: 32,
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
                        fontWeight: FontWeight.bold,
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
                      authorProfileUrl != null
                          ? CircleAvatar(
                              radius: 8,
                              backgroundImage: NetworkImage(authorProfileUrl!),
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.primary,
                            )
                          : CircleAvatar(
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
                      if (rank != null) ...[
                        SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.amber,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '#$rank',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                      Spacer(),
                      if (isLive) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            "LIVE",
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        SizedBox(width: 4),
                      ],
                      if (participantCount != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.people, size: 10, color: Colors.white),
                              SizedBox(width: 4),
                              Text(
                                "$participantCount",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
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

  void _handleTap(BuildContext context) {
    // Always navigate to session detail page regardless of live status
    // Host can manage session, participants can view and join
    context.push('/quiz/session/detail/$sessionId');
  }
}
