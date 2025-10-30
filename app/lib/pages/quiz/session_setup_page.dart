import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "package:supabase_flutter/supabase_flutter.dart";
import "dart:convert";
import "package:http/http.dart" as http;
import "package:flutter_dotenv/flutter_dotenv.dart";
import "../../services/api_service.dart";
import "widgets/multiplayer_setup_modal.dart";

/// Session Setup Page - For NEW solo sessions (just created from Quiz Detail)
/// Shows: "Play Alone" + "Convert to Multiplayer" options
/// State: maxParticipants=1, isLive=false, participantCount=1
class SessionSetupPage extends StatefulWidget {
  final String sessionId;

  const SessionSetupPage({super.key, required this.sessionId});

  @override
  State<SessionSetupPage> createState() => _SessionSetupPageState();
}

class _SessionSetupPageState extends State<SessionSetupPage> {
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _sessionData;
  Map<String, dynamic>? _quizData;

  @override
  void initState() {
    super.initState();
    _loadSessionData();
  }

  Future<void> _loadSessionData() async {
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

  Future<void> _playAlone() async {
    if (_quizData != null) {
      // Navigate to play quiz page immediately for solo play
      context.go('/session/${widget.sessionId}/play');
    }
  }

  Future<void> _showMultiplayerModal() async {
    final code = _sessionData?["code"];
    if (code == null) return;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => MultiplayerSetupModal(
        sessionId: widget.sessionId,
        sessionCode: code,
        onConfirm: _updateSessionForMultiplayer,
      ),
    );

    if (result == true && mounted) {
      // Navigate to Session Detail Page (host control features are now there)
      context.go('/quiz/session/detail/${widget.sessionId}');
    }
  }

  Future<void> _updateSessionForMultiplayer(
    bool isPublic,
    int maxParticipants,
  ) async {
    final authSession = Supabase.instance.client.auth.currentSession;
    if (authSession == null) {
      throw Exception("No active session");
    }

    final serverUrl = dotenv.env["SERVER_URL"];

    // Step 1: Update session settings
    final updateResponse = await http.put(
      Uri.parse("$serverUrl/api/session/${widget.sessionId}"),
      headers: {
        "Authorization": "Bearer ${authSession.accessToken}",
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "isPublic": isPublic,
        "maxParticipants": maxParticipants,
      }),
    );

    if (updateResponse.statusCode != 200) {
      throw Exception("Failed to update session");
    }

    // Step 2: Start the session immediately
    final startResponse = await http.post(
      Uri.parse("$serverUrl/api/session/${widget.sessionId}/start"),
      headers: {"Authorization": "Bearer ${authSession.accessToken}"},
    );

    if (startResponse.statusCode != 200) {
      throw Exception("Failed to start session");
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Setup Session",
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: theme.colorScheme.surface,
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
                  _buildQuizInfoCard(theme),
                  const SizedBox(height: 24),
                  _buildSessionModeSelection(theme),
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
    final imageUrl = _quizData!["imageUrl"] as String?;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (imageUrl != null)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
              child: Image.network(
                imageUrl,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  quizTitle,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
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
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.6,
                        ),
                      ),
                    ),
                    if (category != null) ...[
                      const SizedBox(width: 16),
                      Icon(
                        Icons.category,
                        size: 16,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.6,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        category,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.6,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionModeSelection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          "Choose How to Play",
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _ModeCard(
          icon: Icons.person,
          title: "Play Alone",
          description: "Start playing the quiz immediately by yourself",
          color: theme.colorScheme.primary,
          onTap: _playAlone,
        ),
        const SizedBox(height: 16),
        _ModeCard(
          icon: Icons.people,
          title: "Multiplayer",
          description: "Invite others to join and compete together",
          color: Colors.deepPurple,
          onTap: _showMultiplayerModal,
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

class _ModeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final VoidCallback onTap;

  const _ModeCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 32),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: color, size: 20),
          ],
        ),
      ),
    );
  }
}
