import "package:flutter/material.dart";
import "../../../models/post.dart";
import "../../../services/api_service.dart";

class QuickQuestionModal extends StatefulWidget {
  final Post post;
  final VoidCallback onAnswered;

  const QuickQuestionModal({
    super.key,
    required this.post,
    required this.onAnswered,
  });

  @override
  State<QuickQuestionModal> createState() => _QuickQuestionModalState();
}

class _QuickQuestionModalState extends State<QuickQuestionModal> {
  dynamic _selectedAnswer;
  final Set<int> _selectedAnswers = {};
  bool _isSubmitting = false;
  AnswerResult? _result;

  bool get _hasSelection {
    if (widget.post.questionType == QuestionType.checkbox) {
      return _selectedAnswers.isNotEmpty;
    }
    return _selectedAnswer != null;
  }

  Future<void> _submitAnswer() async {
    if (!_hasSelection) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final answer = widget.post.questionType == QuestionType.checkbox
          ? (_selectedAnswers.toList()..sort())
          : _selectedAnswer;

      final response = await ApiService.submitPostAnswer(
        widget.post.id,
        answer,
      );
      final result = AnswerResult.fromJson(response);

      setState(() {
        _result = result;
        _isSubmitting = false;
      });
    } catch (e) {
      debugPrint("[QuickQuestionModal] Error submitting answer: $e");
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Failed to submit answer: $e")));
      }
    }
  }

  void _close() {
    Navigator.of(context).pop();
    widget.onAnswered();
  }

  @override
  Widget build(BuildContext context) {
    if (_result != null) {
      return _buildResultView();
    }

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.post.questionText ?? "",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildAnswerOptions(),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _hasSelection && !_isSubmitting
                      ? _submitAnswer
                      : null,
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text("Submit Answer"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnswerOptions() {
    final options = widget.post.questionData?.options ?? [];
    final questionType = widget.post.questionType;

    if (questionType == QuestionType.trueFalse) {
      return Column(
        children: [
          _buildTrueFalseButton("True", 0),
          const SizedBox(height: 12),
          _buildTrueFalseButton("False", 1),
        ],
      );
    }

    if (questionType == QuestionType.checkbox) {
      return Column(
        children: options.asMap().entries.map((entry) {
          final index = entry.key;
          final option = entry.value;
          return CheckboxListTile(
            title: Text(option),
            value: _selectedAnswers.contains(index),
            onChanged: (value) {
              setState(() {
                if (value == true) {
                  _selectedAnswers.add(index);
                } else {
                  _selectedAnswers.remove(index);
                }
              });
            },
            controlAffinity: ListTileControlAffinity.leading,
          );
        }).toList(),
      );
    }

    return Column(
      children: options.asMap().entries.map((entry) {
        final index = entry.key;
        final option = entry.value;
        return RadioListTile<int>(
          title: Text(option),
          value: index,
          groupValue: _selectedAnswer,
          onChanged: (value) {
            setState(() {
              _selectedAnswer = value;
            });
          },
        );
      }).toList(),
    );
  }

  Widget _buildTrueFalseButton(String label, int value) {
    final isSelected = _selectedAnswer == value;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedAnswer = value;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primaryContainer
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isSelected
                  ? Theme.of(context).colorScheme.onPrimaryContainer
                  : Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResultView() {
    final result = _result!;
    final isCorrect = result.isCorrect;
    final correctAnswer = result.correctAnswer;
    final options = widget.post.questionData?.options ?? [];

    String correctAnswerText = "";
    if (correctAnswer is List) {
      correctAnswerText =
          correctAnswer.map((i) => options[i as int]).join(", ");
    } else {
      correctAnswerText = options[correctAnswer as int];
    }

    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isCorrect ? Icons.check_circle : Icons.cancel,
            size: 80,
            color: isCorrect ? Colors.green : Colors.red,
          ),
          const SizedBox(height: 16),
          Text(
            isCorrect ? "Correct!" : "Incorrect",
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: isCorrect ? Colors.green : Colors.red,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Correct Answer:",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  correctAnswerText,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                children: [
                  Text(
                    "${result.answersCount}",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  Text(
                    "Answered",
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
              Column(
                children: [
                  Text(
                    "${result.correctPercentage.toStringAsFixed(0)}%",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  Text(
                    "Correct Rate",
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(onPressed: _close, child: const Text("Close")),
          ),
        ],
      ),
    );
  }
}
