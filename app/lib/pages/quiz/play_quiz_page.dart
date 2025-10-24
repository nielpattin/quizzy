import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "dart:async";
import "dart:convert";
import "package:http/http.dart" as http;
import "package:flutter_dotenv/flutter_dotenv.dart";
import "package:supabase_flutter/supabase_flutter.dart";
import "../../../services/websocket_service.dart";
import "../../../services/real_time_notification_service.dart";
import "../../../services/api_service.dart";
import "./widgets/connection_status_indicator.dart";
import "./widgets/live_participant_list.dart";
import "./widgets/live_leaderboard.dart";
import "../../../widgets/real_time_notification_widget.dart";
import "../../../widgets/secure_question_timer.dart";

class PlayQuizPage extends StatefulWidget {
  final String quizId;
  final bool isPreview;

  const PlayQuizPage({required this.quizId, this.isPreview = false, super.key});

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

  // Timer security features
  String? _sessionId;
  Map<String, dynamic>? _currentQuestionData;
  DateTime? _serverDeadline;
  bool _isTimeExpired = false;

  // Real-time features
  final WebSocketService _websocketService = WebSocketService();
  final RealTimeNotificationService _notificationService =
      RealTimeNotificationService();
  bool _showRealTimeFeatures = true;
  bool _showLeaderboard = false;
  StreamSubscription? _connectionSubscription;
  StreamSubscription? _messageSubscription;

  @override
  void initState() {
    super.initState();
    if (widget.isPreview) {
      _loadQuizDataForPreview();
    } else {
      _loadQuizData();
      _initRealTimeFeatures();
    }
  }

  Future<void> _loadQuizData() async {
    try {
      // Create session first
      final sessionResponse = await ApiService.createSession(widget.quizId);
      _sessionId = sessionResponse["id"];

      // Load quiz data
      final quizResponse = await ApiService.getQuiz(widget.quizId);

      if (quizResponse == null) {
        throw Exception("Failed to load quiz");
      }

      setState(() {
        _quizData = quizResponse;
        _isLoading = false;
      });

      // Load first question with timing
      await _loadQuestionWithTiming(0);
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadQuizDataForPreview() async {
    try {
      final quizResponse = await ApiService.getQuiz(widget.quizId);

      if (quizResponse == null) {
        throw Exception("Failed to load quiz");
      }

      final session = Supabase.instance.client.auth.currentSession;
      if (session == null) {
        throw Exception("Not authenticated");
      }

      final serverUrl = dotenv.env["SERVER_URL"];
      final questionsResponse = await http.get(
        Uri.parse("$serverUrl/api/quiz/${widget.quizId}/questions"),
        headers: {"Authorization": "Bearer ${session.accessToken}"},
      );

      if (questionsResponse.statusCode != 200) {
        throw Exception("Failed to load questions");
      }

      final List<dynamic> questionsList = jsonDecode(questionsResponse.body);

      if (questionsList.isEmpty) {
        throw Exception("No questions found in this quiz");
      }

      setState(() {
        _quizData = quizResponse;
        _questions = questionsList;
        _userAnswers.addAll(List.filled(questionsList.length, null));
        _currentQuestionData = questionsList[0];
        _isLoading = false;
      });
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

        // Add question to list if new
        if (questionIndex >= _questions.length) {
          _questions.add(_currentQuestionData!);
          _userAnswers.add(null);
        }
      });
    } catch (e) {
      setState(() {
        _errorMessage = "Failed to load question: ${e.toString()}";
      });
    }
  }

  Future<void> _initRealTimeFeatures() async {
    if (!_showRealTimeFeatures) return;

    try {
      // Initialize notification service
      _notificationService.init();

      // Connect to WebSocket
      await _websocketService.connect();

      // Join quiz-specific room for real-time features
      await _websocketService.joinSession(widget.quizId);

      // Listen to connection status changes
      _connectionSubscription = _websocketService.connectionStatus.listen((
        status,
      ) {
        // Update UI based on connection status
        if (mounted) {
          setState(() {});
        }
      });

      // Listen to WebSocket messages
      _messageSubscription = _websocketService.messages.listen((message) {
        _handleWebSocketMessage(message);
      });
    } catch (e) {
      debugPrint('Failed to initialize real-time features: $e');
      // Silently fail - quiz will work without real-time features
    }
  }

  void _handleWebSocketMessage(WebSocketMessage message) {
    if (!mounted) return;

    switch (message.type) {
      case WebSocketMessageType.participantJoined:
      case WebSocketMessageType.participantLeft:
      case WebSocketMessageType.participantDisconnected:
        // Update participant count display
        setState(() {});
        break;

      case WebSocketMessageType.leaderboardUpdate:
        // Update leaderboard display
        setState(() {});
        break;

      case WebSocketMessageType.sessionState:
        // Handle session state changes
        setState(() {});
        break;

      default:
        break;
    }
  }

