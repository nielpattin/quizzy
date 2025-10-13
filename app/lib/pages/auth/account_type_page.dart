import "package:flutter/material.dart";
import "package:go_router/go_router.dart";

class AccountTypePage extends StatelessWidget {
  const AccountTypePage({super.key});

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
                    icon: Icon(
                      Icons.arrow_back,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    onPressed: () => context.go("/get-started"),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: 0.66,
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
                "What type of account\ndo you like to create?",
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  height: 1.2,
                ),
              ),
              SizedBox(height: 40),
              _AccountTypeButton(
                icon: Icons.people_outline,
                label: "Student",
                color: Colors.blue,
                onTap: () => context.go("/username"),
              ),
              SizedBox(height: 16),
              _AccountTypeButton(
                icon: Icons.person_outline,
                label: "Teacher",
                color: Colors.green,
                onTap: () => context.go("/username"),
              ),
              SizedBox(height: 16),
              _AccountTypeButton(
                icon: Icons.work_outline,
                label: "Business",
                color: Colors.orange,
                onTap: () => context.go("/username"),
              ),
              SizedBox(height: 16),
              _AccountTypeButton(
                icon: Icons.person_add_outlined,
                label: "Participate",
                color: Colors.red,
                onTap: () => context.go("/username"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AccountTypeButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _AccountTypeButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 72,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.5), width: 1),
        ),
        child: Row(
          children: [
            Container(
              width: 90,
              decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
              ),
              child: Center(
                child: Icon(
                  icon,
                  color: Theme.of(context).colorScheme.onSurface,
                  size: 32,
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: Text(
                  label,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
