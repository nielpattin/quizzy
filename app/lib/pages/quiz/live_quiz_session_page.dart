import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../services/websocket_service.dart';
import './widgets/connection_status_indicator.dart';
import './widgets/live_participant_list.dart';
import './widgets/live_leaderboard.dart';
import './widgets/session_status_indicator.dart';

class LiveQuizSessionPage extends StatefulWidget {
  final String sessionId;

  const LiveQuizSessionPage({required this.sessionId, super.key});

  @override
  State<LiveQuizSessionPage> createState() => _LiveQuizSessionPageState();
}

class _LiveQuizSessionPageState extends State<LiveQuizSessionPage> {
  final WebSocketService _websocketService = WebSocketService();

  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _sessionData;
  List<dynamic> _questions = [];
  int _currentQuestionIndex = 0;
  int? _selectedAnswerIndex;
  bool _showResult = false;
  int _score = 0;
  final List<int?> _userAnswers = [];

  bool _showRealtimePanel = true;
  bool _isHost = false;

  @override
  void initState() {
    super.initState();
    _initializeSession();
  }

  @override
  void dispose() {
    _websocketService.dispose();
    super.dispose();
  }

  Future<void> _initializeSession() async {
    try {
      // Connect to WebSocket
      await _websocketService.connect();

      // Join the session
      await _websocketService.joinSession(widget.sessionId);

      // Load session data
      await _loadSessionData();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadSessionData() async {
    try {
      final session = Supabase.instance.client.auth.currentSession;
      final serverUrl = dotenv.env["SERVER_URL"] ?? "http://localhost:8000";

      // Get session info
      final sessionResponse = await http.get(
        Uri.parse("$serverUrl/api/session/${widget.sessionId}"),
        headers: {
          if (session != null) "Authorization": "Bearer ${session.accessToken}",
        },
      );

      if (sessionResponse.statusCode != 200) {
        throw Exception("Failed to load session");
      }

      // Get session questions
      final questionsResponse = await http.get(
        Uri.parse("$serverUrl/api/session/${widget.sessionId}/questions"),
        headers: {
          if (session != null) "Authorization": "Bearer ${session.accessToken}",
        },
      );

      if (questionsResponse.statusCode != 200) {
        throw Exception("Failed to load questions");
      }

      final sessionData = jsonDecode(sessionResponse.body);
      final questions = jsonDecode(questionsResponse.body) as List;

      if (questions.isEmpty) {
        throw Exception("This session has no questions");
      }

      // Check if current user is host
      final currentUserId = session?.user?.id;
      _isHost = sessionData['host']['id'] == currentUserId;

      setState(() {
        _sessionData = sessionData;
        _questions = questions;
        _userAnswers.addAll(List.filled(questions.length, null));
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
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

    // TODO: Send score update via WebSocket
    _sendScoreUpdate();
  }

  Future<void> _sendScoreUpdate() async {
    try {
      final session = Supabase.instance.client.auth.currentSession;
      if (session == null) return;

      final serverUrl = dotenv.env["SERVER_URL"] ?? "http://localhost:8000";

      // This would need to be implemented in the backend
      // For now, we'll simulate the score update
      await http.post(
        Uri.parse("$serverUrl/api/session/${widget.sessionId}/score"),
        headers: {
          "Authorization": "Bearer ${session.accessToken}",
          "Content-Type": "application/json",
        },
        body: jsonEncode({"score": _score}),
      );
    } catch (e) {
      print("Error sending score update: $e");
    }
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

  void _toggleRealtimePanel() {
    setState(() {
      _showRealtimePanel = !_showRealtimePanel;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: const Text("Loading Session..."),
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: const [ConnectionStatusIndicator(), SizedBox(width: 16)],
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
        title: Text(_sessionData!["title"]),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
        actions: [
          const SessionStatusIndicator(),
          const SizedBox(width: 8),
          const ConnectionStatusIndicator(),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          LinearProgressIndicator(
            value: (_currentQuestionIndex + 1) / _questions.length,
            backgroundColor: Colors.grey[300],
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF64A7FF)),
          ),
          Expanded(
            child: Row(
              children: [
                // Main quiz content
                Expanded(
                  flex: _showRealtimePanel ? 2 : 3,
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

                // Real-time panel
                if (_showRealtimePanel) ...[
                  Container(width: 1, color: Colors.grey[300]),
                  Expanded(
                    flex: 1,
                    child: Container(
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        border: Border(
                          left: BorderSide(color: Colors.grey[300]!),
                        ),
                      ),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Session status
                            const SessionStatusCard(title: "Session Info"),
                            const SizedBox(height: 16),

                            // Participants
                            const LiveParticipantList(
                              title: "Live Participants",
                              maxHeight: 150,
                            ),
                            const SizedBox(height: 16),

                            // Leaderboard
                            const LiveLeaderboard(
                              title: "Live Leaderboard",
                              maxItems: 5,
                            ),

                            const SizedBox(height: 16),

                            // Host controls
                            if (_isHost) ...[
                              _buildHostControls(),
                              const SizedBox(height: 16),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ],
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
                IconButton(
                  onPressed: _toggleRealtimePanel,
                  icon: Icon(
                    _showRealtimePanel
                        ? Icons.visibility_off
                        : Icons.visibility,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.grey[200],
                  ),
                  tooltip: _showRealtimePanel
                      ? 'Hide Real-time Panel'
                      : 'Show Real-time Panel',
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

  Widget _buildHostControls() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.settings, color: const Color(0xFF64A7FF), size: 20),
                const SizedBox(width: 8),
                Text(
                  "Host Controls",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  // TODO: Implement start session
                },
                icon: const Icon(Icons.play_arrow),
                label: const Text("Start Session"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  // TODO: Implement pause session
                },
                icon: const Icon(Icons.pause),
                label: const Text("Pause Session"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  // TODO: Implement end session
                },
                icon: const Icon(Icons.stop),
                label: const Text("End Session"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
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
