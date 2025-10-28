import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:go_router/go_router.dart";
import "package:supabase_flutter/supabase_flutter.dart";
import "dart:convert";
import "package:http/http.dart" as http;
import "package:flutter_dotenv/flutter_dotenv.dart";
import "package:intl/intl.dart";
import "package:qr_flutter/qr_flutter.dart";
import "../../services/api_service.dart";

class SessionDetailPage extends StatefulWidget {
  final String sessionId;

  const SessionDetailPage({super.key, required this.sessionId});

  @override
  State<SessionDetailPage> createState() => _SessionDetailPageState();
}

class _SessionDetailPageState extends State<SessionDetailPage> {
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _sessionData;
  Map<String, dynamic>? _quizData;
  List<dynamic> _userParticipants = [];

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
      final userId = authSession.user.id;

      // Load session details
      final sessionResponse = await http.get(
        Uri.parse("$serverUrl/api/session/${widget.sessionId}"),
        headers: {"Authorization": "Bearer ${authSession.accessToken}"},
      );

      if (sessionResponse.statusCode != 200) {
        throw Exception("Failed to load session data");
      }

      final sessionData = jsonDecode(sessionResponse.body);
      print('🔍 DEBUG Raw Session Data: $sessionData');
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

      // Load user's participants for this quiz
      final participantsResponse = await http.get(
        Uri.parse("$serverUrl/api/session/user/$userId/played"),
        headers: {"Authorization": "Bearer ${authSession.accessToken}"},
      );

      if (participantsResponse.statusCode == 200) {
        final allParticipants = jsonDecode(participantsResponse.body) as List;

        // Filter participants for this specific quiz
        final quizParticipants = allParticipants.where((p) {
          final participantQuiz = p["snapshot"]?["quizId"];
          return participantQuiz == quizId;
        }).toList();

        setState(() {
          _sessionData = sessionData;
          _userParticipants = quizParticipants;
          _isLoading = false;
        });
      } else {
        throw Exception("Failed to load participants data");
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _startNewSession() {
    if (_quizData != null) {
      // Navigate to play quiz page with current session
      final quizId = _quizData!["id"];
      context.push('/quiz/$quizId/play?sessionId=${widget.sessionId}');
    }
  }

  Future<void> _shareSession() async {
    final isPublic = _sessionData?["isPublic"] ?? false;

    // If session is private, prompt to make it public
    if (!isPublic) {
      final shouldMakePublic = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Switch To Public Mode?"),
          content: const Text(
            "This session is currently private. Would you like to make it public so others can join using the code or QR?",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text("Keep Private"),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text("Make Public"),
            ),
          ],
        ),
      );

