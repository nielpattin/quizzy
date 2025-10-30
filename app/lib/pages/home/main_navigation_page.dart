import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "package:supabase_flutter/supabase_flutter.dart";
import "package:http/http.dart" as http;
import "package:flutter_dotenv/flutter_dotenv.dart";
import "dart:convert";
import "../../widgets/auth_modal.dart";
import "../../utils/camera_state_manager.dart";
import "../../utils/navigation_direction_provider.dart";
import "../../services/home_repository.dart";

class MainNavigationPage extends StatefulWidget {
  final int initialIndex;
  final Widget child; // Child from ShellRoute
  const MainNavigationPage({
    super.key,
    this.initialIndex = 0,
    required this.child,
  });

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  late int _currentIndex;
  int _navigationDirection = 0; // 1 for right, -1 for left, 0 for no animation
  final CameraStateManager _cameraStateManager = CameraStateManager();

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _checkSetupStatus();

    // Update camera state based on initial index
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateCameraState();
    });
  }

  @override
  void didUpdateWidget(MainNavigationPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update current index when route changes (e.g., from browser back button)
    // Only recalculate direction if the index actually changed AND it's different from our current state
    if (widget.initialIndex != oldWidget.initialIndex &&
        widget.initialIndex != _currentIndex) {
      final direction = widget.initialIndex > _currentIndex ? 1 : -1;
      setState(() {
        _currentIndex = widget.initialIndex;
        _navigationDirection = direction;
      });
      _updateCameraState();
    }
  }

  Future<void> _checkSetupStatus() async {
    try {
      final session = Supabase.instance.client.auth.currentSession;
      if (session == null) {
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
      // Silently ignore setup check errors
    }
  }

  void _onNavTap(int index, BuildContext context) {
    // Start prefetch early for Home to make transition smooth
    if (index == 0) {
      HomeRepository.instance.prefetch();
    }

    // Calculate direction BEFORE updating state
    final direction = index > _currentIndex ? 1 : -1;

    setState(() {
      _currentIndex = index;
      _navigationDirection = direction;
    });

    // Navigate to the appropriate route
    switch (index) {
      case 0:
        context.go('/home');
        break;
      case 1:
        context.go('/library');
        break;
      case 2:
        context.go('/join');
        break;
      case 3:
        context.go('/profile');
        break;
    }

    // Update camera state when navigation changes
    _updateCameraState();
  }

  /// Update camera state based on current navigation index
  void _updateCameraState() {
    if (_currentIndex == 2) {
      // We're on the join page
      _cameraStateManager.setOnJoinPage(true);
    } else {
      // We're not on the join page
      _cameraStateManager.setOnJoinPage(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return NavigationDirectionProvider(
      direction: _navigationDirection,
      child: Scaffold(
        body: widget.child, // Display the child from ShellRoute
        bottomNavigationBar: _BottomNav(
          selectedIndex: _currentIndex,
          onTap: (index) => _onNavTap(index, context),
        ),
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
                onTap: () {
                  final session = Supabase.instance.client.auth.currentSession;
                  if (session == null) {
                    showAuthModal(context);
                  } else {
                    onTap(1);
                  }
                },
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
                    context.go("/create-quiz");
                  }
                },
              ),
              _NavItem(
                icon: Icons.person_outline,
                label: "Profile",
                isSelected: selectedIndex == 3,
                onTap: () {
                  final session = Supabase.instance.client.auth.currentSession;
                  if (session == null) {
                    showAuthModal(context);
                  } else {
                    onTap(3);
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
