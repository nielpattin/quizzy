import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "package:supabase_flutter/supabase_flutter.dart";
import "dart:convert";
import "package:http/http.dart" as http;
import "package:flutter_dotenv/flutter_dotenv.dart";
import "../../services/api_service.dart";

class QuizDetailPage extends StatefulWidget {
  final String quizId;
  const QuizDetailPage({super.key, required this.quizId});

  @override
  State<QuizDetailPage> createState() => _QuizDetailPageState();
}

class _QuizDetailPageState extends State<QuizDetailPage> {
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _quizData;
  List<dynamic>? _questions;
  bool isFollowing = false;
  bool isFavorited = false;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadQuizData();
    _checkFollowStatus();
    _checkFavoriteStatus();
  }

  Future<void> _loadQuizData() async {
    try {
      final session = Supabase.instance.client.auth.currentSession;
      _currentUserId = session?.user.id;
      final serverUrl = dotenv.env["SERVER_URL"] ?? "http://localhost:8000";

      final quizResponse = await http.get(
        Uri.parse("$serverUrl/api/quiz/${widget.quizId}"),
        headers: {
          if (session != null) "Authorization": "Bearer ${session.accessToken}",
        },
      );

      if (quizResponse.statusCode != 200) {
        throw Exception("Failed to load quiz");
      }

      final quiz = jsonDecode(quizResponse.body) as Map<String, dynamic>;

      List<dynamic>? questions;
      if (quiz["questionsVisible"] == true) {
        final questionsResponse = await http.get(
          Uri.parse("$serverUrl/api/quiz/${widget.quizId}/questions"),
          headers: {
            if (session != null)
              "Authorization": "Bearer ${session.accessToken}",
          },
        );

        if (questionsResponse.statusCode == 200) {
          questions = jsonDecode(questionsResponse.body) as List;
        }
      }

      setState(() {
        _quizData = quiz;
        _questions = questions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _checkFollowStatus() async {
    if (_isOwner) return;

    try {
      final creatorUserId = _quizData?["user"]?["id"];
      if (creatorUserId != null) {
        final following = await ApiService.isFollowing(creatorUserId);
        setState(() => isFollowing = following);
      }
    } catch (e) {
      // Silently ignore follow status check errors
    }
  }

  Future<void> _checkFavoriteStatus() async {
    try {
      final favorited = await ApiService.isFavorited(widget.quizId);
      setState(() => isFavorited = favorited);
    } catch (e) {
      // Silently ignore favorite status check errors
    }
  }

  Future<void> _toggleFollow() async {
    final creatorUserId = _quizData?["user"]?["id"];
    if (creatorUserId == null) return;

    try {
      if (isFollowing) {
        await ApiService.unfollowUser(creatorUserId);
      } else {
        await ApiService.followUser(creatorUserId);
      }
      setState(() => isFollowing = !isFollowing);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: ${e.toString()}")));
      }
    }
  }

  Future<void> _toggleFavorite() async {
    try {
      if (isFavorited) {
        await ApiService.unfavoriteQuiz(widget.quizId);
      } else {
        await ApiService.favoriteQuiz(widget.quizId);
      }
      setState(() {
        isFavorited = !isFavorited;
        if (_quizData != null) {
          _quizData!["favoriteCount"] =
              (_quizData!["favoriteCount"] ?? 0) + (isFavorited ? 1 : -1);
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: ${e.toString()}")));
      }
    }
  }

  Future<void> _createGame() async {
    try {
      final session = await ApiService.createSession(
        widget.quizId,
        title: _quizData!["title"],
        estimatedMinutes: (_quizData!["questionCount"] as int) * 2,
      );

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Game Created!"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("Session Code:", style: TextStyle(fontSize: 16)),
                const SizedBox(height: 8),
                Text(
                  session["code"],
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 4,
                  ),
                ),
                const SizedBox(height: 16),
                const Text("Players can join using this code in the Join tab."),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => context.pop(),
                child: const Text("OK"),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error creating game: ${e.toString()}")),
        );
      }
    }
  }

  Future<void> _deleteQuiz() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Quiz?"),
        content: const Text("This action cannot be undone."),
        actions: [
          TextButton(
            onPressed: () => context.pop(false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => context.pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ApiService.deleteQuiz(widget.quizId);
        if (mounted) {
          context.pop();
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text("Quiz deleted")));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("Error: ${e.toString()}")));
        }
      }
    }
  }

  bool get _isOwner =>
      _currentUserId != null && _quizData?["user"]?["id"] == _currentUserId;

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(
              isFavorited ? Icons.favorite : Icons.favorite_border,
              color: isFavorited ? Colors.red : Colors.white,
            ),
            onPressed: _toggleFavorite,
          ),
          if (_isOwner)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.white),
              onPressed: _deleteQuiz,
            ),
          if (!_isOwner)
            IconButton(
              icon: const Icon(Icons.more_vert, color: Colors.white),
              onPressed: _showReportModal,
            ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _quizData!["description"] ?? "No description provided",
                    style: TextStyle(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.7),
                      fontSize: 16,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            _buildStats(),
            _buildCreatorInfo(),
            if (_isOwner) _buildEditButton(),
            if (!_isOwner) _buildActionButtons(),
            if (_questions != null && _questions!.isNotEmpty)
              _buildQuestionsList(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final gradientColors = [const Color(0xFF64A7FF), const Color(0xFF4A90E2)];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          height: 240,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                _quizData!["title"],
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStats() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatItem(
            icon: Icons.question_answer,
            label: "Questions",
            value: _quizData!["questionCount"].toString(),
          ),
          _StatItem(
            icon: Icons.play_circle_outline,
            label: "Played",
            value: _quizData!["playCount"].toString(),
          ),
          _StatItem(
            icon: Icons.favorite_border,
            label: "Favorites",
            value: _quizData!["favoriteCount"].toString(),
          ),
        ],
      ),
    );
  }

  Widget _buildCreatorInfo() {
    final user = _quizData!["user"];

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: Theme.of(context).colorScheme.primary,
            backgroundImage: user["profilePictureUrl"] != null
                ? NetworkImage(user["profilePictureUrl"])
                : null,
            child: user["profilePictureUrl"] == null
                ? const Icon(Icons.person, color: Colors.white, size: 28)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user["fullName"] ?? "Unknown",
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  "@${user["username"] ?? "unknown"}",
                  style: TextStyle(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.6),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          if (!_isOwner)
            OutlinedButton(
              onPressed: _toggleFollow,
              style: OutlinedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.surface,
                foregroundColor: isFollowing
                    ? Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.7)
                    : Theme.of(context).colorScheme.primary,
                side: BorderSide(
                  color: isFollowing
                      ? Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.3)
                      : Theme.of(context).colorScheme.primary,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: Text(isFollowing ? "Following" : "Follow"),
            ),
        ],
      ),
    );
  }

  Widget _buildEditButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ElevatedButton.icon(
            onPressed: () {
              context.push("/quiz/${widget.quizId}/add-questions");
            },
            icon: const Icon(Icons.edit),
            label: const Text(
              "Edit Quiz",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    context.push("/quiz/${widget.quizId}/play");
                  },
                  icon: const Icon(Icons.play_arrow),
                  label: const Text(
                    "Play Solo",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _createGame,
                  icon: const Icon(Icons.group),
                  label: const Text(
                    "Create Game",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionsList() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Questions",
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ..._questions!.asMap().entries.map((entry) {
            final index = entry.key;
            final question = entry.value;
            return Padding(
              padding: EdgeInsets.only(
                bottom: index < _questions!.length - 1 ? 12 : 0,
              ),
              child: _QuestionCard(
                question: question,
                index: index,
                showAnswer: _isOwner,
              ),
            );
          }),
        ],
      ),
    );
  }

  void _showReportModal() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              "Report Quiz",
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.flag),
              title: const Text("Inappropriate Content"),
              onTap: () {
                context.pop();
              },
            ),
            ListTile(
              leading: const Icon(Icons.error),
              title: const Text("Misleading Information"),
              onTap: () {
                context.pop();
              },
            ),
            ListTile(
              leading: const Icon(Icons.report),
              title: const Text("Spam"),
              onTap: () {
                context.pop();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 32, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.6),
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}