  void _handleTimeExpired() {
    if (!_isTimeExpired) {
      setState(() {
        _isTimeExpired = true;
        _showResult = true;
      });
    }
  }

  void _toggleRealTimeFeatures() {
    setState(() {
      _showRealTimeFeatures = !_showRealTimeFeatures;
    });

    if (_showRealTimeFeatures) {
      _initRealTimeFeatures();
    } else {
      _websocketService.leaveSession();
    }
  }

  void _toggleLeaderboard() {
    setState(() {
      _showLeaderboard = !_showLeaderboard;
    });
  }

  void _selectAnswer(int index) {
    if (!_showResult) {
      setState(() {
        _selectedAnswerIndex = index;
      });
    }
  }

  void _submitAnswer() async {
    if (_selectedAnswerIndex == null || _currentQuestionData == null) return;

    try {
      final currentQuestion = _currentQuestionData!;
      final questionType = currentQuestion["type"] as String;

      if (widget.isPreview) {
        if (questionType == "single_choice" ||
            questionType == "single_choice") {
          final correctAnswer = currentQuestion["data"]["correctAnswer"] as int;
          _selectedAnswerIndex == correctAnswer;
        } else if (questionType == "true_false") {
          final correctAnswer =
              currentQuestion["data"]["correctAnswer"] as bool;
          (_selectedAnswerIndex == 0) == correctAnswer;
        } else if (questionType == "checkbox") {
          final correctAnswers =
              (currentQuestion["data"]["correctAnswers"] as List).cast<int>();
          correctAnswers.contains(_selectedAnswerIndex);
        }

        setState(() {
          _userAnswers[_currentQuestionIndex] = _selectedAnswerIndex;
          _showResult = true;
        });
      } else {
        String answerText;

        if (questionType == "single_choice") {
          final options = (currentQuestion["data"]["options"] as List)
              .cast<String>();
          answerText = options[_selectedAnswerIndex!];
        } else if (questionType == "true_false") {
          answerText = _selectedAnswerIndex == 0 ? "true" : "false";
        } else {
          answerText = _selectedAnswerIndex.toString();
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
          });
          return;
        }

        response["isCorrect"] as bool;
        final score = response["score"] as int;

        setState(() {
          _userAnswers[_currentQuestionIndex] = _selectedAnswerIndex;
          _showResult = true;
          _score += score;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Failed to submit answer: ${e.toString()}";
      });
    }
  }

  void _nextQuestion() async {
    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _selectedAnswerIndex = _userAnswers[_currentQuestionIndex];
        _showResult = false;
        _isTimeExpired = false;
      });

      if (widget.isPreview) {
        setState(() {
          _currentQuestionData = _questions[_currentQuestionIndex];
        });
      } else {
        await _loadQuestionWithTiming(_currentQuestionIndex);
      }
    } else {
      _showFinalResults();
    }
  }

  void _previousQuestion() async {
    if (_currentQuestionIndex > 0) {
      setState(() {
        _currentQuestionIndex--;
        _selectedAnswerIndex = _userAnswers[_currentQuestionIndex];
        _showResult = _userAnswers[_currentQuestionIndex] != null;
        _isTimeExpired = false;
      });

      // Load previous question with timing
      await _loadQuestionWithTiming(_currentQuestionIndex);
    }
  }

  void _showFinalResults() {
    // Broadcast score completion if real-time features are enabled
    if (_showRealTimeFeatures &&
        _websocketService.currentStatus == ConnectionStatus.connected) {
      // Note: Using public method or creating a public method in WebSocketService
      // For now, we'll skip this as _sendMessage is private
    }

    if (widget.isPreview) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text("Preview Complete!"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.check_circle_outline,
                size: 64,
                color: Color(0xFF64A7FF),
              ),
              const SizedBox(height: 16),
              Text(
                "You've completed the preview",
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                textAlign: TextAlign.center,
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
      return;
    }

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

    final currentQuestion =
        _currentQuestionData ?? _questions[_currentQuestionIndex];
    if (currentQuestion == null) {
      return const Center(child: Text("Question not loaded"));
    }

    final questionType = currentQuestion["type"] as String;
    final options = questionType == "single_choice"
        ? (currentQuestion["data"]["options"] as List).cast<String>()
        : ["True", "False"];
    final correctIndex = currentQuestion["data"]["correctIndex"] as int?;
    final correctAnswer = currentQuestion["data"]["correctAnswer"] as bool?;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: widget.isPreview
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("Preview Mode"),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      "PREVIEW",
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              )
            : Text(_quizData!["title"]),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (!widget.isPreview) ...[
            if (_showRealTimeFeatures) ...[
              RealTimeNotificationWidget(
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => const NotificationPanel(),
                  );
                },
              ),
              const SizedBox(width: 8),
              const ConnectionStatusIndicator(),
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(
                  _showLeaderboard
                      ? Icons.leaderboard
                      : Icons.leaderboard_outlined,
                  color: _showLeaderboard
                      ? const Color(0xFF64A7FF)
                      : Colors.white,
                ),
                onPressed: _toggleLeaderboard,
                tooltip: 'Toggle Leaderboard',
              ),
            ],
            IconButton(
              icon: Icon(
                _showRealTimeFeatures ? Icons.wifi : Icons.wifi_off,
                color: _showRealTimeFeatures
                    ? const Color(0xFF64A7FF)
                    : Colors.white,
              ),
              onPressed: _toggleRealTimeFeatures,
              tooltip: _showRealTimeFeatures
                  ? 'Disable Real-time'
                  : 'Enable Real-time',
            ),
          ],
        ],
      ),
      body: Column(
        children: [
          LinearProgressIndicator(
            value: (_currentQuestionIndex + 1) / _questions.length,
            backgroundColor: Colors.grey[300],
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF64A7FF)),
          ),

          // Real-time features panel
          if (_showRealTimeFeatures) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: theme.cardColor,
                border: Border(
                  bottom: BorderSide(
                    color: Colors.grey.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  // Live participant count
                  StreamBuilder<List<Participant>>(
                    stream: _websocketService.participants,
                    initialData: const [],
                    builder: (context, snapshot) {
                      final participantCount = snapshot.data?.length ?? 0;
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF64A7FF).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.people,
                              size: 16,
                              color: const Color(0xFF64A7FF),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '$participantCount playing',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF64A7FF),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const Spacer(),
                  // Connection status
                  Row(
                    children: [
                      const ConnectionStatusIndicator(size: 8),
                      const SizedBox(width: 4),
                      StreamBuilder<ConnectionStatus>(
                        stream: _websocketService.connectionStatus,
                        initialData: ConnectionStatus.disconnected,
                        builder: (context, snapshot) {
                          final status =
                              snapshot.data ?? ConnectionStatus.disconnected;
                          String statusText;
                          switch (status) {
                            case ConnectionStatus.connected:
                              statusText = 'Live';
                              break;
                            case ConnectionStatus.connecting:
                            case ConnectionStatus.reconnecting:
                              statusText = 'Connecting...';
                              break;
                            case ConnectionStatus.disconnected:
                              statusText = 'Offline';
                              break;
                            case ConnectionStatus.error:
                              statusText = 'Error';
                              break;
                          }
                          return Text(
                            statusText,
                            style: TextStyle(
                              fontSize: 12,
                              color: status == ConnectionStatus.connected
                                  ? Colors.green
                                  : Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],

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
                      if (!widget.isPreview)
                        Row(
                          children: [
                            Text(
                              "Score: $_score",
                              style: const TextStyle(
                                fontSize: 16,
                                color: Color(0xFF64A7FF),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (_showRealTimeFeatures) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'LIVE',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                    ],
                  ),

                  // Live leaderboard (shown when toggled)
                  if (!widget.isPreview &&
                      _showRealTimeFeatures &&
                      _showLeaderboard) ...[
                    const SizedBox(height: 24),
                    const LiveLeaderboard(
                      title: "Live Leaderboard",
                      maxItems: 5,
                      showTopThreeOnly: true,
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Live participant list (compact version)
                  if (!widget.isPreview &&
                      _showRealTimeFeatures &&
                      !_showLeaderboard) ...[
                    const SizedBox(height: 16),
                    const LiveParticipantList(
                      title: "Also Playing",
                      maxHeight: 120,
                      showConnectionStatus: false,
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Timer widget (server for real game only)
                  if (!widget.isPreview && _serverDeadline != null) ...[
                    const SizedBox(height: 16),
                    SecureQuestionTimer(
                      serverDeadline: _serverDeadline!,
                      onTimeExpired: _handleTimeExpired,
                    ),
                    const SizedBox(height: 16),
                  ],

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
                        onTap: _isTimeExpired
                            ? null
                            : () => _selectAnswer(index),
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
                    onPressed: _isTimeExpired
                        ? null
                        : (_showResult
                              ? _nextQuestion
                              : (_selectedAnswerIndex != null
                                    ? _submitAnswer
                                    : null)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isTimeExpired
                          ? Colors.grey
                          : const Color(0xFF64A7FF),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      _isTimeExpired
                          ? "Time Expired"
                          : (_showResult
                                ? (_currentQuestionIndex < _questions.length - 1
                                      ? "Next Question"
                                      : "View Results")
                                : "Submit Answer"),
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

  @override
  void dispose() {
    _connectionSubscription?.cancel();
    _messageSubscription?.cancel();
    _notificationService.dispose();
    if (!widget.isPreview && _showRealTimeFeatures) {
      _websocketService.leaveSession();
    }
    super.dispose();
  }
}

class _OptionButton extends StatelessWidget {
  final String option;
  final bool isSelected;
  final bool? isCorrect;
  final VoidCallback? onTap;

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
