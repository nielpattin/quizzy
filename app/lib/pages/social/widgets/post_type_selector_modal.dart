import "package:flutter/material.dart";

enum PostTypeChoice { normal, quiz }

class PostTypeSelectorModal extends StatelessWidget {
  const PostTypeSelectorModal({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "What type of post?",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 24),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.text_fields,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            title: const Text(
              "Normal Post",
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: const Text("Share your thoughts or image"),
            onTap: () => Navigator.of(context).pop(PostTypeChoice.normal),
          ),
          const SizedBox(height: 12),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.quiz,
                color: Theme.of(context).colorScheme.secondary,
              ),
            ),
            title: const Text(
              "Quiz Post",
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: const Text("Create a quick quiz question"),
            onTap: () => Navigator.of(context).pop(PostTypeChoice.quiz),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Cancel"),
          ),
        ],
      ),
    );
  }
}