class _QuestionCard extends StatelessWidget {
  final Map<String, dynamic> question;
  final int index;
  final bool showAnswer;

  const _QuestionCard({
    required this.question,
    required this.index,
    required this.showAnswer,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final type = question["type"] as String;
    final data = question["data"] as Map<String, dynamic>;

    List<String> options = [];
    int? correctIndex;

    if (type == "multiple_choice" && data["options"] != null) {
      options = (data["options"] as List).cast<String>();
      correctIndex = data["correctIndex"] as int?;
    } else if (type == "true_false") {
      options = ["True", "False"];
      final correctAnswer = data["correctAnswer"] as bool?;
      correctIndex = correctAnswer == true ? 0 : 1;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    "${index + 1}",
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  question["questionText"],
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (options.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...options.asMap().entries.map((entry) {
              final optionIndex = entry.key;
              final option = entry.value;
              final isCorrect = showAnswer && optionIndex == correctIndex;

              return Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isCorrect
                        ? Colors.green.withValues(alpha: 0.1)
                        : isDark
                        ? Colors.grey[800]
                        : Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: isCorrect
                        ? Border.all(color: Colors.green, width: 2)
                        : null,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          option,
                          style: TextStyle(
                            color: isCorrect
                                ? Colors.green[700]
                                : theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                      if (isCorrect)
                        const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 20,
                        ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}
