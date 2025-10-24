import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "package:supabase_flutter/supabase_flutter.dart";
import "../../../services/api_service.dart";
import "../../../widgets/user_avatar.dart";

class UserListItem extends StatefulWidget {
  final Map<String, dynamic> userData;
  final VoidCallback? onFollowChanged;

  const UserListItem({super.key, required this.userData, this.onFollowChanged});

  @override
  State<UserListItem> createState() => _UserListItemState();
}

class _UserListItemState extends State<UserListItem> {
  bool _isFollowing = false;
  bool _isLoading = false;
  bool _isCurrentUser = false;

  @override
  void initState() {
    super.initState();
    _checkFollowStatus();
    _checkIfCurrentUser();
  }

  void _checkFollowStatus() async {
    final userId = widget.userData["id"] as String?;
    if (userId == null) return;

    try {
      final isFollowing = await ApiService.isFollowing(userId);
      if (mounted) {
        setState(() {
          _isFollowing = isFollowing;
        });
      }
    } catch (e) {
      debugPrint("[UserListItem] Error checking follow status: $e");
    }
  }

  void _checkIfCurrentUser() {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    final userId = widget.userData["id"] as String?;
    _isCurrentUser = currentUserId == userId;
  }

  Future<void> _toggleFollow() async {
    final userId = widget.userData["id"] as String?;
    if (userId == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      if (_isFollowing) {
        await ApiService.unfollowUser(userId);
      } else {
        await ApiService.followUser(userId);
      }

      if (mounted) {
        setState(() {
          _isFollowing = !_isFollowing;
          _isLoading = false;
        });
        widget.onFollowChanged?.call();
      }
    } catch (e) {
      debugPrint("[UserListItem] Error toggling follow: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to update follow status")),
        );
      }
    }
  }

  void _navigateToProfile() {
    final userId = widget.userData["id"] as String?;
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;

    if (userId == null) return;

    if (userId == currentUserId) {
      context.go("/profile");
    } else {
      context.push("/profile/$userId");
    }
  }

  @override
  Widget build(BuildContext context) {
    final fullName = widget.userData["fullName"] as String? ?? "Unknown";
    final username = widget.userData["username"] as String? ?? "";
    final avatarUrl = widget.userData["profilePictureUrl"] as String?;

    return InkWell(
      onTap: _navigateToProfile,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          children: [
            UserAvatar(imageUrl: avatarUrl, radius: 24),
            const SizedBox(width: 12),
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
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (username.isNotEmpty)
                    Text(
                      "@$username",
                      style: TextStyle(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.6),
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            if (!_isCurrentUser) ...[
              const SizedBox(width: 12),
              _isLoading
                  ? SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    )
                  : OutlinedButton(
                      onPressed: _toggleFollow,
                      style: OutlinedButton.styleFrom(
                        backgroundColor: _isFollowing
                            ? Theme.of(context).colorScheme.primary
                            : Colors.transparent,
                        foregroundColor: _isFollowing
                            ? Colors.white
                            : Theme.of(context).colorScheme.primary,
                        side: BorderSide(
                          color: Theme.of(context).colorScheme.primary,
                          width: 1.5,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 8,
                        ),
                        minimumSize: const Size(90, 32),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: Text(
                        _isFollowing ? "Following" : "Follow",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
            ],
          ],
        ),
      ),
    );
  }
}
