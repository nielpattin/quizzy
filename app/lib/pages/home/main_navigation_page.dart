import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "package:supabase_flutter/supabase_flutter.dart";
import "package:http/http.dart" as http;
import "package:flutter_dotenv/flutter_dotenv.dart";
import "dart:convert";
import "home_page.dart";
import "../library/library_page.dart";
import "../social/join_page.dart";
import "../../widgets/auth_modal.dart";

class MainNavigationPage extends StatefulWidget {
  final int initialIndex;
  const MainNavigationPage({super.key, this.initialIndex = 0});

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  late int _currentIndex;
  bool _isCheckingSetup = true;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _checkSetupStatus();
  }

  Future<void> _checkSetupStatus() async {
    try {
      final session = Supabase.instance.client.auth.currentSession;
      if (session == null) {
        setState(() {
          _isCheckingSetup = false;
        });
        return;
      }

      final token = session.accessToken;
      final serverUrl = dotenv.env["SERVER_URL"]!;

      final response = await http.get(
        Uri.parse("$serverUrl/api/user/profile"),
        headers: {"Authorization": "Bearer $token"},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final userData = data["user"];
        if (mounted && userData["setup_account_completed"] == false) {
          context.go(
            "/setup-account",
            extra: {
              "email": userData["email"],
              "name": userData["name"],
              "image": userData["image"],
            },
          );
          return;
        }
      }
    } catch (e) {
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingSetup = false;
        });
      }
    }
  }

  void _onNavTap(int index, BuildContext context) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          HomePage(showBottomNav: false),
          LibraryPage(showBottomNav: false),
          JoinPage(showBottomNav: false),
        ],
      ),
      bottomNavigationBar: _BottomNav(
        selectedIndex: _currentIndex,
        onTap: (index) => _onNavTap(index, context),
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onTap;
  const _BottomNav({required this.selectedIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.home,
                label: "Home",
                isSelected: selectedIndex == 0,
                onTap: () => onTap(0),
              ),
              _NavItem(
                icon: Icons.library_books_outlined,
                label: "Library",
                isSelected: selectedIndex == 1,
                onTap: () => onTap(1),
              ),
              _NavItem(
                icon: Icons.play_arrow,
                label: "Join",
                isSelected: selectedIndex == 2,
                onTap: () => onTap(2),
              ),
              _NavItem(
                icon: Icons.add_box_outlined,
                label: "Create",
                onTap: () {
                  final session = Supabase.instance.client.auth.currentSession;
                  if (session == null) {
                    showAuthModal(context);
                  } else {
                    context.push("/create-quiz");
                  }
                },
              ),
              _NavItem(
                icon: Icons.person_outline,
                label: "Profile",
                isSelected: selectedIndex == 4,
                onTap: () {
                  final session = Supabase.instance.client.auth.currentSession;
                  if (session == null) {
                    showAuthModal(context);
                  } else {
                    context.push("/profile");
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback? onTap;
  const _NavItem({
    required this.icon,
    required this.label,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        splashColor: Theme.of(
          context,
        ).colorScheme.primary.withValues(alpha: 0.2),
        highlightColor: Theme.of(
          context,
        ).colorScheme.primary.withValues(alpha: 0.1),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.6),
                size: 26,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.6),
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
