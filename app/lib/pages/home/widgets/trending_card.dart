import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "../../../widgets/user_avatar.dart";
import "../../../widgets/optimized_image.dart";

class TrendingCard extends StatelessWidget {
  final String title;
  final String author;
  final String category;
  final int count;
  final bool isSessions;
  final String quizId;
  final String? imageUrl;
  final String? profilePictureUrl;
  final int? playCount;
  final String? createdAt;

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
    this.playCount,
    this.createdAt,
  });

  LinearGradient _getGradientForCategory(String category) {
    final gradients = {
      'Khoa học': [Color(0xFF667eea), Color(0xFF764ba2)], // Purple-Blue
      'Lịch sử': [Color(0xFFf093fb), Color(0xFFf5576c)], // Pink-Red
      'Địa lý': [Color(0xFF4facfe), Color(0xFF00f2fe)], // Blue-Cyan
      'Toán học': [Color(0xFFfa709a), Color(0xFFfee140)], // Pink-Yellow
      'Văn học': [Color(0xFFa8edea), Color(0xFFfed6e3)], // Teal-Pink
      'Công nghệ': [Color(0xFF30cfd0), Color(0xFF330867)], // Cyan-Purple
      'Thể thao': [Color(0xFFff6a00), Color(0xFFee0979)], // Orange-Pink
      'Âm nhạc': [Color(0xFFf761a1), Color(0xFF8c1bab)], // Pink-Purple
      'Nghệ thuật': [Color(0xFFffecd2), Color(0xFFfcb69f)], // Peach
      'Kinh doanh': [Color(0xFF3f2b96), Color(0xFFa8c0ff)], // Deep Purple-Blue
    };

    final colors =
        gradients[category] ?? [Color(0xFF667eea), Color(0xFF764ba2)];
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: colors,
    );
  }

  String _getRelativeTime(String? dateString) {
    if (dateString == null) return '';

    try {
      final dateTime = DateTime.parse(dateString).toLocal();
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inDays == 0) {
        if (difference.inHours == 0) {
          return '${difference.inMinutes}m ago';
        }
        return '${difference.inHours}h ago';
      } else if (difference.inDays == 1) {
        return '1d ago';
      } else if (difference.inDays < 7) {
        return '${difference.inDays}d ago';
      } else if (difference.inDays < 30) {
        return '${(difference.inDays / 7).floor()}w ago';
      } else if (difference.inDays < 365) {
        return '${(difference.inDays / 30).floor()}mo ago';
      }
      return '${(difference.inDays / 365).floor()}y ago';
    } catch (e) {
      return '';
    }
  }

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
              width: double.infinity,
              height: 80,
              decoration: BoxDecoration(
                gradient: (imageUrl == null || imageUrl!.isEmpty)
                    ? _getGradientForCategory(category)
                    : null,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Stack(
                children: [
                  if (imageUrl != null && imageUrl!.isNotEmpty)
                    OptimizedImage(
                      imageUrl: imageUrl!,
                      width: double.infinity,
                      height: 80,
                      fit: BoxFit.cover,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                    ),
                  Positioned(
                    top: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        category,
                        style: TextStyle(color: Colors.white, fontSize: 10),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
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
                          SizedBox(width: 2),
                          Text(
                            "$count",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (isSessions)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          "Sessions",
                          style: TextStyle(color: Colors.white, fontSize: 10),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 6),
                  Row(
                    children: [
                      UserAvatar(
                        imageUrl: profilePictureUrl,
                        radius: 8,
                        iconSize: 10,
                      ),
                      SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          author,
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.7),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 2),
                  Row(
                    children: [
                      if (createdAt != null &&
                          _getRelativeTime(createdAt).isNotEmpty) ...[
                        Text(
                          _getRelativeTime(createdAt),
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.5),
                            fontSize: 10,
                          ),
                        ),
                        if (playCount != null && playCount! > 0) ...[
                          Text(
                            ' • ',
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.5),
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ],
                      if (playCount != null && playCount! > 0)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.play_arrow,
                              size: 10,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.5),
                            ),
                            SizedBox(width: 2),
                            Text(
                              "$playCount plays",
                              style: TextStyle(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: 0.5),
                                fontSize: 10,
                              ),
                            ),
                          ],
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
