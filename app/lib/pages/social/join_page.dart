import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "../../widgets/bottom_nav.dart";
import "qr_tab.dart";
import "code_tab.dart";
import "../../utils/camera_state_manager.dart";

class JoinPage extends StatefulWidget {
  final bool showBottomNav;
  const JoinPage({super.key, this.showBottomNav = true});

  @override
  State<JoinPage> createState() => _JoinPageState();
}

class _JoinPageState extends State<JoinPage> with WidgetsBindingObserver {
  int _selectedTab = 0;
  bool _isPageVisible = true;
  bool _shouldCameraBeActive = false;

  // Global camera state manager
  final CameraStateManager _cameraStateManager = CameraStateManager();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Update the camera state manager that we're on the join page
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cameraStateManager.setOnJoinPage(true);
    });
  }

  @override
  void dispose() {
    _cameraStateManager.setOnJoinPage(false);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _onTabChanged(int tabIndex) {
    setState(() {
      _selectedTab = tabIndex;
    });

    // Update camera active state based on tab selection
    _shouldCameraBeActive = (_selectedTab == 1);

    // Update the camera state manager
    _cameraStateManager.setOnQRTab(_selectedTab == 1);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      final isVisible = route.isCurrent && route.isActive;

      if (isVisible && !_isPageVisible) {
        _isPageVisible = true;
        // debugPrint("DEBUG: JoinPage became visible");
      } else if (!isVisible && _isPageVisible) {
        _isPageVisible = false;
        // debugPrint("DEBUG: JoinPage became hidden");
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // debugPrint("DEBUG: JoinPage app lifecycle state changed to: $state");

    switch (state) {
      case AppLifecycleState.resumed:
        // App is resumed - camera will be handled by QRTab based on its own visibility logic
        // debugPrint("DEBUG: JoinPage app resumed");
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        // App is paused/hidden - camera will be handled by QRTab based on its own lifecycle
        // debugPrint("DEBUG: JoinPage app paused/hidden");
        break;
      case AppLifecycleState.detached:
        // App is being detached
        // debugPrint("DEBUG: JoinPage app detached");
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          _shouldCameraBeActive = false; // Reset camera state
        }
      },
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          elevation: 0,
          automaticallyImplyLeading: false,
          leading: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.quiz, color: Colors.white, size: 24),
            ),
          ),
          title: Text(
            "Join Game",
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            IconButton(
              icon: Icon(
                Icons.search,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              onPressed: () {
                _shouldCameraBeActive = false; // Reset camera state
                context.push("/search");
              },
            ),
            IconButton(
              icon: Icon(
                Icons.notifications_outlined,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              onPressed: () {
                _shouldCameraBeActive = false; // Reset camera state
                context.push("/notification");
              },
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: _TabButton(
                        label: "Enter Code",
                        isSelected: _selectedTab == 0,
                        onTap: () => _onTabChanged(0),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: _TabButton(
                        label: "Scan QR Code",
                        isSelected: _selectedTab == 1,
                        onTap: () => _onTabChanged(1),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _selectedTab == 0 ? const CodeTab() : const QRTab(),
              ),
            ],
          ),
        ),
        bottomNavigationBar: widget.showBottomNav
            ? const BottomNav(selectedIndex: 2)
            : null,
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: isSelected
              ? null
              : Border.all(
                  color: Theme.of(context).colorScheme.primary,
                  width: 2,
                ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected
                ? Colors.white
                : Theme.of(context).colorScheme.primary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
