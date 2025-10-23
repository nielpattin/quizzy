import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "package:supabase_flutter/supabase_flutter.dart";
import "../../services/api_service.dart";
import "widgets/profile_header.dart";
import "widgets/profile_stats.dart";
import "widgets/profile_loading_skeleton.dart";
import "widgets/profile_tabs_content.dart";

class UserProfilePage extends StatefulWidget {
  final String userId;

  const UserProfilePage({super.key, required this.userId});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Future<Map<String, dynamic>>? _profileFuture;
  bool _isFollowing = false;
  bool _isOwnProfile = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _checkIfOwnProfile();
    _profileFuture = _loadProfile();
  }

  void _checkIfOwnProfile() {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    _isOwnProfile = currentUserId == widget.userId;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>> _loadProfile() async {
    final data = await ApiService.getUserProfile(widget.userId);

    setState(() {
      _isFollowing = data["isFollowing"] ?? false;
    });

    return {
      'username': data["username"],
      'fullName': data["fullName"],
      'avatarUrl': data["profilePictureUrl"],
      'bio': data["bio"] ?? "",
      'quizzes': data["quizzes"] ?? [],
      'sessions': data["sessions"] ?? [],
      'posts': data["posts"] ?? [],
      'stats': {
        "quizzes": (data["quizzes"] as List?)?.length ?? 0,
        "sessions": (data["sessions"] as List?)?.length ?? 0,
        "posts": (data["posts"] as List?)?.length ?? 0,
        "followers": data["followersCount"] ?? 0,
        "following": data["followingCount"] ?? 0,
      },
    };
  }

  Future<void> _toggleFollow() async {
    try {
      if (_isFollowing) {
        await ApiService.unfollowUser(widget.userId);
      } else {
        await ApiService.followUser(widget.userId);
      }

      setState(() {
        _isFollowing = !_isFollowing;
        _profileFuture = _loadProfile();
      });
    } catch (e) {
      debugPrint("[UserProfilePage] Error toggling follow: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to update follow status")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Profile"),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _profileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return ProfileLoadingSkeleton();
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Error loading profile',
                    style: TextStyle(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _profileFuture = _loadProfile();
                      });
                    },
                    child: Text("Retry"),
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData) {
            return ProfileLoadingSkeleton();
          }

          final data = snapshot.data!;
          final username = data['username'] as String?;
          final fullName = data['fullName'] as String?;
          final avatarUrl = data['avatarUrl'] as String?;
          final bio = data['bio'] as String;
          final quizzes = data['quizzes'] as List<dynamic>;
          final sessions = data['sessions'] as List<dynamic>;
          final posts = data['posts'] as List<dynamic>;
          final stats = data['stats'] as Map<String, dynamic>;

          return Column(
            children: [
              ProfileHeader(
                fullName: fullName,
                username: username,
                avatarUrl: avatarUrl,
              ),
              ProfileStats(
                stats: stats,
                onFollowersPressed: () {},
                onFollowingPressed: () {},
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
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 12.0,
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isOwnProfile
                        ? () async {
                            final result = await context.push<bool>(
                              "/edit-profile",
                            );
                            if (result == true) {
                              setState(() {
                                _profileFuture = _loadProfile();
                              });
                            }
                          }
                        : _toggleFollow,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isOwnProfile
                          ? Theme.of(context).colorScheme.surface
                          : _isFollowing
                          ? Theme.of(context).colorScheme.surface
                          : Theme.of(context).colorScheme.primary,
                      foregroundColor: _isOwnProfile
                          ? Theme.of(context).colorScheme.onSurface
                          : _isFollowing
                          ? Theme.of(context).colorScheme.onSurface
                          : Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: (_isOwnProfile || _isFollowing)
                            ? BorderSide(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: 0.2),
                              )
                            : BorderSide.none,
                      ),
                    ),
                    child: Text(
                      _isOwnProfile
                          ? "Edit Profile"
                          : _isFollowing
                          ? "Following"
                          : "Follow",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ),
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
                  tabs: [
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
                    ProfileTabsContent.buildQuizzesTab(context, quizzes),
                    ProfileTabsContent.buildSessionsTab(context, sessions),
                    ProfileTabsContent.buildPostsTab(
                      context,
                      posts,
                      fullName,
                      avatarUrl,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
