import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:go_router/go_router.dart";
import "package:supabase_flutter/supabase_flutter.dart";
import "dart:convert";
import "dart:async";
import "package:http/http.dart" as http;
import "package:flutter_dotenv/flutter_dotenv.dart";
import "../../services/api_service.dart";
import "../../services/websocket_service.dart";
import "widgets/session_qr_modal.dart";

/// Session Detail Page - For viewing and resuming existing sessions
/// Used by Continue Playing cards
/// Routes user to appropriate page based on session state
class SessionDetailPage extends StatefulWidget {
  final String sessionId;

  const SessionDetailPage({super.key, required this.sessionId});

  @override
  State<SessionDetailPage> createState() => _SessionDetailPageState();
}

class _SessionDetailPageState extends State<SessionDetailPage>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _sessionData;
  Map<String, dynamic>? _quizData;
  String? _currentUserId;
  bool _isHost = false;

  // WebSocket state
  StreamSubscription<List<Participant>>? _participantsSubscription;
  StreamSubscription<WebSocketMessage>? _messagesSubscription;
  List<Participant> _participants = [];
  final _wsService = WebSocketService();

  // Tab controller
  late TabController _tabController;

  // My participants data
  List<Map<String, dynamic>> _myParticipants = [];
  bool _loadingMyParticipants = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    _loadSessionData();
    _setupWebSocket();
    _loadMyParticipants();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _participantsSubscription?.cancel();
    _messagesSubscription?.cancel();
    super.dispose();
  }

  Future<void> _setupWebSocket() async {
    try {
      // Connect to WebSocket
      await _wsService.connect();

      // Join session for real-time updates
      await _wsService.joinSession(widget.sessionId);

      // Listen to participants stream for real-time updates
      _participantsSubscription = _wsService.participants.listen((
        participants,
      ) {
        if (mounted) {
          setState(() {
            _participants = participants;
          });
        }
      });

      // Listen for session events to keep session state up-to-date
      _messagesSubscription = _wsService.messages.listen((message) {
        if (!mounted) return;

        if (message.type == WebSocketMessageType.sessionStarted) {
          if (message.sessionId == widget.sessionId) {
            debugPrint('[SessionDetail] Session started! Button will enable.');
            // Update session state to live
            setState(() {
              _sessionData = {
                ..._sessionData ?? {},
                'isLive': true,
                'startedAt': DateTime.now().toIso8601String(),
              };
            });
            // Don't auto-navigate - let user click the button to join
          }
        } else if (message.type == WebSocketMessageType.sessionUpdate) {
          if (message.sessionId == widget.sessionId && message.data != null) {
            debugPrint('[SessionDetail] Session updated - refreshing state');
            // Update session state when session changes
            setState(() {
              _sessionData = {
                ..._sessionData ?? {},
                if (message.data!.containsKey('isLive'))
                  'isLive': message.data!['isLive'],
                if (message.data!.containsKey('startedAt'))
                  'startedAt': message.data!['startedAt'],
                if (message.data!.containsKey('endedAt'))
                  'endedAt': message.data!['endedAt'],
              };
            });
          }
        } else if (message.type == WebSocketMessageType.sessionEnded) {
          if (message.sessionId == widget.sessionId) {
            debugPrint('[SessionDetail] Session ended');
            // Mark session as no longer live
            setState(() {
              _sessionData = {
                ..._sessionData ?? {},
                'isLive': false,
                'endedAt': DateTime.now().toIso8601String(),
              };
            });
          }
        }
      });
    } catch (e) {
      debugPrint('Error setting up WebSocket: $e');
    }
  }

  Future<void> _loadParticipants() async {
    try {
      final authSession = Supabase.instance.client.auth.currentSession;
      if (authSession == null) return;

      final serverUrl = dotenv.env["SERVER_URL"];
      final response = await http.get(
        Uri.parse("$serverUrl/api/session/${widget.sessionId}/participants"),
        headers: {"Authorization": "Bearer ${authSession.accessToken}"},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _participants = data.map((p) => Participant.fromJson(p)).toList();
        });
      }
    } catch (e) {
      debugPrint('Error loading participants: $e');
    }
  }

  Future<void> _loadMyParticipants() async {
    try {
      setState(() {
        _loadingMyParticipants = true;
      });

      final result = await ApiService.getMyParticipants(widget.sessionId);

      if (mounted) {
        setState(() {
          _myParticipants = List<Map<String, dynamic>>.from(
            result['participants'] ?? [],
          );
          _loadingMyParticipants = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading my participants: $e');
      if (mounted) {
        setState(() {
          _loadingMyParticipants = false;
        });
      }
    }
  }

  Future<void> _loadSessionData() async {
    try {
      final authSession = Supabase.instance.client.auth.currentSession;
      if (authSession == null) {
        throw Exception("No active session");
      }

      final serverUrl = dotenv.env["SERVER_URL"];
      _currentUserId = authSession.user.id;

      // Load session details
      final sessionResponse = await http.get(
        Uri.parse("$serverUrl/api/session/${widget.sessionId}"),
        headers: {"Authorization": "Bearer ${authSession.accessToken}"},
      );

      if (sessionResponse.statusCode != 200) {
        throw Exception("Failed to load session data");
      }

      final sessionData = jsonDecode(sessionResponse.body);
      final quizId = sessionData["snapshot"]?["quizId"];

      // Check if current user is host
      _isHost = sessionData["hostId"] == _currentUserId;

      // Load quiz details
      if (quizId != null) {
        final quizResponse = await ApiService.getQuiz(quizId);
        if (quizResponse != null) {
          setState(() {
            _quizData = quizResponse;
          });
        }
      }

      setState(() {
        _sessionData = sessionData;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _continueSession() async {
    if (_quizData == null) return;

    try {
      final authSession = Supabase.instance.client.auth.currentSession;
      if (authSession == null) return;

      final serverUrl = dotenv.env["SERVER_URL"];
      final isLive = _sessionData?["isLive"] ?? false;

      // HOST AUTO-START: If host clicks Play and session isn't live, start it first
      if (_isHost && !isLive) {
        debugPrint('[SessionDetail] Host starting session...');
        final startResp = await http.post(
          Uri.parse("$serverUrl/api/session/${widget.sessionId}/start"),
          headers: {"Authorization": "Bearer ${authSession.accessToken}"},
        );
        if (startResp.statusCode != 200) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Failed to start session: ${startResp.body}"),
            ),
          );
          return;
        }
        if (mounted) {
          setState(() {
            _sessionData = {
              ...?_sessionData,
              "isLive": true,
              "startedAt": DateTime.now().toIso8601String(),
            };
          });
        }
        debugPrint('[SessionDetail] Session started successfully');
      }

      final lastParticipant = _myParticipants.isNotEmpty
          ? _myParticipants.last
          : null;
      final isPlayAgain =
          lastParticipant != null && (lastParticipant['isCompleted'] ?? true);
      final needsInitialJoin = _myParticipants.isEmpty;

      debugPrint('[SessionDetail] _continueSession called');
      debugPrint(
        '[SessionDetail] _myParticipants.length: ${_myParticipants.length}',
      );
      debugPrint('[SessionDetail] lastParticipant: $lastParticipant');
      debugPrint('[SessionDetail] isPlayAgain: $isPlayAgain');
      debugPrint('[SessionDetail] needsInitialJoin: $needsInitialJoin');

      // Join session if: "Play Again" (new attempt) OR first time playing (no participants yet)
      if (isPlayAgain || needsInitialJoin) {
        debugPrint(
          '[SessionDetail] ${needsInitialJoin ? "Initial join" : "Play Again"} - creating new participant...',
        );

        final response = await http.post(
          Uri.parse("$serverUrl/api/session/${widget.sessionId}/join"),
          headers: {
            "Authorization": "Bearer ${authSession.accessToken}",
            "Content-Type": "application/json",
          },
        );

        debugPrint(
          '[SessionDetail] Join response status: ${response.statusCode}',
        );
        debugPrint('[SessionDetail] Join response body: ${response.body}');

        if (response.statusCode != 201 && response.statusCode != 200) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Failed to join session: ${response.body}")),
          );
          return;
        }

        // Reload participants to get the new one
        debugPrint('[SessionDetail] Reloading participants after join...');
        await _loadMyParticipants();
        debugPrint(
          '[SessionDetail] After reload, _myParticipants.length: ${_myParticipants.length}',
        );
      } else {
        debugPrint(
          '[SessionDetail] Continuing with existing participant (incomplete attempt)',
        );
      }

      // Navigate to play page
      if (!mounted) return;
      context.go('/session/${widget.sessionId}/play');
    } catch (e) {
      debugPrint('Error in _continueSession: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Failed to start game")));
      }
    }
  }

  void _copySessionCode() {
    final code = _sessionData?["code"];
    if (code != null) {
      Clipboard.setData(ClipboardData(text: code));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Session code copied to clipboard!"),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _showQrModal() {
    final code = _sessionData?["code"];
    final title = _sessionData?["title"];

    if (code == null) return;

    showDialog(
      context: context,
      builder: (context) =>
          SessionQrModal(sessionCode: code, sessionTitle: title),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go("/home");
            }
          },
        ),
        title: Text(
          "Session Details",
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: theme.colorScheme.surface,
        actions: [
          if (_isHost && !_isLoading)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () async {
                final result = await context.push(
                  '/quiz/session/edit/${widget.sessionId}',
                );
                if (result == true && mounted) {
                  _loadSessionData();
                }
              },
            ),
        ],
      ),
      backgroundColor: theme.colorScheme.surface,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? _buildErrorView()
          : Column(
              children: [
                // Session and Quiz Info Cards (outside tabs)
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildSessionInfoCard(theme),
                      const SizedBox(height: 16),
                      _buildQuizInfoCard(theme),
                    ],
                  ),
                ),

                // Tabs
                TabBar(
                  controller: _tabController,
                  labelColor: theme.colorScheme.primary,
                  unselectedLabelColor: theme.colorScheme.onSurface.withValues(
                    alpha: 0.6,
                  ),
                  indicatorColor: theme.colorScheme.primary,
                  tabs: const [
                    Tab(text: "All Participants"),
                    Tab(text: "My Games"),
                  ],
                ),

                // Tab Content
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildAllParticipantsTab(theme),
                      _buildMyGamesTab(theme),
                    ],
                  ),
                ),

                // Action buttons (always visible at bottom)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    border: Border(
                      top: BorderSide(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.1,
                        ),
                      ),
                    ),
                  ),
                  child: _buildActions(theme),
                ),
              ],
            ),
    );
  }

  Widget _buildSessionInfoCard(ThemeData theme) {
    final sessionTitle = _sessionData?["title"] ?? "Untitled Session";
    final sessionDescription = _sessionData?["description"];
    final isLive = _sessionData?["isLive"] ?? false;
    // Use database participantCount (total completed plays), not WebSocket connection count
    final participantCount = _sessionData?["participantCount"] ?? 0;
    final maxParticipants = _sessionData?["maxParticipants"] ?? 1;
    final isPublic = _sessionData?["isPublic"] ?? false;
    final code = _sessionData?["code"];

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    sessionTitle,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (isLive)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      "LIVE",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            if (sessionDescription != null) ...[
              const SizedBox(height: 8),
              Text(
                sessionDescription,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  isPublic ? Icons.public : Icons.lock,
                  size: 16,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                const SizedBox(width: 8),
                Text(
                  isPublic ? "Public Session" : "Private Session",
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(width: 24),
                Icon(
                  Icons.people,
                  size: 16,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                const SizedBox(width: 8),
                Text(
                  "$participantCount / $maxParticipants plays",
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
            if (code != null && maxParticipants > 1) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Code: ", style: theme.textTheme.bodyMedium),
                    Text(
                      code,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.copy, size: 18),
                      onPressed: _copySessionCode,
                      tooltip: "Copy Code",
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.qr_code, size: 18),
                      onPressed: _showQrModal,
                      tooltip: "Show QR Code",
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildQuizInfoCard(ThemeData theme) {
    if (_quizData == null) {
      return const SizedBox.shrink();
    }

    final quizTitle = _quizData!["title"] ?? "Unknown Quiz";
    final questionCount = _quizData!["questionCount"] ?? 0;
    final category = _quizData!["category"]?["name"];

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Quiz Information",
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.quiz, color: theme.colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(quizTitle, style: theme.textTheme.bodyLarge),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.help_outline,
                  size: 16,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                const SizedBox(width: 8),
                Text(
                  "$questionCount questions",
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                if (category != null) ...[
                  const SizedBox(width: 16),
                  Icon(
                    Icons.category,
                    size: 16,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    category,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAllParticipantsTab(ThemeData theme) {
    if (_participants.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            "No participants yet",
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _participants.length,
      itemBuilder: (context, index) {
        final participant = _participants[index];
        return _buildParticipantCard(participant, theme);
      },
    );
  }

  Widget _buildMyGamesTab(ThemeData theme) {
    return _loadingMyParticipants
        ? const Center(child: CircularProgressIndicator())
        : _myParticipants.isEmpty
        ? Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text(
                "You haven't joined this session yet",
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ),
          )
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _myParticipants.length,
            itemBuilder: (context, index) {
              final participant = _myParticipants[index];
              return _buildMyParticipantCard(
                participant,
                participant['attemptNumber'] ?? (index + 1),
                theme,
              );
            },
          );
  }

  Widget _buildMyParticipantCard(
    Map<String, dynamic> participant,
    int attemptNumber,
    ThemeData theme,
  ) {
    final score = participant['score'] ?? 0;
    final answeredQuestions = participant['answeredQuestions'] ?? 0;
    final totalQuestions = participant['totalQuestions'] ?? 0;
    final isCompleted = participant['isCompleted'] ?? false;
    final joinedAt = DateTime.parse(
      participant['joinedAt'] ?? DateTime.now().toIso8601String(),
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      '#$attemptNumber',
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Attempt #$attemptNumber',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Started ${_formatDateTime(joinedAt)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.6,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? Colors.green.withValues(alpha: 0.2)
                        : Colors.orange.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isCompleted ? 'Completed' : 'In Progress',
                    style: TextStyle(
                      color: isCompleted ? Colors.green : Colors.orange,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(
                        Icons.emoji_events,
                        size: 20,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text('Score: $score', style: theme.textTheme.bodyMedium),
                    ],
                  ),
                ),
                Expanded(
                  child: Row(
                    children: [
                      Icon(
                        Icons.quiz,
                        size: 20,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$answeredQuestions/$totalQuestions',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: totalQuestions > 0
                  ? answeredQuestions / totalQuestions
                  : 0,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              color: theme.colorScheme.primary,
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  Widget _buildActions(ThemeData theme) {
    final isLive = _sessionData?["isLive"] ?? false;

    // UNIFIED CONTROLS - Play/Continue/Play Again for both hosts and participants
    final lastParticipant = _myParticipants.isNotEmpty
        ? _myParticipants.last
        : null;
    final hasIncompleteGame =
        lastParticipant != null && !(lastParticipant['isCompleted'] ?? true);

    // Determine button state
    String buttonText;
    bool buttonEnabled;
    IconData buttonIcon;

    if (!isLive) {
      if (_isHost) {
        // Host override: allow Play to start the session
        buttonText = "Play";
        buttonEnabled = true;
        buttonIcon = Icons.play_arrow;
      } else {
        buttonText = "Waiting...";
        buttonEnabled = false;
        buttonIcon = Icons.hourglass_empty;
      }
    } else if (lastParticipant == null) {
      // Never played
      buttonText = "Play";
      buttonEnabled = true;
      buttonIcon = Icons.play_arrow;
    } else if (lastParticipant['isCompleted'] ?? true) {
      // Last game completed
      buttonText = "Play Again";
      buttonEnabled = true;
      buttonIcon = Icons.replay;
    } else {
      // Last game incomplete
      buttonText = "Continue Playing";
      buttonEnabled = true;
      buttonIcon = Icons.play_arrow;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Main action button
        ElevatedButton.icon(
          onPressed: buttonEnabled ? _continueSession : null,
          icon: Icon(buttonIcon),
          label: Text(
            buttonText,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: buttonEnabled
                ? Colors.green
                : theme.colorScheme.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),

        // New Game button (only show if there's an incomplete game)
        if (hasIncompleteGame && isLive) ...[
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _startNewGame,
            icon: const Icon(Icons.add_circle_outline),
            label: const Text(
              "New Game",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: BorderSide(color: theme.colorScheme.primary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],

        // End Session button (only for hosts)
        if (_isHost) ...[
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _endSession,
            icon: const Icon(Icons.stop),
            label: const Text("End Session"),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _endSession() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("End Session?"),
        content: const Text(
          "This will end the session for all participants. This action cannot be undone.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("End Session"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final authSession = Supabase.instance.client.auth.currentSession;
        if (authSession == null) return;

        final serverUrl = dotenv.env["SERVER_URL"];
        await http.post(
          Uri.parse("$serverUrl/api/session/${widget.sessionId}/end"),
          headers: {"Authorization": "Bearer ${authSession.accessToken}"},
        );

        if (mounted) {
          context.go("/library?category=game&tab=mine");
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Error: ${e.toString()}"),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _startNewGame() async {
    try {
      // Join session again (creates new participant)
      final authSession = Supabase.instance.client.auth.currentSession;
      if (authSession == null) return;

      final serverUrl = dotenv.env["SERVER_URL"];
      final response = await http.post(
        Uri.parse("$serverUrl/api/session/${widget.sessionId}/join"),
        headers: {
          "Authorization": "Bearer ${authSession.accessToken}",
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 201) {
        // Reload my participants
        await _loadMyParticipants();

        // Navigate to play screen
        if (_quizData != null && mounted) {
          context.go('/session/${widget.sessionId}/play');
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Failed to start new game: ${response.body}"),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error starting new game: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to start new game")),
        );
      }
    }
  }

  Widget _buildParticipantsList(ThemeData theme) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.people, color: theme.colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  "Participants (${_participants.length})",
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _participants.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final participant = _participants[index];
                return _buildParticipantCard(participant, theme);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParticipantCard(Participant participant, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundImage: participant.profilePictureUrl != null
                ? NetworkImage(participant.profilePictureUrl!)
                : null,
            child: participant.profilePictureUrl == null
                ? Text(
                    participant.username.isNotEmpty
                        ? participant.username[0].toUpperCase()
                        : "?",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  participant.fullName ?? participant.username,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (participant.fullName != null)
                  Text(
                    "@${participant.username}",
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
              ],
            ),
          ),
          if (participant.userId == _currentUserId)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                "You",
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 24),
            Text(
              "Error Loading Session",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _errorMessage ?? "Unknown error occurred",
              style: TextStyle(fontSize: 16, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.pop(),
              child: const Text("Go Back"),
            ),
          ],
        ),
      ),
    );
  }
}
