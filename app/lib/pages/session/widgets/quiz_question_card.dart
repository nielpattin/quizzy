import 'package:flutter/material.dart';
import 'package:quizzy/pages/session/controllers/quiz_session_controller.dart';
import 'quiz_option_button.dart';

class QuizQuestionCard extends StatelessWidget {
  final QuizSessionController controller;

  const QuizQuestionCard({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentQuestion = controller.currentQuestion;
    final questionType = currentQuestion["type"] as String;

    final options = questionType == "single_choice"
        ? (currentQuestion["data"]["options"] as List)
              .map((opt) => opt is Map ? opt["text"] as String : opt as String)
              .toList()
        : ["True", "False"];

    int? correctIndex = currentQuestion["data"]["correctIndex"] as int?;
    if (correctIndex == null && questionType == "single_choice") {
      final optionsList = currentQuestion["data"]["options"] as List;
      for (int i = 0; i < optionsList.length; i++) {
        if (optionsList[i] is Map && optionsList[i]["isCorrect"] == true) {
          correctIndex = i;
          break;
        }
      }
    }

    final correctAnswerRaw = currentQuestion["data"]["correctAnswer"];
    bool? correctAnswerBool;
    if (correctAnswerRaw is bool) {
      correctAnswerBool = correctAnswerRaw;
    } else if (correctAnswerRaw is String) {
      correctAnswerBool = correctAnswerRaw.toLowerCase() == 'true';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Question ${controller.currentQuestionIndex + 1} of ${controller.questions.length}",
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              "Score: ${controller.score}",
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF64A7FF),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text(
          currentQuestion["questionText"],
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 32),
        ...options.asMap().entries.map((entry) {
          final index = entry.key;
          final option = entry.value;
          final isSelected = controller.selectedAnswerIndex == index;
          bool? isCorrect;

          if (controller.showResult) {
            if (correctIndex != null) {
              isCorrect = index == correctIndex;
            } else if (correctAnswerBool != null) {
              isCorrect =
                  (index == 0 && correctAnswerBool) ||
                  (index == 1 && !correctAnswerBool);
            }
          }

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: QuizOptionButton(
              option: option,
              isSelected: isSelected,
              isCorrect: controller.showResult ? isCorrect : null,
              onTap: () => controller.selectAnswer(index),
            ),
          );
        }),
      ],
    );
  }
}
