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
import "../quiz/widgets/session_qr_modal.dart";

/// Host Control Panel - For managing live multiplayer sessions
/// Host can see participants and control the session flow
class HostControlPanelPage extends StatefulWidget {
  final String sessionId;

  const HostControlPanelPage({super.key, required this.sessionId});

  @override
  State<HostControlPanelPage> createState() => _HostControlPanelPageState();
}

class _HostControlPanelPageState extends State<HostControlPanelPage> {
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _sessionData;
  Map<String, dynamic>? _quizData;
  List<dynamic> _participants = [];

  // WebSocket state
  StreamSubscription<List<Participant>>? _participantsSubscription;
  final _wsService = WebSocketService();

  @override
  void initState() {
    super.initState();
    _loadData();
    _setupWebSocket();
  }

  @override
  void dispose() {
    // Cancel subscription immediately before disposing
    _participantsSubscription?.cancel();
    _participantsSubscription = null;
    super.dispose();
  }

  Future<void> _setupWebSocket() async {
    try {
      // Connect to WebSocket
      await _wsService.connect();

      // Join session for real-time updates
      await _wsService.joinSession(widget.sessionId);

      // Listen to participants stream for real-time updates
      _participantsSubscription = _wsService.participants.listen(
        (participants) {
          debugPrint(
            '[HostControlPanel] Participants stream update received: ${participants.length} participants',
          );
          if (mounted) {
            setState(() {
              _participants = participants
                  .map(
                    (p) => {
                      "userId": p.userId,
                      "user": {
                        "fullName": p.fullName,
                        "username": p.username,
                        "profilePictureUrl": p.profilePictureUrl,
                      },
                    },
                  )
                  .toList();
              debugPrint(
                '[HostControlPanel] UI updated with ${_participants.length} participants',
              );
            });
          }
        },
        onError: (error) {
          debugPrint('WebSocket participants stream error: $error');
        },
        cancelOnError: false,
      );
    } catch (e) {
      debugPrint('Error setting up WebSocket: $e');
    }
  }

  Future<void> _loadData() async {
    try {
      final authSession = Supabase.instance.client.auth.currentSession;
      if (authSession == null) {
        throw Exception("No active session");
      }

      final serverUrl = dotenv.env["SERVER_URL"];

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

      // Load quiz details
      Map<String, dynamic>? quizData;
      if (quizId != null) {
        quizData = await ApiService.getQuiz(quizId);
      }

      // Load participants
      final participantsResponse = await http.get(
        Uri.parse("$serverUrl/api/session/${widget.sessionId}/participants"),
        headers: {"Authorization": "Bearer ${authSession.accessToken}"},
      );

      List<dynamic> participants = [];
      if (participantsResponse.statusCode == 200) {
        participants = jsonDecode(participantsResponse.body) as List;
      }

      if (mounted) {
        setState(() {
          _sessionData = sessionData;
          _quizData = quizData;
          // Only set participants if WebSocket hasn't provided any yet
          // This prevents HTTP response from overwriting WebSocket updates
          if (_participants.isEmpty) {
            _participants = participants;
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
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

  Future<void> _startQuiz() async {
    if (_quizData != null) {
      // Navigate all participants to play quiz
      final quizId = _quizData!["id"];
      context.push('/quiz/$quizId/play?sessionId=${widget.sessionId}');
    }
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
          context.go("/home");
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Host Control Panel",
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: theme.colorScheme.surface,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            // Navigate to Library > Game tab > Mine section
            context.go("/library?category=game&tab=mine");
          },
        ),
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
                  const SizedBox(height: 16),
                  _buildParticipantsCard(theme),
                  const SizedBox(height: 24),
                  _buildControls(theme),
                ],
              ),
            ),
    );
  }

  Widget _buildSessionInfoCard(ThemeData theme) {
    final sessionTitle = _sessionData?["title"] ?? "Untitled Session";
    final code = _sessionData?["code"];
    final isPublic = _sessionData?["isPublic"] ?? false;
    final maxParticipants = _sessionData?["maxParticipants"] ?? 1;
    final participantCount =
        _sessionData?["participantCount"] ?? 0; // Total plays

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
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: code));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Session code copied!"),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
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
              "Quiz",
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

  Widget _buildParticipantsCard(ThemeData theme) {
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
                Text(
                  "Participants",
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    "${_participants.length}",
                    style: TextStyle(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_participants.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Icon(
                        Icons.people_outline,
                        size: 48,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.3,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "No participants yet",
                        style: TextStyle(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.6,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _participants.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final participant = _participants[index];
                  final user = participant["user"];
                  final fullName = user?["fullName"] ?? "Unknown";
                  final username = user?["username"] ?? "unknown";
                  final profileUrl = user?["profilePictureUrl"];

                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    leading: CircleAvatar(
                      radius: 24,
                      backgroundColor: theme.colorScheme.primary,
                      backgroundImage: profileUrl != null
                          ? NetworkImage(profileUrl)
                          : null,
                      child: profileUrl == null
                          ? const Icon(
                              Icons.person,
                              color: Colors.white,
                              size: 28,
                            )
                          : null,
                    ),
                    title: Text(
                      fullName,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text("@$username"),
                    trailing: Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 20,
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildControls(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton.icon(
          onPressed: _startQuiz,
          icon: const Icon(Icons.play_arrow),
          label: const Text(
            "Start Quiz",
            style: TextStyle(fontWeight: FontWeight.bold),
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
