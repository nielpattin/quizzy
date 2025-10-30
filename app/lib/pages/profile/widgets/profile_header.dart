import "package:flutter/material.dart";
import "../../../widgets/user_avatar.dart";

class ProfileHeader extends StatelessWidget {
  final String? fullName;
  final String? username;
  final String? avatarUrl;
  final VoidCallback? onEditPressed;
  final VoidCallback? onSettingsPressed;

  const ProfileHeader({
    super.key,
    this.fullName,
    this.username,
    this.avatarUrl,
    this.onEditPressed,
    this.onSettingsPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          UserAvatar(imageUrl: avatarUrl, radius: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fullName ?? "User",
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  username != null ? "@$username" : "@user",
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
          if (onEditPressed != null)
            IconButton(
              icon: Icon(
                Icons.edit_outlined,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              onPressed: onEditPressed,
            ),
          if (onSettingsPressed != null)
            IconButton(
              icon: Icon(
                Icons.settings_outlined,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              onPressed: onSettingsPressed,
            ),
        ],
      ),
    );
  }
}
