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

/// Session Lobby Page - For multiplayer sessions
/// Shows session details and participants
/// Note: Sessions now go live immediately after creation.
/// This page is used for viewing session details from Library.
/// State: maxParticipants>1
class SessionLobbyPage extends StatefulWidget {
  final String sessionId;

  const SessionLobbyPage({super.key, required this.sessionId});

  @override
  State<SessionLobbyPage> createState() => _SessionLobbyPageState();
}

class _SessionLobbyPageState extends State<SessionLobbyPage> {
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _sessionData;
  Map<String, dynamic>? _quizData;
  String? _currentUserId;
  bool _isHost = false;
  bool _isJoiningAsPlayer = false;

  // WebSocket state
  StreamSubscription<List<Participant>>? _participantsSubscription;
  List<Participant> _participants = [];
  final _wsService = WebSocketService();

  // Check if current user is a participant
  bool get _isParticipant {
    if (_currentUserId == null) return false;
    return _participants.any((p) => p.userId == _currentUserId);
  }

  @override
  void initState() {
    super.initState();
    _loadSessionData();
    _setupWebSocket();
  }

  @override
  void dispose() {
    _participantsSubscription?.cancel();
    super.dispose();
  }

  Future<void> _setupWebSocket() async {
    try {
      // Connect to WebSocket
      await _wsService.connect();

      // Join session for real-time updates
      await _wsService.joinSession(widget.sessionId);

      // Load initial participants
      await _loadParticipants();

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

      // Note: We don't auto-redirect if session is live because:
      // 1. User might intentionally navigate back from Host Control Panel
      // 2. Causes infinite redirect loop
      // 3. Instead, we show appropriate UI state for live sessions

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

      // Auto-redirect host to Session Detail if session is already live
      // This handles edge cases where host navigates to lobby for a live session
      if (_isHost && sessionData["isLive"] == true && mounted) {
        Future.microtask(() {
          if (mounted) {
            context.go('/quiz/session/detail/${widget.sessionId}');
          }
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _joinSession() async {
    // Participant joins the session
    if (_quizData != null) {
      context.go('/session/${widget.sessionId}/play');
    }
  }

  Future<void> _joinAsPlayer() async {
    try {
      setState(() => _isJoiningAsPlayer = true);

      final authSession = Supabase.instance.client.auth.currentSession;
      if (authSession == null) {
        throw Exception("No active session");
      }

      final serverUrl = dotenv.env["SERVER_URL"];

      // Call backend join endpoint to create participant record
      final response = await http.post(
        Uri.parse("$serverUrl/api/session/${widget.sessionId}/join"),
        headers: {
          "Authorization": "Bearer ${authSession.accessToken}",
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        final error = jsonDecode(response.body);
        throw Exception(error["error"] ?? "Failed to join as player");
      }

      // Reload participants to show the host in the list
      await _loadParticipants();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("You've joined as a player!"),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
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
    } finally {
      setState(() => _isJoiningAsPlayer = false);
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
            // Safe navigation - check if we can pop before attempting
            if (context.canPop()) {
              context.pop();
            } else {
              // No history to pop, navigate to home as fallback
              context.go('/');
            }
          },
          tooltip: "Back",
        ),
        title: Text(
          "Session Lobby",
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
              tooltip: "Edit Session",
            ),
        ],
      ),
      backgroundColor: theme.colorScheme.surface,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? _buildErrorView()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildSessionInfoCard(theme),
                  const SizedBox(height: 16),
                  _buildQuizInfoCard(theme),
                  const SizedBox(height: 24),
                  if (_isHost) _buildHostActions(theme),
                  if (!_isHost) _buildParticipantWaiting(theme),
                ],
              ),
            ),
    );
  }

  Widget _buildSessionInfoCard(ThemeData theme) {
    final sessionTitle = _sessionData?["title"] ?? "Untitled Session";
    final sessionDescription = _sessionData?["description"];
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
            Text(
              sessionTitle,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
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
            if (code != null) ...[
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

  Widget _buildHostActions(ThemeData theme) {
    final isLive = _sessionData?["isLive"] ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Participants list
        if (_participants.isNotEmpty) ...[
          _buildParticipantsList(theme),
          const SizedBox(height: 16),
        ],
        // Join as Player button (only show if host is not a participant)
        if (!_isParticipant) ...[
          OutlinedButton.icon(
            onPressed: _isJoiningAsPlayer ? null : _joinAsPlayer,
            icon: _isJoiningAsPlayer
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.person_add),
            label: Text(
              _isJoiningAsPlayer ? "Joining..." : "Join as Player",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: theme.colorScheme.primary,
              side: BorderSide(color: theme.colorScheme.primary, width: 2),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        // Go to Session Detail button (host controls are now integrated there)
        if (isLive)
          ElevatedButton.icon(
            onPressed: () =>
                context.push('/quiz/session/detail/${widget.sessionId}'),
            icon: const Icon(Icons.dashboard),
            label: const Text(
              "Go to Session Control",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
      ],
    );
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

  Widget _buildParticipantWaiting(ThemeData theme) {
    final isLive = _sessionData?["isLive"] ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: theme.colorScheme.secondaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Icon(
                isLive ? Icons.play_circle_filled : Icons.hourglass_empty,
                size: 64,
                color: theme.colorScheme.onSecondaryContainer,
              ),
              const SizedBox(height: 16),
              Text(
                isLive ? "Session is live!" : "Waiting for host to start...",
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSecondaryContainer,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                isLive
                    ? "Tap below to join the session"
                    : "The session will begin shortly",
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSecondaryContainer.withValues(
                    alpha: 0.7,
                  ),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Participants list
        if (_participants.isNotEmpty) ...[
          _buildParticipantsList(theme),
          const SizedBox(height: 16),
        ],
        ElevatedButton.icon(
          onPressed: isLive ? _joinSession : null,
          icon: const Icon(Icons.play_arrow),
          label: Text(
            isLive ? "Join Session" : "Waiting...",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: theme.colorScheme.onPrimary,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
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
