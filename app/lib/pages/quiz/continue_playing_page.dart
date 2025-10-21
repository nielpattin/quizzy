import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "package:supabase_flutter/supabase_flutter.dart";
import "dart:convert";
import "package:http/http.dart" as http;
import "package:flutter_dotenv/flutter_dotenv.dart";
import "./widgets/connection_status_indicator.dart";
import "./widgets/session_status_indicator.dart";

class ContinuePlayingPage extends StatefulWidget {
  const ContinuePlayingPage({super.key});

  @override
  State<ContinuePlayingPage> createState() => _ContinuePlayingPageState();
}

class _ContinuePlayingPageState extends State<ContinuePlayingPage> {
  bool _isLoading = true;
  String? _errorMessage;
  List<dynamic> _liveSessions = [];
  List<dynamic> _mySessions = [];

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    try {
      final session = Supabase.instance.client.auth.currentSession;
      if (session == null) {
        throw Exception("No active session");
      }

      final serverUrl = dotenv.env["SERVER_URL"];
      final userId = session.user.id;

      // Load live sessions (sessions that are active and not ended)
      final liveSessionsResponse = await http.get(
        Uri.parse("$serverUrl/api/session/user/$userId/played"),
        headers: {"Authorization": "Bearer ${session.accessToken}"},
      );

      // Load hosted sessions
      final hostedSessionsResponse = await http.get(
        Uri.parse("$serverUrl/api/session/user/$userId/hosted"),
        headers: {"Authorization": "Bearer ${session.accessToken}"},
      );

      if (liveSessionsResponse.statusCode != 200 ||
          hostedSessionsResponse.statusCode != 200) {
        throw Exception("Failed to load sessions");
      }

      final liveSessions = jsonDecode(liveSessionsResponse.body) as List;
      final hostedSessions = jsonDecode(hostedSessionsResponse.body) as List;

      // Filter for active/live sessions
      final activeLiveSessions = liveSessions
          .where(
            (session) =>
                session['isLive'] == true && session['endedAt'] == null,
          )
          .toList();

      final activeHostedSessions = hostedSessions
          .where(
            (session) =>
                session['isLive'] == true && session['endedAt'] == null,
          )
          .toList();

      setState(() {
        _liveSessions = [...activeLiveSessions, ...activeHostedSessions];
        _mySessions = [...liveSessions, ...hostedSessions];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _joinSession(String sessionId) {
    context.push('/quiz/session/live/$sessionId');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Continue Playing",
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        actions: const [ConnectionStatusIndicator(), SizedBox(width: 16)],
      ),
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? _buildErrorView()
          : RefreshIndicator(
              onRefresh: _loadSessions,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Live Sessions Section
                    if (_liveSessions.isNotEmpty) ...[
                      _buildSectionHeader(
                        "Live Sessions",
                        Icons.live_tv,
                        Colors.red,
                      ),
                      const SizedBox(height: 12),
                      ..._liveSessions
                          .map((session) => _buildSessionCard(session, true))
                          .toList(),
                      const SizedBox(height: 24),
                    ],

                    // My Sessions Section
                    _buildSectionHeader(
                      "My Sessions",
                      Icons.history,
                      const Color(0xFF64A7FF),
                    ),
                    const SizedBox(height: 12),

                    if (_mySessions.isEmpty)
                      _buildEmptyState()
                    else
                      ..._mySessions
                          .map((session) => _buildSessionCard(session, false))
                          .toList(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
      ],
    );
  }

  Widget _buildSessionCard(Map<String, dynamic> session, bool isLive) {
    final theme = Theme.of(context);
    final isHost =
        session['hostId'] != null; // We'd need to compare with current user ID
    final participant = session['participant'];

    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isLive
            ? BorderSide(color: Colors.red, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: () => _joinSession(session['id']),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      session['title'],
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isLive) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'LIVE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  const SessionStatusIndicator(),
                ],
              ),
              const SizedBox(height: 12),

              // Session details
              Row(
                children: [
                  Icon(Icons.people, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '${session['joinedCount'] ?? 0} participants',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.schedule, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '${session['estimatedMinutes'] ?? 10} min',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),

              if (session['code'] != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.code, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      'Code: ${session['code']}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],

              if (participant != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.star, size: 16, color: const Color(0xFF64A7FF)),
                    const SizedBox(width: 4),
                    Text(
                      'Your Score: ${participant['score'] ?? 0}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF64A7FF),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (participant['rank'] != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.amber,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '#${participant['rank']}',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],

              const SizedBox(height: 12),

              // Action button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _joinSession(session['id']),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isLive
                        ? Colors.red
                        : const Color(0xFF64A7FF),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    isLive ? 'Join Live Session' : 'Continue Session',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.quiz_outlined, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 24),
            Text(
              "No Sessions Yet",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "Join a live session or create your own to get started!",
              style: TextStyle(fontSize: 16, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                // TODO: Navigate to session creation
              },
              icon: const Icon(Icons.add),
              label: const Text("Create Session"),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF64A7FF),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadSessions,
              child: const Text("Retry"),
            ),
          ],
        ),
      ),
    );
  }
}
