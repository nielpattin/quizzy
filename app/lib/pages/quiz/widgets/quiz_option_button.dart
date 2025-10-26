import 'package:flutter/material.dart';

class QuizOptionButton extends StatelessWidget {
  final String option;
  final bool isSelected;
  final bool? isCorrect;
  final bool isSubmitting;
  final VoidCallback? onTap;

  const QuizOptionButton({
    required this.option,
    required this.isSelected,
    this.isCorrect,
    this.isSubmitting = false,
    this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color textColor;
    Color borderColor;

    if (isCorrect != null) {
      // Show result
      if (isCorrect!) {
        backgroundColor = Colors.green.withValues(alpha: 0.2);
        textColor = Colors.green;
        borderColor = Colors.green;
      } else if (isSelected) {
        backgroundColor = Colors.red.withValues(alpha: 0.2);
        textColor = Colors.red;
        borderColor = Colors.red;
      } else {
        backgroundColor = Colors.grey.withValues(alpha: 0.1);
        textColor = Colors.grey[400]!;
        borderColor = Colors.grey.withValues(alpha: 0.3);
      }
    } else {
      // Normal state
      if (isSelected) {
        backgroundColor = const Color(0xFF64A7FF).withValues(alpha: 0.2);
        textColor = const Color(0xFF64A7FF);
        borderColor = const Color(0xFF64A7FF);
      } else {
        backgroundColor = Colors.grey.withValues(alpha: 0.1);
        textColor = Colors.white;
        borderColor = Colors.grey.withValues(alpha: 0.3);
      }
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: 2),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                option,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: textColor,
                ),
              ),
            ),
            if (isCorrect != null) ...[
              Icon(
                isCorrect! ? Icons.check_circle : Icons.cancel,
                color: isCorrect! ? Colors.green : Colors.red,
              ),
            ] else if (isSelected && isSubmitting) ...[
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF64A7FF)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
