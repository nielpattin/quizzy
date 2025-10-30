import "package:flutter/material.dart";
import "package:flutter/foundation.dart";
import "package:flutter_dotenv/flutter_dotenv.dart";
import "../pages/profile/debug_page.dart";

/// Controller for the debug overlay visibility
class DebugOverlayController extends ChangeNotifier {
  bool _visible = false;

  bool get visible => _visible;

  void toggle() {
    _visible = !_visible;
    debugPrint('[DebugOverlayController] Toggled to: $_visible');
    notifyListeners();
  }

  void show() {
    if (!_visible) {
      _visible = true;
      debugPrint('[DebugOverlayController] Showing overlay');
      notifyListeners();
    }
  }

  void hide() {
    if (_visible) {
      _visible = false;
      debugPrint('[DebugOverlayController] Hiding overlay');
      notifyListeners();
    }
  }
}

/// Debug overlay widget that renders a modal when visible
/// Wraps the entire app to enable global F12 toggle
class DebugOverlay extends StatelessWidget {
  final DebugOverlayController controller;
  final Widget child;

  const DebugOverlay({
    required this.controller,
    required this.child,
    super.key,
  });

  /// Check if debug button should be visible based on Flutter debug mode AND .env DEBUG variable
  bool _shouldShowDebugButton() {
    // Never show in release mode for security
    if (!kDebugMode) return false;

    // Check .env DEBUG variable
    final debugEnv = dotenv.env['DEBUG']?.toLowerCase();
    return debugEnv == 'true' || debugEnv == '1';
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return Stack(
          children: [
            child,
            // Floating debug button (visible when DEBUG=true in .env AND in debug mode)
            if (!controller.visible && _shouldShowDebugButton())
              Positioned(
                top: 50,
                left: 0,
                right: 0,
                child: Center(
                  child: FloatingActionButton(
                    mini: true,
                    backgroundColor: Colors.red.withOpacity(0.8),
                    onPressed: () {
                      debugPrint('[DebugOverlay] FAB pressed!');
                      controller.show();
                    },
                    child: const Icon(Icons.bug_report, color: Colors.white),
                  ),
                ),
              ),
            if (controller.visible)
              Positioned.fill(
                child: Material(
                  color: Theme.of(context).colorScheme.surface,
                  child: Column(
                    children: [
                      // Modal header
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.surfaceContainerHighest,
                          border: Border(
                            bottom: BorderSide(
                              color: Theme.of(
                                context,
                              ).colorScheme.outline.withOpacity(0.2),
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.bug_report,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              "Debug Info",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              "Tap X to close",
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withOpacity(0.6),
                              ),
                            ),
                            const SizedBox(width: 12),
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: controller.hide,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ],
                        ),
                      ),
                      // Modal body
                      const Expanded(child: DebugPanel()),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
