import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../services/websocket_service.dart';
import '../quiz/widgets/connection_status_indicator.dart';
import '../quiz/widgets/session_status_indicator.dart';
import 'controllers/quiz_session_controller.dart';
import 'widgets/quiz_question_card.dart';
import 'widgets/quiz_answer_buttons.dart';

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
  QuizSessionController? _controller;

  @override
  void initState() {
    super.initState();
    _initializeSession();
  }

  @override
  void dispose() {
    _websocketService.dispose();
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _initializeSession() async {
    try {
      await _websocketService.connect();
      await _websocketService.joinSession(widget.sessionId);
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

      final sessionResponse = await http.get(
        Uri.parse("$serverUrl/api/session/${widget.sessionId}"),
        headers: {
          if (session != null) "Authorization": "Bearer ${session.accessToken}",
        },
      );

      final questionsResponse = await http.get(
        Uri.parse("$serverUrl/api/session/${widget.sessionId}/questions"),
        headers: {
          if (session != null) "Authorization": "Bearer ${session.accessToken}",
        },
      );

      if (sessionResponse.statusCode != 200) {
        throw Exception("Failed to load session");
      }

      if (questionsResponse.statusCode != 200) {
        throw Exception("Failed to load questions");
      }

      final sessionData = jsonDecode(sessionResponse.body);
      final questions = jsonDecode(questionsResponse.body) as List;

      if (questions.isEmpty) {
        throw Exception("This session has no questions");
      }

      setState(() {
        _sessionData = sessionData;
        _controller = QuizSessionController(
          questions: questions,
          sessionId: widget.sessionId,
        );
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
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
              _controller!.score >= _controller!.questions.length * 0.7
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
              "${_controller!.score} / ${_controller!.questions.length}",
              style: const TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: Color(0xFF64A7FF),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "${((_controller!.score / _controller!.questions.length) * 100).toStringAsFixed(0)}%",
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
        actions: const [
          SessionStatusIndicator(),
          SizedBox(width: 8),
          ConnectionStatusIndicator(),
          SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          LinearProgressIndicator(
            value:
                (_controller!.currentQuestionIndex + 1) /
                _controller!.questions.length,
            backgroundColor: Colors.grey[300],
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF64A7FF)),
          ),
          Expanded(
            child: ListenableBuilder(
              listenable: _controller!,
              builder: (context, _) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: QuizQuestionCard(controller: _controller!),
                );
              },
            ),
          ),
          ListenableBuilder(
            listenable: _controller!,
            builder: (context, _) {
              return QuizAnswerButtons(
                controller: _controller!,
                onShowResults: _showFinalResults,
              );
            },
          ),
        ],
      ),
    );
  }
}