      if (shouldMakePublic == true) {
        await _updateSessionVisibility(true);
      } else {
        return; // User chose to keep it private
      }
    }

    // Show share options
    _showShareOptions();
  }

  Future<void> _updateSessionVisibility(bool isPublic) async {
    try {
      final authSession = Supabase.instance.client.auth.currentSession;
      if (authSession == null) return;

      final serverUrl = dotenv.env["SERVER_URL"];
      final response = await http.put(
        Uri.parse("$serverUrl/api/session/${widget.sessionId}"),
        headers: {
          "Authorization": "Bearer ${authSession.accessToken}",
          "Content-Type": "application/json",
        },
        body: jsonEncode({"isPublic": isPublic}),
      );

      if (response.statusCode == 200) {
        setState(() {
          _sessionData?["isPublic"] = isPublic;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isPublic ? "Session is now public" : "Session is now private",
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error updating session: ${e.toString()}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showShareOptions() {
    final code = _sessionData?["code"];
    if (code == null) return;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Share Session",
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),

            // QR Code
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: QrImageView(
                data: code,
                version: QrVersions.auto,
                size: 200.0,
              ),
            ),
            const SizedBox(height: 24),

            // Session Code
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    code,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 4,
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    icon: const Icon(Icons.copy),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: code));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Code copied to clipboard"),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "Share this code or QR with others to join",
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _continueParticipant(Map<String, dynamic> participant) {
    final sessionId = participant["id"];
    context.push('/quiz/session/detail/$sessionId');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    final isHost =
        _sessionData != null && _sessionData!["hostId"] == currentUserId;

    // Debug log
    if (_sessionData != null) {
      print('🔍 DEBUG Session Detail:');
      print('  Current User ID: $currentUserId');
      print('  Session Host ID: ${_sessionData!["hostId"]}');
      print('  Is Host: $isHost');
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Session Details",
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        actions: [
          // Debug info badge
          if (_sessionData != null)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isHost ? Colors.green : Colors.orange,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                isHost ? 'HOST' : 'GUEST',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          if (!_isLoading && isHost)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () async {
                final result = await context.push(
                  '/quiz/session/edit/${widget.sessionId}',
                );
                if (result == true && mounted) {
                  _loadSessionData(); // Reload data after edit
                }
              },
              tooltip: "Edit Session",
            ),
          const SizedBox(width: 8),
        ],
      ),
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? _buildErrorView()
          : RefreshIndicator(
              onRefresh: _loadSessionData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Quiz Information Card
                    if (_quizData != null) _buildQuizInfoCard(theme),
                    const SizedBox(height: 24),

                    // Session Information Card
                    if (_sessionData != null) _buildSessionInfoCard(theme),
                    const SizedBox(height: 24),

                    // Action Buttons
                    _buildActionButtons(theme),
                    const SizedBox(height: 24),

                    // Previous Participants
                    if (_userParticipants.isNotEmpty) ...[
                      Text(
                        "Your Previous Sessions",
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ..._userParticipants.map(
                        (participant) =>
                            _buildParticipantCard(participant, theme),
                      ),
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildQuizInfoCard(ThemeData theme) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Quiz Header with Image
            Row(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    image: DecorationImage(
                      image: NetworkImage(_quizData!["imageUrl"] ?? ""),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _quizData!["title"],
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _quizData!["description"] ?? "No description",
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.7,
                          ),
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Quiz Stats - Simplified
            Row(
              children: [
                _buildStatItem(
                  Icons.quiz_outlined,
                  "${_quizData!["questionCount"] ?? 0}",
                  "Questions",
                ),
                const SizedBox(width: 12),
                _buildStatItem(
                  Icons.play_arrow_outlined,
                  "${_quizData!["playCount"] ?? 0}",
                  "Plays",
                ),
                const SizedBox(width: 12),
                _buildStatItem(
                  Icons.favorite_outline,
                  "${_quizData!["favoriteCount"] ?? 0}",
                  "Favorites",
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    final theme = Theme.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(
            alpha: 0.3,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              size: 22,
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionInfoCard(ThemeData theme) {
    final createdAt = DateTime.parse(_sessionData!["createdAt"]);
    final formattedDate = DateFormat('MMM dd, yyyy').format(createdAt);

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
                Icon(Icons.info_outline, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  "Session Information",
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_sessionData!["description"] != null &&
                _sessionData!["description"].toString().isNotEmpty) ...[
              Text(
                _sessionData!["description"],
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                ),
              ),
              const SizedBox(height: 12),
            ],
            _buildInfoRow("Created", formattedDate),
            if (_sessionData!["code"] != null)
              _buildInfoRow("Session Code", _sessionData!["code"]),
            _buildInfoRow("Status", _sessionData!["isLive"] ? "Live" : "Ended"),
            _buildInfoRow(
              "Visibility",
              _sessionData!["isPublic"] == true ? "Public" : "Private",
            ),
            if (_sessionData!["joinedCount"] != null)
              _buildInfoRow("Participants", "${_sessionData!["joinedCount"]}"),
            if (_sessionData!["maxPlayers"] != null)
              _buildInfoRow("Max Players", "${_sessionData!["maxPlayers"]}"),
            if (_sessionData!["hasEndTime"] == true &&
                _sessionData!["endTime"] != null)
              _buildInfoRow(
                "Ends At",
                DateFormat(
                  'MMM dd, yyyy • HH:mm',
                ).format(DateTime.parse(_sessionData!["endTime"])),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              "$label:",
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(ThemeData theme) {
    return Column(
      children: [
        // Play Alone Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _startNewSession,
            icon: const Icon(Icons.play_arrow),
            label: const Text("Play Alone"),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Share Button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _shareSession,
            icon: const Icon(Icons.share),
            label: const Text("Share Code / QR"),
            style: OutlinedButton.styleFrom(
              foregroundColor: theme.colorScheme.primary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: BorderSide(color: theme.colorScheme.primary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildParticipantCard(
    Map<String, dynamic> participant,
    ThemeData theme,
  ) {
    final participantData = participant["participant"] as Map<String, dynamic>?;
    final joinedAt = DateTime.parse(participantData!["joinedAt"]);
    final formattedDate = DateFormat('MMM dd, yyyy • HH:mm').format(joinedAt);

    // Calculate progress (simplified - would need total questions for real progress)
    final score = participantData["score"] ?? 0;
    final rank = participantData["rank"];
    final progress = 0; // Placeholder - would calculate from answered questions

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _continueParticipant(participant),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Session from $formattedDate",
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  if (rank != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.amber,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '#$rank',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Score",
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.7,
                            ),
                          ),
                        ),
                        Text(
                          "$score points",
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Stack(
                      children: [
                        Center(
                          child: Text(
                            "$progress%",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                        CircularProgressIndicator(
                          value: progress / 100,
                          backgroundColor: theme.colorScheme.primary.withValues(
                            alpha: 0.1,
                          ),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            theme.colorScheme.primary,
                          ),
                          strokeWidth: 3,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _continueParticipant(participant),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text("Continue This Session"),
                ),
              ),
            ],
          ),
        ),
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
