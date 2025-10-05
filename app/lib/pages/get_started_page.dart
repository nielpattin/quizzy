import "package:flutter/material.dart";
import "package:go_router/go_router.dart";

class GetStartedPage extends StatelessWidget {
  const GetStartedPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.onSurface),
                    onPressed: () => context.go("/walkthrough"),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: 0.33,
                        backgroundColor: Colors.grey[800],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).colorScheme.primary,
                        ),
                        minHeight: 6,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 40),
              Text(
                "Great!",
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                "Let's Get Started",
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 40),
              _OAuthButton(
                icon: Icons.code,
                label: "Sign Up with GitHub",
                onTap: () => context.go("/account-type"),
              ),
              SizedBox(height: 16),
              _OAuthButton(
                icon: Icons.g_mobiledata,
                label: "Sign Up with Google",
                iconColor: Color(0xFF4285F4),
                onTap: () => context.go("/account-type"),
              ),
              SizedBox(height: 16),
              _OAuthButton(
                icon: Icons.window,
                label: "Sign Up with Microsoft",
                iconColor: Color(0xFF00A4EF),
                onTap: () => context.go("/account-type"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OAuthButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? iconColor;
  final VoidCallback onTap;

  const _OAuthButton({
    required this.icon,
    required this.label,
    this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor ?? Theme.of(context).colorScheme.onSurface, size: 28),
            SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(Icons.arrow_forward, color: Theme.of(context).colorScheme.onSurface, size: 24),
          ],
        ),
      ),
    );
  }
}
