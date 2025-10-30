import 'package:flutter/material.dart';

class QuizProgressButton extends StatelessWidget {
  final double progress; // 0.0 to 1.0
  final bool isLastQuestion;
  final VoidCallback onTap;

  const QuizProgressButton({
    required this.progress,
    required this.isLastQuestion,
    required this.onTap,
    super.key,
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
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            color: const Color(0xFF64A7FF),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Circular progress indicator
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: SizedBox(
                  width: 32,
                  height: 32,
                  child: Stack(
                    children: [
                      // Background circle
                      CircularProgressIndicator(
                        value: 1.0,
                        strokeWidth: 3,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.white.withValues(alpha: 0.2),
                        ),
                      ),
                      // Progress circle (depletes as time runs out)
                      CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 3,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Static arrow icon
              const Icon(Icons.arrow_forward, color: Colors.white, size: 24),
              const SizedBox(width: 12),
              // Button text
              Text(
                isLastQuestion ? "View Results" : "Next",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
