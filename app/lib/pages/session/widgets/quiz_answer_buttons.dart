import 'package:flutter/material.dart';
import 'package:quizzy/pages/session/controllers/quiz_session_controller.dart';

class QuizAnswerButtons extends StatelessWidget {
  final QuizSessionController controller;
  final VoidCallback onShowResults;

  const QuizAnswerButtons({
    super.key,
    required this.controller,
    required this.onShowResults,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (!controller.isFirstQuestion)
            IconButton(
              onPressed: controller.previousQuestion,
              icon: const Icon(Icons.arrow_back),
              style: IconButton.styleFrom(backgroundColor: Colors.grey[200]),
            ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: controller.showResult
                  ? (controller.isLastQuestion
                        ? onShowResults
                        : controller.nextQuestion)
                  : (controller.selectedAnswerIndex != null
                        ? controller.submitAnswer
                        : null),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF64A7FF),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                controller.showResult
                    ? (controller.isLastQuestion ? "Finish" : "Next Question")
                    : "Submit Answer",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
