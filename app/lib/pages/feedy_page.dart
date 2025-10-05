import "package:flutter/material.dart";

class FeedyPage extends StatelessWidget {
  const FeedyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: _FeedCard(
            author: "Ly Nguyên",
            category: "Animal",
            question: "What is the surprising real color of a Polar Bear's skin, which helps it absorb heat in the Arctic environment",
            likes: 152,
            comments: 28,
            isAnswered: index % 2 == 1,
          ),
        );
      },
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
                  child: Icon(Icons.person, color: Theme.of(context).colorScheme.onSurface, size: 24),
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
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    border: Border.all(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54)),
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
                    color: Colors.black,
                  ),
                ),
                if (isAnswered)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.close,
                        size: 100,
                        color: Colors.red,
                      ),
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
                    Icon(Icons.favorite_border, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7), size: 24),
                    SizedBox(width: 8),
                    Text(
                      "$likes",
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                SizedBox(width: 24),
                Row(
                  children: [
                    Icon(Icons.chat_bubble_outline, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7), size: 24),
                    SizedBox(width: 8),
                    Text(
                      "$comments",
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Icon(Icons.share, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7), size: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
