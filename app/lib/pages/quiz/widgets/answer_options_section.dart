import "package:flutter/material.dart";
import "answer_card.dart";

class AnswerOptionsSection extends StatelessWidget {
  final String questionType;
  final int? correctAnswerIndex;
  final List<TextEditingController> answerControllers;
  final Function(int) onMarkCorrect;

  const AnswerOptionsSection({
    required this.questionType,
    required this.correctAnswerIndex,
    required this.answerControllers,
    required this.onMarkCorrect,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 22,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              "Answer Options",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          crossAxisCount: 2,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          childAspectRatio: 1.4,
          children: questionType == "true_false"
              ? [
                  AnswerCard(
                    text: "True",
                    index: 0,
                    color: const Color(0xFF10B981),
                    icon: Icons.check_circle_rounded,
                    isCorrect: correctAnswerIndex == 0,
                    isTrueFalse: true,
                    onMarkCorrect: onMarkCorrect,
                  ),
                  AnswerCard(
                    text: "False",
                    index: 1,
                    color: const Color(0xFFEF4444),
                    icon: Icons.cancel_rounded,
                    isCorrect: correctAnswerIndex == 1,
                    isTrueFalse: true,
                    onMarkCorrect: onMarkCorrect,
                  ),
                ]
              : List.generate(
                  4,
                  (index) => AnswerCard(
                    text: answerControllers[index].text,
                    index: index,
                    color: [
                      const Color(0xFF3B82F6),
                      const Color(0xFFEC4899),
                      const Color(0xFFF59E0B),
                      const Color(0xFF10B981),
                    ][index],
                    icon: [
                      Icons.looks_one_rounded,
                      Icons.looks_two_rounded,
                      Icons.looks_3_rounded,
                      Icons.looks_4_rounded,
                    ][index],
                    isCorrect: correctAnswerIndex == index,
                    isTrueFalse: false,
                    controller: answerControllers[index],
                    onMarkCorrect: onMarkCorrect,
                  ),
                ),
        ),
      ],
    );
  }
}
