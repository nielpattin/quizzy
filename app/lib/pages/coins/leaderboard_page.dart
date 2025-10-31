import "package:flutter/material.dart";
import "../../services/leaderboard_service.dart";
import "../../widgets/user_avatar.dart";
import "package:go_router/go_router.dart";

class LeaderboardPage extends StatefulWidget {
  const LeaderboardPage({super.key});

  @override
  State<LeaderboardPage> createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage> {
  List<dynamic> _leaderboard = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLeaderboard();
  }

  Future<void> _loadLeaderboard() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final data = await LeaderboardService.getCoinLeaderboard(limit: 100);
      if (mounted) {
        setState(() {
          _leaderboard = data["leaderboard"] as List<dynamic>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return Colors.amber;
      case 2:
        return Colors.grey[400]!;
      case 3:
        return Colors.brown[400]!;
      default:
        return Colors.blue;
    }
  }

  Widget _getRankBadge(int rank) {
    if (rank <= 3) {
      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: _getRankColor(rank),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: rank == 1
              ? const Icon(Icons.emoji_events, color: Colors.white, size: 24)
              : Text(
                  "$rank",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
        ),
      );
    }

    return SizedBox(
      width: 40,
      child: Text(
        "$rank",
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
          color: Colors.grey,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Coin Leaderboard"),
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _leaderboard.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.leaderboard, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    "No rankings yet",
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadLeaderboard,
              child: ListView.builder(
                itemCount: _leaderboard.length,
                itemBuilder: (context, index) {
                  final entry = _leaderboard[index];
                  final rank = entry["rank"] as int;
                  final username = entry["username"] as String?;
                  final fullName = entry["fullName"] as String;
                  final avatarUrl = entry["profilePictureUrl"] as String?;
                  final coins = entry["coins"] as int;
                  final isCurrentUser = entry["isCurrentUser"] as bool;
                  final userId = entry["userId"] as String;

                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    color: isCurrentUser
                        ? Colors.blue.withValues(alpha: 0.1)
                        : null,
                    child: ListTile(
                      leading: _getRankBadge(rank),
                      title: Row(
                        children: [
                          UserAvatar(imageUrl: avatarUrl, radius: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  fullName,
                                  style: TextStyle(
                                    fontWeight: isCurrentUser
                                        ? FontWeight.bold
                                        : FontWeight.w600,
                                  ),
                                ),
                                if (username != null)
                                  Text(
                                    "@$username",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.monetization_on,
                            color: Colors.amber,
                            size: 20,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "$coins",
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.amber,
                            ),
                          ),
                        ],
                      ),
                      onTap: () {
                        context.push("/profile/$userId");
                      },
                    ),
                  );
                },
              ),
            ),
    );
  }
}
