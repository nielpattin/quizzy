import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "../../../utils/image_helper.dart";
import "../../../widgets/optimized_image.dart";

class ProfileTabsContent extends StatelessWidget {
  final List<dynamic> quizzes;
  final List<dynamic> sessions;
  final List<dynamic> posts;
  final String? fullName;
  final String? avatarUrl;

  const ProfileTabsContent({
    super.key,
    required this.quizzes,
    required this.sessions,
    required this.posts,
    this.fullName,
    this.avatarUrl,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox.shrink();
  }

  static Widget buildQuizzesTab(
    BuildContext context,
    List<dynamic> quizzes,
    Future<void> Function() onRefresh,
  ) {
    if (quizzes.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          child: Container(
            height: 400,
            alignment: Alignment.center,
            child: Text(
              "No quizzes yet",
              style: TextStyle(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.75,
        ),
        itemCount: quizzes.length,
        itemBuilder: (context, index) {
          final quiz = quizzes[index];
          return _QuizCard(
            id: quiz["id"],
            title: quiz["title"],
            category: quiz["category"]?["name"] ?? "General",
            plays: quiz["playCount"] ?? 0,
            questionCount: quiz["questionCount"] ?? 0,
            imageUrl: quiz["imageUrl"],
            color: Colors.primaries[index % Colors.primaries.length],
          );
        },
      ),
    );
  }

  static Widget buildSessionsTab(
    BuildContext context,
    List<dynamic> sessions,
    Future<void> Function() onRefresh,
  ) {
    if (sessions.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          child: Container(
            height: 400,
            alignment: Alignment.center,
            child: Text(
              "No sessions yet",
              style: TextStyle(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: sessions.length,
        itemBuilder: (context, index) {
          final session = sessions[index];
          final participantCount = session["participantCount"] ?? 0;
          final isLive = session["isLive"] ?? false;
          final startedAt = session["startedAt"];
          final createdAt = session["createdAt"];

          String date = "Unknown date";
          if (startedAt != null) {
            final dateTime = DateTime.parse(startedAt).toLocal();
            date = "${dateTime.day}/${dateTime.month}/${dateTime.year}";
          } else if (createdAt != null) {
            final dateTime = DateTime.parse(createdAt).toLocal();
            date = "${dateTime.day}/${dateTime.month}/${dateTime.year}";
          }

          return _SessionCard(
            title: session["title"] ?? "Untitled Session",
            date: date,
            isLive: isLive,
            participantCount: participantCount,
            sessionId: session["id"],
          );
        },
      ),
    );
  }

  static Widget buildPostsTab(
    BuildContext context,
    List<dynamic> posts,
    String? fullName,
    String? avatarUrl,
    Future<void> Function() onRefresh,
  ) {
    if (posts.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          child: Container(
            height: 400,
            alignment: Alignment.center,
            child: Text(
              "No posts yet",
              style: TextStyle(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: posts.length,
        itemBuilder: (context, index) {
          final post = posts[index];
          final likes = post["likesCount"] ?? 0;
          final comments = post["commentsCount"] ?? 0;
          final createdAt = post["createdAt"];

          String time = "Unknown time";
          if (createdAt != null) {
            final dateTime = DateTime.parse(createdAt).toLocal();
            final now = DateTime.now();
            final difference = now.difference(dateTime);

            if (difference.inDays == 0) {
              if (difference.inHours == 0) {
                time = "${difference.inMinutes}m ago";
              } else {
                time = "${difference.inHours}h ago";
              }
            } else if (difference.inDays == 1) {
              time = "Yesterday";
            } else if (difference.inDays < 7) {
              time = "${difference.inDays}d ago";
            } else {
              time = "${dateTime.day}/${dateTime.month}/${dateTime.year}";
            }
          }

          return _PostCard(
            text: post["text"] ?? "",
            likes: likes,
            comments: comments,
            time: time,
            fullName: fullName ?? "User",
            avatarUrl: avatarUrl,
          );
        },
      ),
    );
  }
}

class _QuizCard extends StatelessWidget {
  final String id;
  final String title;
  final String category;
  final int plays;
  final int questionCount;
  final String? imageUrl;
  final Color color;

  const _QuizCard({
    required this.id,
    required this.title,
    required this.category,
    required this.plays,
    required this.questionCount,
    this.imageUrl,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.push("/quiz/$id"),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 120,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.3),
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
                      height: 120,
                      fit: BoxFit.cover,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
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
                  SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.play_arrow,
                            size: 14,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                          SizedBox(width: 4),
                          Text(
                            "$plays plays",
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.6),
                              fontSize: 12,
                            ),
                          ),
                        ],
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
                              "$questionCount",
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

class _SessionCard extends StatelessWidget {
  final String title;
  final String date;
  final bool isLive;
  final int participantCount;
  final String sessionId;

  const _SessionCard({
    required this.title,
    required this.date,
    required this.isLive,
    required this.participantCount,
    required this.sessionId,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        context.push('/quiz/session/detail/$sessionId');
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.emoji_events,
                    color: Theme.of(context).colorScheme.primary,
                    size: 24,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            date,
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.6),
                              fontSize: 13,
                            ),
                          ),
                          SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: isLive
                                  ? Colors.green.withValues(alpha: 0.2)
                                  : Colors.grey.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              isLive ? "LIVE" : "ENDED",
                              style: TextStyle(
                                color: isLive ? Colors.green : Colors.grey,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _SessionStat(
                    icon: Icons.people,
                    label: "Players",
                    value: "$participantCount",
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SessionStat extends StatelessWidget {
  final IconData? icon;
  final String label;
  final String value;

  const _SessionStat({this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, size: 16, color: Theme.of(context).colorScheme.primary),
          SizedBox(width: 6),
        ],
        Text(
          value,
          style: TextStyle(
            color: Theme.of(context).colorScheme.primary,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.6),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _PostCard extends StatelessWidget {
  final String text;
  final int likes;
  final int comments;
  final String time;
  final String fullName;
  final String? avatarUrl;

  const _PostCard({
    required this.text,
    required this.likes,
    required this.comments,
    required this.time,
    required this.fullName,
    this.avatarUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ImageHelper.createValidNetworkImage(avatarUrl) != null
                  ? CircleAvatar(
                      radius: 20,
                      backgroundImage: ImageHelper.createValidNetworkImage(
                        avatarUrl,
                      )!,
                      backgroundColor: Theme.of(context).colorScheme.primary,
                    )
                  : CircleAvatar(
                      radius: 20,
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      child: Icon(Icons.person, size: 20, color: Colors.white),
                    ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fullName,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      time,
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
            ],
          ),
          SizedBox(height: 12),
          Text(
            text,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 14,
              height: 1.4,
            ),
          ),
          SizedBox(height: 12),
          Row(
            children: [
              _PostAction(icon: Icons.favorite_border, count: likes),
              SizedBox(width: 24),
              _PostAction(icon: Icons.chat_bubble_outline, count: comments),
              SizedBox(width: 24),
              _PostAction(icon: Icons.share_outlined, count: 0),
            ],
          ),
        ],
      ),
    );
  }
}

class _PostAction extends StatelessWidget {
  final IconData icon;
  final int count;

  const _PostAction({required this.icon, required this.count});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            if (count > 0) ...[
              SizedBox(width: 4),
              Text(
                "$count",
                style: TextStyle(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.6),
                  fontSize: 13,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
