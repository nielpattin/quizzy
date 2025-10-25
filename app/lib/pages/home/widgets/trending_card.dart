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
                        placeholder: (context, url) => Container(
                          decoration: BoxDecoration(
                            gradient: _getGradientForCategory(category),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          decoration: BoxDecoration(
                            gradient: _getGradientForCategory(category),
                          ),
                          child: Center(
                            child: Icon(
                              Icons.image_not_supported,
                              color: Colors.white.withValues(alpha: 0.5),
                              size: 32,
                            ),
                          ),
                        ),
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
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(
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
                  ),
                  if (isSessions)
                    Positioned(
                      top: 8,
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
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 10),
                  Row(
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
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.7),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
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
