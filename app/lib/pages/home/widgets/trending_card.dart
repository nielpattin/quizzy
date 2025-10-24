import "package:cached_network_image/cached_network_image.dart";
import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "../../../widgets/user_avatar.dart";

class TrendingCard extends StatelessWidget {
  final String title;
  final String author;
  final String category;
  final int count;
  final bool isSessions;
  final String quizId;
  final String? imageUrl;
  final String? profilePictureUrl;

  const TrendingCard({
    super.key,
    required this.title,
    required this.author,
    required this.category,
    required this.count,
    this.isSessions = false,
    required this.quizId,
    this.imageUrl,
    this.profilePictureUrl,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.push("/quiz/$quizId"),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 160,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 90,
              decoration: BoxDecoration(
                color: Colors.grey[700],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Stack(
                children: [
                  if (imageUrl != null && imageUrl!.isNotEmpty)
                    ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                      child: CachedNetworkImage(
                        imageUrl: imageUrl!,
                        width: double.infinity,
                        height: 90,
                        fit: BoxFit.cover,
                        placeholder: (context, url) =>
                            Container(color: Colors.grey[700]),
                        errorWidget: (context, url, error) =>
                            Container(color: Colors.grey[700]),
                      ),
                    ),
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
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            UserAvatar(
                              imageUrl: profilePictureUrl,
                              radius: 10,
                              iconSize: 12,
                            ),
                            SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                author,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onSurface
                                      .withValues(alpha: 0.7),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.copy, size: 11, color: Colors.white),
                            SizedBox(width: 4),
                            Text(
                              "$count",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
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
