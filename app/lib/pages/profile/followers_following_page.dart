import "package:flutter/material.dart";
import "../../services/api_service.dart";
import "widgets/user_list_item.dart";

class FollowersFollowingPage extends StatefulWidget {
  final String userId;
  final int initialTab;

  const FollowersFollowingPage({
    super.key,
    required this.userId,
    this.initialTab = 0,
  });

  @override
  State<FollowersFollowingPage> createState() => _FollowersFollowingPageState();
}

class _FollowersFollowingPageState extends State<FollowersFollowingPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Future<List<dynamic>>? _followersFuture;
  Future<List<dynamic>>? _followingFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab,
    );
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadData() {
    setState(() {
      _followersFuture = ApiService.getFollowers(widget.userId);
      _followingFuture = ApiService.getFollowing(widget.userId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Connections"),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Theme.of(context).colorScheme.primary,
          unselectedLabelColor: Theme.of(
            context,
          ).colorScheme.onSurface.withValues(alpha: 0.6),
          indicatorColor: Theme.of(context).colorScheme.primary,
          indicatorWeight: 3,
          tabs: [
            Tab(text: "Followers"),
            Tab(text: "Following"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildFollowersList(), _buildFollowingList()],
      ),
    );
  }

  Widget _buildFollowersList() {
    return FutureBuilder<List<dynamic>>(
      future: _followersFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingSkeleton();
        }

        if (snapshot.hasError) {
          return _buildErrorState("Failed to load followers", () {
            _loadData();
          });
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyState(
            "No followers yet",
            "When people follow this account, they'll appear here.",
          );
        }

        final followers = snapshot.data!;
        return RefreshIndicator(
          onRefresh: () async {
            _loadData();
            await _followersFuture;
          },
          child: ListView.builder(
            itemCount: followers.length,
            itemBuilder: (context, index) {
              final followerData = followers[index];
              final user = followerData["user"] as Map<String, dynamic>?;

              if (user == null) return const SizedBox.shrink();

              return UserListItem(userData: user, onFollowChanged: _loadData);
            },
          ),
        );
      },
    );
  }

  Widget _buildFollowingList() {
    return FutureBuilder<List<dynamic>>(
      future: _followingFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingSkeleton();
        }

        if (snapshot.hasError) {
          return _buildErrorState("Failed to load following", () {
            _loadData();
          });
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyState(
            "Not following anyone yet",
            "When this account follows people, they'll appear here.",
          );
        }

        final following = snapshot.data!;
        return RefreshIndicator(
          onRefresh: () async {
            _loadData();
            await _followingFuture;
          },
          child: ListView.builder(
            itemCount: following.length,
            itemBuilder: (context, index) {
              final followingData = following[index];
              final user = followingData["user"] as Map<String, dynamic>?;

              if (user == null) return const SizedBox.shrink();

              return UserListItem(userData: user, onFollowChanged: _loadData);
            },
          ),
        );
      },
    );
  }

  Widget _buildLoadingSkeleton() {
    return ListView.builder(
      itemCount: 10,
      itemBuilder: (context, index) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 150,
                      height: 14,
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: 100,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 90,
                height: 32,
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(String title, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 80,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
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
    );
  }

  Widget _buildErrorState(String message, VoidCallback onRetry) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton(
              onPressed: onRetry,
              style: OutlinedButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.primary,
                side: BorderSide(color: Theme.of(context).colorScheme.primary),
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
              ),
              child: Text("Retry"),
            ),
          ],
        ),
      ),
    );
  }
}
