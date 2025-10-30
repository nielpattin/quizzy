import "package:flutter/material.dart";
import "../../../widgets/optimized_image.dart";

class QuestionCard extends StatelessWidget {
  final Map<String, dynamic> question;
  final int index;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const QuestionCard({
    required this.question,
    required this.index,
    required this.onEdit,
    required this.onDelete,
    super.key,
  });

  String _getTypeLabel(String type) {
    switch (type) {
      case "single_choice":
        return "Single Choice";
      case "true_false":
        return "True/False";
      case "reorder":
        return "Reorder";
      case "type_answer":
        return "Type Answer";
      case "checkbox":
        return "Checkbox";
      case "drop_pin":
        return "Drop Pin";
      default:
        return "Single Choice";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (question["imageUrl"] != null) ...[
            OptimizedImage(
              imageUrl: question["imageUrl"],
              height: 120,
              width: double.infinity,
              fit: BoxFit.cover,
              borderRadius: BorderRadius.circular(10),
            ),
            const SizedBox(height: 12),
          ],
          Row(
            children: [
              Text(
                "#${index + 1}",
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFFC0C0C0),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Text(
                  question["timeLimit"] ?? "20s",
                  style: const TextStyle(fontSize: 14, color: Colors.white),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Text(
                  question["points"] ?? "100 coki",
                  style: const TextStyle(fontSize: 14, color: Colors.white),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary,
                    width: 2,
                  ),
                ),
                child: Text(
                  _getTypeLabel(question["type"]),
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            question["questionText"],
            style: const TextStyle(fontSize: 20, color: Colors.white),
          ),
        ],
      ),
    );
  }
}
