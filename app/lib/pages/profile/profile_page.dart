import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "package:supabase_flutter/supabase_flutter.dart";
import "package:http/http.dart" as http;
import "package:flutter_dotenv/flutter_dotenv.dart";
import "dart:convert";
import "widgets/profile_header.dart";
import "widgets/profile_stats.dart";
import "widgets/profile_coin_card.dart";
import "widgets/profile_loading_skeleton.dart";
import "widgets/profile_tabs_content.dart";
import "../../widgets/app_header.dart";
import "../../pages/library/models/game_session.dart";

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Future<Map<String, dynamic>>? _profileFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _profileFuture = _loadProfile();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>> _loadProfile() async {
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) {
      throw Exception('No session found');
    }

    final token = session.accessToken;
    final serverUrl = dotenv.env["SERVER_URL"]!;

    final profileResponse = await http
        .get(
          Uri.parse("$serverUrl/api/user/profile"),
          headers: {"Authorization": "Bearer $token"},
        )
        .timeout(const Duration(seconds: 10));

    if (profileResponse.statusCode == 404) {
      await Supabase.instance.client.auth.signOut();
      if (mounted) {
        context.go("/login");
      }
      throw Exception('User not found');
    }

    if (profileResponse.statusCode != 200) {
      throw Exception('Failed to load profile: ${profileResponse.statusCode}');
    }

    final profileData = json.decode(profileResponse.body);

    final results = await Future.wait([
      http.get(
        Uri.parse("$serverUrl/api/user/quizzes"),
        headers: {"Authorization": "Bearer $token"},
      ),
      http.get(
        Uri.parse("$serverUrl/api/user/sessions"),
        headers: {"Authorization": "Bearer $token"},
      ),
      http.get(
        Uri.parse("$serverUrl/api/user/posts"),
        headers: {"Authorization": "Bearer $token"},
      ),
    ]);

    final quizzes = results[0].statusCode == 200
        ? json.decode(results[0].body) as List<dynamic>
        : <dynamic>[];
    final sessionsData = results[1].statusCode == 200
        ? json.decode(results[1].body) as List<dynamic>
        : <dynamic>[];
    final posts = results[2].statusCode == 200
        ? json.decode(results[2].body) as List<dynamic>
        : <dynamic>[];

    // Parse sessions into GameSession objects with random gradients
    final sessions = sessionsData
        .asMap()
        .entries
        .map((entry) {
          final gradient = Colors.primaries[entry.key % Colors.primaries.length];
          return GameSession.fromJson(
            entry.value as Map<String, dynamic>,
            [gradient, gradient.withValues(alpha: 0.7)],
          );
        })
        .toList();

    return {
      'username': profileData["username"],
      'fullName': profileData["fullName"],
      'avatarUrl': profileData["profilePictureUrl"],
      'bio': profileData["bio"] ?? "",
      'coins': profileData["coins"] ?? 1000,
      'quizzes': quizzes,
      'sessions': sessions,
      'posts': posts,
      'stats': {
        "quizzes": quizzes.length,
        "sessions": sessions.length,
        "posts": posts.length,
        "followers": profileData["followersCount"] ?? 0,
        "following": profileData["followingCount"] ?? 0,
      },
    };
  }

  Future<void> _refreshProfile() async {
    setState(() {
      _profileFuture = _loadProfile();
    });
    await _profileFuture;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: FutureBuilder<Map<String, dynamic>>(
          future: _profileFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Column(
                children: [
                  const AppHeader(title: "Profile"),
                  Expanded(child: ProfileLoadingSkeleton()),
                ],
              );
            }

            if (snapshot.hasError) {
              return Column(
                children: [
                  const AppHeader(title: "Profile"),
                  Expanded(
                    child: Center(
                      child: Text(
                        'Error loading profile',
                        style: TextStyle(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }

            if (!snapshot.hasData) {
              return Column(
                children: [
                  const AppHeader(title: "Profile"),
                  Expanded(child: ProfileLoadingSkeleton()),
                ],
              );
            }

            final data = snapshot.data!;
            final username = data['username'] as String?;
            final fullName = data['fullName'] as String?;
            final avatarUrl = data['avatarUrl'] as String?;
            final bio = data['bio'] as String;
            final coins = data['coins'] as int;
            final quizzes = data['quizzes'] as List<dynamic>;
            final sessions = data['sessions'] as List<GameSession>;
            final posts = data['posts'] as List<dynamic>;
            final stats = data['stats'] as Map<String, dynamic>;

            return Column(
              children: [
                const AppHeader(title: "Profile"),
                ProfileHeader(
                  fullName: fullName,
                  username: username,
                  avatarUrl: avatarUrl,
                  onEditPressed: () async {
                    final result = await context.push<bool>("/edit-profile");
                    if (result == true) {
                      setState(() {
                        _profileFuture = _loadProfile();
                      });
                    }
                  },
                  onSettingsPressed: () {
                    context.push("/settings");
                  },
                ),
                const SizedBox(height: 8),
                ProfileCoinCard(
                  coins: coins,
                  onTap: () {
                    context.push("/profile/coins/history");
                  },
                ),
                const SizedBox(height: 16),
                ProfileStats(
                  stats: stats,
                  onFollowersPressed: () {
                    final currentUserId =
                        Supabase.instance.client.auth.currentUser?.id;
                    if (currentUserId != null) {
                      context.push(
                        "/profile/followers-following?userId=$currentUserId&initialTab=0",
                      );
                    }
                  },
                  onFollowingPressed: () {
                    final currentUserId =
                        Supabase.instance.client.auth.currentUser?.id;
                    if (currentUserId != null) {
                      context.push(
                        "/profile/followers-following?userId=$currentUserId&initialTab=1",
                      );
                    }
                  },
                  onQuizzesPressed: () {
                    _tabController.animateTo(0);
                  },
                  onSessionsPressed: () {
                    _tabController.animateTo(1);
                  },
                ),
                if (bio.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 4.0,
                    ),
                    child: Text(
                      bio,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 13,
                        height: 1.3,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                  child: TabBar(
                    controller: _tabController,
                    labelColor: Theme.of(context).colorScheme.primary,
                    unselectedLabelColor: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.6),
                    indicatorColor: Theme.of(context).colorScheme.primary,
                    indicatorWeight: 3,
                    tabs: const [
                      Tab(text: "Quizzes"),
                      Tab(text: "Sessions"),
                      Tab(text: "Posts"),
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      ProfileTabsContent.buildQuizzesTab(
                        context,
                        quizzes,
                        _refreshProfile,
                      ),
                      ProfileTabsContent.buildSessionsTab(
                        context,
                        sessions,
                        _refreshProfile,
                      ),
                      ProfileTabsContent.buildPostsTab(
                        context,
                        posts,
                        fullName,
                        avatarUrl,
                        _refreshProfile,
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
