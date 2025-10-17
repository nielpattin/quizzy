import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "package:supabase_flutter/supabase_flutter.dart";
import "package:http/http.dart" as http;
import "package:flutter_dotenv/flutter_dotenv.dart";
import "dart:convert";
import "../../services/api_service.dart";

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  String? _username;
  String? _fullName;
  String? _avatarUrl;
  Map<String, dynamic>? _stats;
  Map<String, dynamic>? _bio;
  List<dynamic> _quizzes = [];
  List<dynamic> _sessions = [];
  List<dynamic> _posts = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadProfile();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh profile when dependencies change (e.g., navigation)
    _loadProfile();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    debugPrint('[PROFILE] Loading profile...');
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) {
      debugPrint('[PROFILE] No session found');
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      final token = session.accessToken;
      final serverUrl = dotenv.env["SERVER_URL"]!;
      final userId = session.user.id;
      debugPrint('[PROFILE] Fetching from: $serverUrl/api/user/profile');

      final results = await Future.wait([
        http.get(
          Uri.parse("$serverUrl/api/user/profile"),
          headers: {"Authorization": "Bearer $token"},
        ),
        ApiService.getUserQuizzes(userId),
        ApiService.getHostedSessions(userId),
        ApiService.getUserPosts(userId),
      ]);

      final profileResponse = results[0] as http.Response;

      debugPrint('[PROFILE] Response status: ${profileResponse.statusCode}');
      debugPrint('[PROFILE] Response body: ${profileResponse.body}');

      if (profileResponse.statusCode == 200) {
        final profileData = json.decode(profileResponse.body);
        final quizzes = results[1] as List<dynamic>;
        final sessions = results[2] as List<dynamic>;
        final posts = results[3] as List<dynamic>;

        final stats = {
          "quizzes": quizzes.length,
          "sessions": sessions.length,
          "posts": posts.length,
          "followers": profileData["followersCount"] ?? 0,
          "following": profileData["followingCount"] ?? 0,
        };

        if (mounted) {
          setState(() {
            _username = profileData["username"];
            _fullName = profileData["fullName"];
            _avatarUrl = profileData["profilePictureUrl"];
            _stats = stats;
            _bio = {"bio": profileData["bio"] ?? ""};
            _quizzes = quizzes;
            _sessions = sessions;
            _posts = posts;
            _isLoading = false;
          });
          debugPrint(
            '[PROFILE] Loaded: username=$_username, fullName=$_fullName, avatarUrl=$_avatarUrl',
          );
        }
      } else {
        debugPrint(
          '[PROFILE] Failed to load profile: ${profileResponse.statusCode}',
        );
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('[PROFILE] Error loading profile: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Profile"),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        actions: [
          IconButton(
            icon: Icon(
              Icons.edit_outlined,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            onPressed: () async {
              final result = await context.push<bool>("/edit-profile");
              if (result == true) {
                _loadProfile(); // Refresh profile if update was successful
              }
            },
          ),
          IconButton(
            icon: Icon(
              Icons.settings_outlined,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            onPressed: () {
              context.push("/settings");
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildProfileHeader(),
          _buildStatsRow(),
          _buildBioSection(),
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildQuizzesTab(),
                _buildSessionsTab(),
                _buildPostsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          _isLoading
              ? CircleAvatar(
                  radius: 32,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : _avatarUrl != null && _avatarUrl!.isNotEmpty
              ? CircleAvatar(
                  radius: 32,
                  backgroundImage: NetworkImage(_avatarUrl!),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                )
              : CircleAvatar(
                  radius: 32,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: Icon(Icons.person, size: 32, color: Colors.white),
                ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _isLoading
                    ? Container(
                        width: 120,
                        height: 20,
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      )
                    : Text(
                        _fullName ?? "User",
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                SizedBox(height: 2),
                _isLoading
                    ? Container(
                        width: 80,
                        height: 16,
                        margin: EdgeInsets.only(top: 4),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      )
                    : Text(
                        _username != null ? "@$_username" : "@user",
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
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    if (_stats == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _StatItem(count: "...", label: "Followers", onTap: () {}),
            _StatItem(count: "...", label: "Following", onTap: () {}),
            _StatItem(count: "...", label: "Quizzes", onTap: () {}),
            _StatItem(count: "...", label: "Sessions", onTap: () {}),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatItem(
            count: "${_stats!["followers"]}",
            label: "Followers",
            onTap: () {},
          ),
          _StatItem(
            count: "${_stats!["following"]}",
            label: "Following",
            onTap: () {},
          ),
          _StatItem(
            count: "${_stats!["quizzes"]}",
            label: "Quizzes",
            onTap: () {
              _tabController.animateTo(0);
            },
          ),
          _StatItem(
            count: "${_stats!["sessions"]}",
            label: "Sessions",
            onTap: () {
              _tabController.animateTo(1);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBioSection() {
    final bioText = _bio?["bio"] as String?;

    if (bioText == null || bioText.isEmpty) {
      return SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: Text(
        bioText,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurface,
          fontSize: 13,
          height: 1.3,
        ),
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: TabBar(
        controller: _tabController,
        labelColor: Theme.of(context).colorScheme.primary,
        unselectedLabelColor: Theme.of(
          context,
        ).colorScheme.onSurface.withValues(alpha: 0.6),
        indicatorColor: Theme.of(context).colorScheme.primary,
        indicatorWeight: 3,
        tabs: [
          Tab(text: "Quizzes"),
          Tab(text: "Sessions"),
          Tab(text: "Posts"),
        ],
      ),
    );
  }

  Widget _buildQuizzesTab() {
    if (_quizzes.isEmpty) {
      return Center(
        child: Text(
          "No quizzes yet",
          style: TextStyle(
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.75,
      ),
      itemCount: _quizzes.length,
      itemBuilder: (context, index) {
        final quiz = _quizzes[index];
        return _QuizCard(
          id: quiz["id"],
          title: quiz["title"],
          category: quiz["category"] ?? "General",
          plays: quiz["playCount"] ?? 0,
          color: Colors.primaries[index % Colors.primaries.length],
        );
      },
    );
  }

  Widget _buildSessionsTab() {
    if (_sessions.isEmpty) {
      return Center(
        child: Text(
          "No sessions yet",
          style: TextStyle(
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _sessions.length,
      itemBuilder: (context, index) {
        final session = _sessions[index];
        return _SessionCard(
          title: session["title"],
          date: session["date"],
          score: "${session["score"]}",
          rank: "${session["rank"]}",
          totalPlayers: "${session["totalPlayers"]}",
        );
      },
    );
  }

  Widget _buildPostsTab() {
    if (_posts.isEmpty) {
      return Center(
        child: Text(
          "No posts yet",
          style: TextStyle(
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _posts.length,
      itemBuilder: (context, index) {
        final post = _posts[index];
        return _PostCard(
          text: post["text"],
          likes: post["likes"],
          comments: post["comments"],
          time: post["time"],
          fullName: _fullName ?? "User",
          avatarUrl: _avatarUrl,
        );
      },
    );
  }
}

class _StatItem extends StatelessWidget {
  final String count;
  final String label;
  final VoidCallback onTap;

  const _StatItem({
    required this.count,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
        child: Column(
          children: [
            Text(
              count,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.6),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuizCard extends StatelessWidget {
  final String id;
  final String title;
  final String category;
  final int plays;
  final Color color;

  const _QuizCard({
    required this.id,
    required this.title,
    required this.category,
    required this.plays,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.push("/quiz/$id"),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 120,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.3),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        category,
                        style: TextStyle(color: Colors.white, fontSize: 11),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.play_arrow,
                        size: 14,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                      SizedBox(width: 4),
                      Text(
                        "$plays plays",
                        style: TextStyle(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.6),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  final String title;
  final String date;
  final String score;
  final String rank;
  final String totalPlayers;

  const _SessionCard({
    required this.title,
    required this.date,
    required this.score,
    required this.rank,
    required this.totalPlayers,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.emoji_events,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      date,
                      style: TextStyle(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.6),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _SessionStat(label: "Score", value: score),
              _SessionStat(label: "Rank", value: "$rank/$totalPlayers"),
            ],
          ),
        ],
      ),
    );
  }
}

class _SessionStat extends StatelessWidget {
  final String label;
  final String value;

  const _SessionStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: Theme.of(context).colorScheme.primary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.6),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _PostCard extends StatelessWidget {
  final String text;
  final int likes;
  final int comments;
  final String time;
  final String fullName;
  final String? avatarUrl;

  const _PostCard({
    required this.text,
    required this.likes,
    required this.comments,
    required this.time,
    required this.fullName,
    this.avatarUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              avatarUrl != null && avatarUrl!.isNotEmpty
                  ? CircleAvatar(
                      radius: 20,
                      backgroundImage: NetworkImage(avatarUrl!),
                      backgroundColor: Theme.of(context).colorScheme.primary,
                    )
                  : CircleAvatar(
                      radius: 20,
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      child: Icon(Icons.person, size: 20, color: Colors.white),
                    ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fullName,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      time,
                      style: TextStyle(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.6),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            text,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 14,
              height: 1.4,
            ),
          ),
          SizedBox(height: 12),
          Row(
            children: [
              _PostAction(icon: Icons.favorite_border, count: likes),
              SizedBox(width: 24),
              _PostAction(icon: Icons.chat_bubble_outline, count: comments),
              SizedBox(width: 24),
              _PostAction(icon: Icons.share_outlined, count: 0),
            ],
          ),
        ],
      ),
    );
  }
}

class _PostAction extends StatelessWidget {
  final IconData icon;
  final int count;

  const _PostAction({required this.icon, required this.count});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            if (count > 0) ...[
              SizedBox(width: 4),
              Text(
                "$count",
                style: TextStyle(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.6),
                  fontSize: 13,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
