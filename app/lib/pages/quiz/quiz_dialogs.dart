import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void showQuizCompleteDialog(
  BuildContext context, {
  required int score,
  required int totalQuestions,
  required String quizId,
  required String? sessionId,
}) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => QuizCompleteDialog(
      score: score,
      totalQuestions: totalQuestions,
      quizId: quizId,
      sessionId: sessionId,
    ),
  );
}

class QuizCompleteDialog extends StatefulWidget {
  final int score;
  final int totalQuestions;
  final String quizId;
  final String? sessionId;

  const QuizCompleteDialog({
    super.key,
    required this.score,
    required this.totalQuestions,
    required this.quizId,
    required this.sessionId,
  });

  @override
  State<QuizCompleteDialog> createState() => _QuizCompleteDialogState();
}

class _QuizCompleteDialogState extends State<QuizCompleteDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _progressAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.5, curve: Curves.elasticOut),
    );

    _progressAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.3, 0.9, curve: Curves.easeOutCubic),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.5, 1.0, curve: Curves.easeIn),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double get percentage =>
      widget.totalQuestions > 0 ? (widget.score / widget.totalQuestions) : 0.0;

  String get performanceMessage {
    final percent = percentage * 100;
    if (percent == 100) return "Perfect Score! 🏆";
    if (percent >= 90) return "Excellent! 🌟";
    if (percent >= 75) return "Great Job! 👏";
    if (percent >= 60) return "Good Work! 👍";
    if (percent >= 50) return "Keep Practicing! 💪";
    return "Don't Give Up! 🎯";
  }

  Color get scoreColor {
    final percent = percentage * 100;
    if (percent >= 90) return Colors.green;
    if (percent >= 75) return Colors.blue;
    if (percent >= 60) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      backgroundColor: Colors.transparent,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with gradient
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      scoreColor.withValues(alpha: 0.8),
                      scoreColor.withValues(alpha: 0.5),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.emoji_events,
                      size: 48,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Quiz Complete!",
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    // Circular Progress Indicator
                    SizedBox(
                      width: 180,
                      height: 180,
                      child: AnimatedBuilder(
                        animation: _progressAnimation,
                        builder: (context, child) {
                          return CustomPaint(
                            painter: CircularProgressPainter(
                              progress: percentage * _progressAnimation.value,
                              color: scoreColor,
                            ),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    "${(percentage * _progressAnimation.value * 100).toStringAsFixed(0)}%",
                                    style: theme.textTheme.headlineLarge
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: scoreColor,
                                        ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "${(widget.score * _progressAnimation.value).toInt()} / ${widget.totalQuestions}",
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      color: theme.colorScheme.onSurface
                                          .withValues(alpha: 0.7),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Performance Message
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: scoreColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          performanceMessage,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: scoreColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Stats Row
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildStatItem(
                            context,
                            icon: Icons.check_circle,
                            label: "Correct",
                            value: "${widget.score}",
                            color: Colors.green,
                          ),
                          _buildStatItem(
                            context,
                            icon: Icons.cancel,
                            label: "Wrong",
                            value: "${widget.totalQuestions - widget.score}",
                            color: Colors.red,
                          ),
                          _buildStatItem(
                            context,
                            icon: Icons.help_outline,
                            label: "Total",
                            value: "${widget.totalQuestions}",
                            color: Colors.blue,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Action Buttons
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: Column(
                        children: [
                          // Play Again Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                // Proper Play Again flow
                                if (widget.sessionId != null) {
                                  try {
                                    // Create new participant by calling join API
                                    final authSession = Supabase
                                        .instance
                                        .client
                                        .auth
                                        .currentSession;
                                    if (authSession == null) return;

                                    final serverUrl = dotenv.env["SERVER_URL"];
                                    final response = await http.post(
                                      Uri.parse(
                                        "$serverUrl/api/session/${widget.sessionId}/join",
                                      ),
                                      headers: {
                                        "Authorization":
                                            "Bearer ${authSession.accessToken}",
                                        "Content-Type": "application/json",
                                      },
                                    );

                                    if (response.statusCode == 201 ||
                                        response.statusCode == 200) {
                                      // Successfully joined, close modal and restart quiz from beginning
                                      if (context.mounted) {
                                        context.pop(); // Close dialog
                                        // Add timestamp to force GoRouter to rebuild the widget
                                        final timestamp = DateTime.now()
                                            .millisecondsSinceEpoch;
                                        context.go(
                                          '/session/${widget.sessionId}/play?ts=$timestamp',
                                        );
                                      }
                                    } else {
                                      // Join failed, show error
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Failed to join session: ${response.body}',
                                            ),
                                          ),
                                        );
                                      }
                                    }
                                  } catch (e) {
                                    // Error during join
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(content: Text('Error: $e')),
                                      );
                                    }
                                  }
                                } else {
                                  // Fallback: create new session
                                  context.push('/quiz/${widget.quizId}/play');
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              icon: const Icon(Icons.replay),
                              label: const Text(
                                "Play Again",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 12),

                          // Done Button
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () {
                                context.pop(); // Close dialog
                                if (widget.sessionId != null) {
                                  // Navigate to session detail page with My Attempts tab
                                  context.go(
                                    '/quiz/session/detail/${widget.sessionId}?tab=1',
                                  );
                                } else {
                                  // Fallback to home if no sessionId
                                  context.go('/');
                                }
                              },
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              icon: const Icon(Icons.check),
                              label: const Text(
                                "Done",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }
}

class CircularProgressPainter extends CustomPainter {
  final double progress;
  final Color color;

  CircularProgressPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;
    final strokeWidth = 12.0;

    // Background circle
    final backgroundPaint = Paint()
      ..color = color.withValues(alpha: 0.2)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius - strokeWidth / 2, backgroundPaint);

    // Progress arc
    final progressPaint = Paint()
      ..shader = LinearGradient(
        colors: [color, color.withValues(alpha: 0.7)],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * math.pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
      -math.pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(CircularProgressPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
