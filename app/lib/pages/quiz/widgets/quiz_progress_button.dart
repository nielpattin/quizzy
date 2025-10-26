import 'package:flutter/material.dart';

class QuizProgressButton extends StatelessWidget {
  final double progress; // 0.0 to 1.0
  final bool isHolding;
  final bool isLastQuestion;
  final VoidCallback onTapDown;
  final VoidCallback onTapUp;
  final VoidCallback onTapCancel;

  const QuizProgressButton({
    required this.progress,
    required this.isHolding,
    required this.isLastQuestion,
    required this.onTapDown,
    required this.onTapUp,
    required this.onTapCancel,
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
      child: GestureDetector(
        onTapDown: (_) => onTapDown(),
        onTapUp: (_) => onTapUp(),
        onTapCancel: onTapCancel,
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            color: const Color(0xFF64A7FF),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Stack(
            children: [
              // Progress bar background
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              // Animated progress fill
              FractionallySizedBox(
                widthFactor: progress,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              // Arrow icon that moves with progress
              Positioned.fill(
                child: Align(
                  alignment: Alignment(-1 + (2 * progress), 0),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Icon(
                      Icons.arrow_forward,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
              ),
              // Text overlay
              Center(
                child: Text(
                  isHolding
                      ? "Hold to skip..."
                      : (isLastQuestion ? "View Results" : "Next Question"),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
