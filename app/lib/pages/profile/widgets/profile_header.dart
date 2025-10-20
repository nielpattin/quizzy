import "package:flutter/material.dart";
import "../../../utils/image_helper.dart";

class ProfileHeader extends StatelessWidget {
  final String? fullName;
  final String? username;
  final String? avatarUrl;

  const ProfileHeader({
    super.key,
    this.fullName,
    this.username,
    this.avatarUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          ImageHelper.createValidNetworkImage(avatarUrl) != null
              ? CircleAvatar(
                  radius: 32,
                  backgroundImage: ImageHelper.createValidNetworkImage(
                    avatarUrl,
                  )!,
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
                Text(
                  fullName ?? "User",
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 2),
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
        ],
      ),
    );
  }
}
