import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "package:supabase_flutter/supabase_flutter.dart";
import "dart:convert";
import "package:http/http.dart" as http;
import "package:flutter_dotenv/flutter_dotenv.dart";

class PlayQuizPage extends StatefulWidget {
  final String quizId;

  const PlayQuizPage({required this.quizId, super.key});

  @override
  State<PlayQuizPage> createState() => _PlayQuizPageState();
}

class _PlayQuizPageState extends State<PlayQuizPage> {
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _quizData;
  List<dynamic> _questions = [];
  int _currentQuestionIndex = 0;
  int? _selectedAnswerIndex;
  bool _showResult = false;
  int _score = 0;
  final List<int?> _userAnswers = [];

  @override
  void initState() {
    super.initState();
    _loadQuizData();
  }

  Future<void> _loadQuizData() async {
    try {
      final session = Supabase.instance.client.auth.currentSession;
      final serverUrl = dotenv.env["SERVER_URL"] ?? "http://localhost:8000";

      final quizResponse = await http.get(
        Uri.parse("$serverUrl/api/quiz/${widget.quizId}"),
        headers: {
          if (session != null) "Authorization": "Bearer ${session.accessToken}",
        },
      );

      if (quizResponse.statusCode != 200) {
        throw Exception("Failed to load quiz");
      }

      final questionsResponse = await http.get(
        Uri.parse("$serverUrl/api/quiz/${widget.quizId}/questions"),
        headers: {
          if (session != null) "Authorization": "Bearer ${session.accessToken}",
        },
      );

      if (questionsResponse.statusCode != 200) {
        throw Exception("Failed to load questions");
      }

      final quiz = jsonDecode(quizResponse.body);
      final questions = jsonDecode(questionsResponse.body) as List;

      if (questions.isEmpty) {
        throw Exception("This quiz has no questions");
      }

      setState(() {
        _quizData = quiz;
        _questions = questions;
        _userAnswers.addAll(List.filled(questions.length, null));
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _selectAnswer(int index) {
    if (!_showResult) {
      setState(() {
        _selectedAnswerIndex = index;
      });
    }
  }

  void _submitAnswer() {
    if (_selectedAnswerIndex == null) return;

    final currentQuestion = _questions[_currentQuestionIndex];
    final correctIndex = currentQuestion["data"]["correctIndex"] as int?;
    final correctAnswer = currentQuestion["data"]["correctAnswer"] as bool?;

    bool isCorrect = false;
    if (correctIndex != null) {
      isCorrect = _selectedAnswerIndex == correctIndex;
    } else if (correctAnswer != null) {
      isCorrect =
          (_selectedAnswerIndex == 0 && correctAnswer) ||
          (_selectedAnswerIndex == 1 && !correctAnswer);
    }

    setState(() {
      _userAnswers[_currentQuestionIndex] = _selectedAnswerIndex;
      _showResult = true;
      if (isCorrect) _score++;
    });
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _selectedAnswerIndex = _userAnswers[_currentQuestionIndex];
        _showResult = false;
      });
    } else {
      _showFinalResults();
    }
  }

  void _previousQuestion() {
    if (_currentQuestionIndex > 0) {
      setState(() {
        _currentQuestionIndex--;
        _selectedAnswerIndex = _userAnswers[_currentQuestionIndex];
        _showResult = _userAnswers[_currentQuestionIndex] != null;
      });
    }
  }

  void _showFinalResults() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Quiz Complete!"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _score >= _questions.length * 0.7
                  ? Icons.emoji_events
                  : Icons.thumb_up,
              size: 64,
              color: const Color(0xFF64A7FF),
            ),
            const SizedBox(height: 16),
            Text(
              "Your Score",
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              "$_score / ${_questions.length}",
              style: const TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: Color(0xFF64A7FF),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "${((_score / _questions.length) * 100).toStringAsFixed(0)}%",
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: const Text("Loading Quiz..."),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: const Text("Error"),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => context.pop(),
                  child: const Text("Go Back"),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final currentQuestion = _questions[_currentQuestionIndex];
    final questionType = currentQuestion["type"] as String;
    final options = questionType == "multiple_choice"
        ? (currentQuestion["data"]["options"] as List).cast<String>()
        : ["True", "False"];
    final correctIndex = currentQuestion["data"]["correctIndex"] as int?;
    final correctAnswer = currentQuestion["data"]["correctAnswer"] as bool?;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(_quizData!["title"]),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          LinearProgressIndicator(
            value: (_currentQuestionIndex + 1) / _questions.length,
            backgroundColor: Colors.grey[300],
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF64A7FF)),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Question ${_currentQuestionIndex + 1} of ${_questions.length}",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        "Score: $_score",
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
                    final isSelected = _selectedAnswerIndex == index;
                    bool? isCorrect;

                    if (_showResult) {
                      if (correctIndex != null) {
                        isCorrect = index == correctIndex;
                      } else if (correctAnswer != null) {
                        isCorrect =
                            (index == 0 && correctAnswer) ||
                            (index == 1 && !correctAnswer);
                      }
                    }

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _OptionButton(
                        option: option,
                        isSelected: isSelected,
                        isCorrect: _showResult ? isCorrect : null,
                        onTap: () => _selectAnswer(index),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
          Container(
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
                if (_currentQuestionIndex > 0)
                  IconButton(
                    onPressed: _previousQuestion,
                    icon: const Icon(Icons.arrow_back),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.grey[200],
                    ),
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _showResult
                        ? _nextQuestion
                        : (_selectedAnswerIndex != null ? _submitAnswer : null),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF64A7FF),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      _showResult
                          ? (_currentQuestionIndex < _questions.length - 1
                                ? "Next Question"
                                : "View Results")
                          : "Submit Answer",
                      style: const TextStyle(
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
    );
  }
}

class _OptionButton extends StatelessWidget {
  final String option;
  final bool isSelected;
  final bool? isCorrect;
  final VoidCallback onTap;

  const _OptionButton({
    required this.option,
    required this.isSelected,
    required this.isCorrect,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color borderColor;
    Color textColor;
    IconData? icon;

    if (isCorrect == true) {
      backgroundColor = Colors.green[50]!;
      borderColor = Colors.green;
      textColor = Colors.green[900]!;
      icon = Icons.check_circle;
    } else if (isCorrect == false && isSelected) {
      backgroundColor = Colors.red[50]!;
      borderColor = Colors.red;
      textColor = Colors.red[900]!;
      icon = Icons.cancel;
    } else if (isSelected) {
      backgroundColor = const Color(0xFF64A7FF).withValues(alpha: 0.1);
      borderColor = const Color(0xFF64A7FF);
      textColor = const Color(0xFF64A7FF);
    } else {
      backgroundColor = Colors.grey[100]!;
      borderColor = Colors.grey[300]!;
      textColor = Colors.black87;
    }

    return InkWell(
      onTap: isCorrect == null ? onTap : null,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: backgroundColor,
          border: Border.all(color: borderColor, width: 2),
          borderRadius: BorderRadius.circular(12),
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
            if (icon != null) Icon(icon, color: borderColor),
          ],
        ),
      ),
    );
  }
}
