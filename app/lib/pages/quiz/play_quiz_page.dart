import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "dart:async";
import "../../services/api_service.dart";
import "./widgets/quiz_stats_header.dart";
import "./widgets/quiz_question_card.dart";
import "./widgets/quiz_option_button.dart";
import "./widgets/quiz_progress_button.dart";
import "./widgets/quiz_scaffolds.dart";
import "./quiz_dialogs.dart";

class PlayQuizPage extends StatefulWidget {
  final String quizId;
  final bool isPreview;

  const PlayQuizPage({required this.quizId, this.isPreview = false, super.key});

  @override
  State<PlayQuizPage> createState() => _PlayQuizPageState();
}

class _PlayQuizPageState extends State<PlayQuizPage>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _quizData;
  List<dynamic> _questions = [];
  int _totalQuestionCount = 0;
  int _currentQuestionIndex = 0;
  int? _selectedAnswerIndex;
  bool _showResult = false;
  int _score = 0;
  int _coins = 200;
  int _streak = 0;
  final List<int?> _userAnswers = [];
  final List<bool?> _answerResults = []; // Store isCorrect for each answer
  bool _isSubmitting = false;

  // Animation
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;

  // Timer features
  String? _sessionId;
  Map<String, dynamic>? _currentQuestionData;
  DateTime? _serverDeadline;
  bool _isTimeExpired = false;
  int _remainingSeconds = 30;
  int _totalSeconds = 30; // Track total time for progress calculation
  Timer? _countdownTimer;
  Timer? _autoAdvanceTimer;
  double _autoAdvanceSeconds =
      5.0; // Countdown after showing result (now double for smooth progress)
  bool _isHoldingNextButton = false; // Track if user is holding button

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(1.0, 0.0), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );
    _animationController.forward();
    _loadQuizData();
  }

  Future<void> _loadQuizData() async {
    try {
      final sessionResponse = await ApiService.createSession(widget.quizId);
      _sessionId = sessionResponse["id"];

      final quizResponse = await ApiService.getQuiz(widget.quizId);
      if (quizResponse == null) throw Exception("Failed to load quiz");

      setState(() {
        _quizData = quizResponse;
        _totalQuestionCount = quizResponse["questionCount"] ?? 0;
        _isLoading = false;
      });

      await _loadQuestionWithTiming(0);
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadQuestionWithTiming(int questionIndex) async {
    if (_sessionId == null) return;

    try {
      final response = await ApiService.fetchQuestionWithTiming(
        _sessionId!,
        questionIndex,
      );

      setState(() {
        _currentQuestionData = response["question"];
        _serverDeadline = DateTime.parse(response["timing"]["deadlineTime"]);
        _isTimeExpired = false;

        final now = DateTime.now();
        final calculatedSeconds = _serverDeadline!.difference(now).inSeconds;

        // Clamp to 0 minimum (no negative timers)
        _remainingSeconds = calculatedSeconds > 0 ? calculatedSeconds : 0;
        _totalSeconds = response["timing"]["timeLimit"] ?? 30;

        _startCountdownTimer();

        if (questionIndex >= _questions.length) {
          _questions.add(_currentQuestionData!);
          _userAnswers.add(null);
          _answerResults.add(null);
        }
      });
    } catch (e) {
      setState(() {
        _errorMessage = "Failed to load question: ${e.toString()}";
      });
    }
  }

  void _startCountdownTimer() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() => _remainingSeconds--);
      } else {
        timer.cancel();
        // Don't auto-expire - let server validate when user submits
        // Just keep timer at 0
      }
    });
  }

  void _startAutoAdvanceTimer() {
    _autoAdvanceTimer?.cancel();
    _autoAdvanceTimer = Timer.periodic(const Duration(milliseconds: 100), (
      timer,
    ) {
      if (_autoAdvanceSeconds > 0) {
        setState(() {
          // Speed: normal = 0.1s per tick, holding = 0.3s per tick (3x faster)
          final decrement = _isHoldingNextButton ? 0.3 : 0.1;
          _autoAdvanceSeconds = (_autoAdvanceSeconds - decrement).clamp(
            0.0,
            5.0,
          );
        });
      } else {
        timer.cancel();
        _nextQuestion(); // Auto-advance to next question
      }
    });
  }

  void _selectAnswer(int index) async {
    if (_showResult || _isSubmitting) return;

    setState(() {
      _selectedAnswerIndex = index;
      _isSubmitting = true;
    });

    // Auto-submit immediately
    _submitAnswer();
  }

  void _submitAnswer() async {
    if (_selectedAnswerIndex == null || _currentQuestionData == null) return;
    _countdownTimer?.cancel();

    try {
      final currentQuestion = _currentQuestionData!;
      final questionType = currentQuestion["type"] as String;

      String answerText;
      if (questionType == "single_choice") {
        final options = (currentQuestion["data"]["options"] as List)
            .map((opt) => opt is Map ? opt["text"] as String : opt as String)
            .toList();
        answerText = options[_selectedAnswerIndex!];
      } else {
        answerText = _selectedAnswerIndex == 0 ? "true" : "false";
      }

      final response = await ApiService.submitAnswerWithValidation(
        _sessionId!,
        currentQuestion["id"],
        answerText,
      );

      if (response["error"] == "time_expired") {
        setState(() {
          _isTimeExpired = true;
          _showResult = true;
          _isSubmitting = false;
          _streak = 0;
          // Record 0 score for expired question (no points added)
          _userAnswers[_currentQuestionIndex] = _selectedAnswerIndex;
          _answerResults[_currentQuestionIndex] = false; // Time expired = wrong
          _autoAdvanceSeconds = 5.0;
        });
        _startAutoAdvanceTimer();
        return;
      }

      final isCorrect = response["isCorrect"] as bool;
      final score = response["score"] as int;

      setState(() {
        _userAnswers[_currentQuestionIndex] = _selectedAnswerIndex;
        _answerResults[_currentQuestionIndex] = isCorrect; // Store the result!
        _showResult = true;
        _isSubmitting = false;
        _score += score;
        _autoAdvanceSeconds = 5; // Reset countdown

        if (isCorrect) {
          _streak++;
          _coins += 10;
        } else {
          _streak = 0;
        }
      });

      // Start auto-advance countdown
      _startAutoAdvanceTimer();
    } catch (e) {
      setState(() {
        _errorMessage = "Failed to submit answer: ${e.toString()}";
        _isSubmitting = false;
      });
    }
  }

  void _nextQuestion() async {
    _autoAdvanceTimer?.cancel(); // Cancel auto-advance timer

    if (_currentQuestionIndex < _totalQuestionCount - 1) {
      // Slide out animation
      await _animationController.reverse();

      setState(() {
        _currentQuestionIndex++;
        _selectedAnswerIndex = _userAnswers.length > _currentQuestionIndex
            ? _userAnswers[_currentQuestionIndex]
            : null;
        _showResult = false;
        _isTimeExpired = false;
        _remainingSeconds = 30;
        _totalSeconds = 30; // Reset total time
        _autoAdvanceSeconds = 5; // Reset auto-advance
      });

      await _loadQuestionWithTiming(_currentQuestionIndex);

      // Slide in animation
      _animationController.forward();
    } else {
      _showFinalResults();
    }
  }

  void _showFinalResults() {
    showQuizCompleteDialog(
      context,
      score: _score,
      totalQuestions: _totalQuestionCount,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) return const QuizLoadingScaffold();
    if (_errorMessage != null) return QuizErrorScaffold(error: _errorMessage!);

    final currentQuestion =
        _currentQuestionData ??
        (_questions.isNotEmpty ? _questions[_currentQuestionIndex] : null);

    if (currentQuestion == null) {
      return QuizLoadingScaffold(title: _quizData?["title"] ?? "Loading...");
    }

    final questionType = currentQuestion["type"] as String;
    final options = questionType == "single_choice"
        ? (currentQuestion["data"]["options"] as List)
              .map((opt) => opt is Map ? opt["text"] as String : opt as String)
              .toList()
        : ["True", "False"];

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
          // Stats Header
          QuizStatsHeader(
            coins: _coins,
            score: _score,
            streak: _streak,
            remainingSeconds: _remainingSeconds,
          ),

          // Loading indicator
          if (_currentQuestionData == null)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              color: Colors.orange.withValues(alpha: 0.1),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Colors.orange,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    "Loading question...",
                    style: TextStyle(
                      color: Colors.orange,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

          // Progress Bar (Timer)
          if (_totalSeconds > 0)
            LinearProgressIndicator(
              value: _remainingSeconds / _totalSeconds,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(
                _remainingSeconds > 10
                    ? const Color(0xFF64A7FF)
                    : _remainingSeconds > 5
                    ? Colors.orange
                    : Colors.red,
              ),
              minHeight: 4,
            ),

          // Question Content
          Expanded(
            child: SlideTransition(
              position: _slideAnimation,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    QuizQuestionCard(
                      questionText: currentQuestion["questionText"],
                      imageUrl: currentQuestion["imageUrl"],
                    ),
                    const SizedBox(height: 32),

                    // Options
                    ...options.asMap().entries.map((entry) {
                      final index = entry.key;
                      final option = entry.value;
                      final isSelected = _selectedAnswerIndex == index;
                      bool? isCorrect;

                      if (_showResult && isSelected) {
                        // Use stored result from server response
                        isCorrect = _answerResults[_currentQuestionIndex];
                      }

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: QuizOptionButton(
                          option: option,
                          isSelected: isSelected,
                          isCorrect: _showResult ? isCorrect : null,
                          isSubmitting: _isSubmitting,
                          onTap:
                              (_isTimeExpired || _showResult || _isSubmitting)
                              ? null
                              : () => _selectAnswer(index),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ),

          // Bottom Action Bar - Progress bar button
          if (_showResult)
            QuizProgressButton(
              progress: 1 - (_autoAdvanceSeconds / 5.0),
              isHolding: _isHoldingNextButton,
              isLastQuestion: _currentQuestionIndex >= _totalQuestionCount - 1,
              onTapDown: () => setState(() => _isHoldingNextButton = true),
              onTapUp: () => setState(() => _isHoldingNextButton = false),
              onTapCancel: () => setState(() => _isHoldingNextButton = false),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _autoAdvanceTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }
}
