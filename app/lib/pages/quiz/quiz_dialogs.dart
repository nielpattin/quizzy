import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

void showQuizCompleteDialog(
  BuildContext context, {
  required int score,
  required int totalQuestions,
}) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      title: const Text("Quiz Complete!"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.check_circle_outline,
            size: 64,
            color: Color(0xFF64A7FF),
          ),
          const SizedBox(height: 16),
          Text(
            "Your Score",
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            "$score / $totalQuestions",
            style: const TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: Color(0xFF64A7FF),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "${totalQuestions > 0 ? ((score / totalQuestions) * 100).toStringAsFixed(0) : 0}%",
            style: TextStyle(fontSize: 24, color: Colors.grey[700]),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            context.pop();
            context.pop();
          },
          child: const Text("Done"),
        ),
      ],
    ),
  );
}
