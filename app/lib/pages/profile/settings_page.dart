import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "package:supabase_flutter/supabase_flutter.dart";

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  Future<void> _handleLogout(BuildContext context) async {
    try {
      await Supabase.instance.client.auth.signOut();
      if (context.mounted) {
        context.go("/login");
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to logout: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Settings"),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          onPressed: () {
            context.pop();
          },
        ),
      ),
      body: ListView(
        children: [
          SizedBox(height: 16),
          _buildSettingsSection(
            context,
            title: "Account",
            items: [
              _SettingsItem(
                icon: Icons.person_outline,
                title: "Edit Profile",
                subtitle: "Update your profile information",
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Edit Profile - Coming Soon"),
                      backgroundColor: Theme.of(context).colorScheme.primary,
                    ),
                  );
                },
              ),
              _SettingsItem(
                icon: Icons.lock_outline,
                title: "Privacy",
                subtitle: "Manage your privacy settings",
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Privacy Settings - Coming Soon"),
                      backgroundColor: Theme.of(context).colorScheme.primary,
                    ),
                  );
                },
              ),
            ],
          ),
          SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => _handleLogout(context),
              child: Text(
                "Logout",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildSettingsSection(
    BuildContext context, {
    required String title,
    required List<_SettingsItem> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            title,
            style: TextStyle(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.6),
              fontSize: 14,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),
        SizedBox(height: 8),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16.0),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.1),
            ),
          ),
          child: Column(
            children: [
              for (int i = 0; i < items.length; i++) ...[
                InkWell(
                  onTap: items[i].onTap,
                  borderRadius: BorderRadius.vertical(
                    top: i == 0 ? Radius.circular(12) : Radius.zero,
                    bottom: i == items.length - 1
                        ? Radius.circular(12)
                        : Radius.zero,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Icon(
                          items[i].icon,
                          color: Theme.of(context).colorScheme.onSurface,
                          size: 24,
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                items[i].title,
                                style: TextStyle(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (items[i].subtitle != null) ...[
                                SizedBox(height: 4),
                                Text(
                                  items[i].subtitle!,
                                  style: TextStyle(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.6),
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.4),
                        ),
                      ],
                    ),
                  ),
                ),
                if (i < items.length - 1)
                  Divider(
                    height: 1,
                    indent: 56,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.1),
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _SettingsItem {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  _SettingsItem({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
  });
}
