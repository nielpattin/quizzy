import "package:flutter/foundation.dart";
import "route_observer.dart";

/// Global camera state manager to track camera state across the app
class CameraStateManager extends ChangeNotifier {
  static final CameraStateManager _instance = CameraStateManager._internal();
  factory CameraStateManager() => _instance;
  CameraStateManager._internal() {
    // Listen to navigation changes
    NavigationObserver().addListener(_onNavigationChanged);
  }

  bool _isCameraActive = false;
  bool _isOnJoinPage = false;
  bool _isOnQRTab = false;

  /// Whether the camera should be active
  bool get isCameraActive => _isCameraActive;

  /// Whether we're on the join page
  bool get isOnJoinPage => _isOnJoinPage;

  /// Whether we're on the QR tab
  bool get isOnQRTab => _isOnQRTab;

  /// Update the state when we're on the join page
  void setOnJoinPage(bool isOnJoinPage) {
    if (_isOnJoinPage != isOnJoinPage) {
      debugPrint("DEBUG: CameraStateManager - setOnJoinPage: $isOnJoinPage");
      _isOnJoinPage = isOnJoinPage;
      _updateCameraState();
    }
  }

  /// Update the state when we're on the QR tab
  void setOnQRTab(bool isOnQRTab) {
    if (_isOnQRTab != isOnQRTab) {
      debugPrint("DEBUG: CameraStateManager - setOnQRTab: $isOnQRTab");
      _isOnQRTab = isOnQRTab;
      _updateCameraState();
    }
  }

  /// Called when navigation changes
  void _onNavigationChanged() {
    final observer = NavigationObserver();
    final wasOnJoinPage = _isOnJoinPage;
    _isOnJoinPage = observer.isOnJoinPage;

    debugPrint("DEBUG: CameraStateManager - navigation changed");
    debugPrint(
      "DEBUG: CameraStateManager - wasOnJoinPage: $wasOnJoinPage, isOnJoinPage: $_isOnJoinPage",
    );
    debugPrint(
      "DEBUG: CameraStateManager - currentRoute: ${observer.currentRoute}",
    );
    debugPrint(
      "DEBUG: CameraStateManager - previousRoute: ${observer.previousRoute}",
    );
    debugPrint(
      "DEBUG: CameraStateManager - isNavigatingAwayFromJoinPage: ${observer.isNavigatingAwayFromJoinPage}",
    );

    // If we're navigating away from the join page, stop the camera
    if (wasOnJoinPage && !_isOnJoinPage) {
      debugPrint(
        "DEBUG: CameraStateManager - navigating away from join page, stopping camera",
      );
      _isOnQRTab = false; // We're no longer on any tab in the join page
    }

    _updateCameraState();
  }

  /// Update the camera state based on current conditions
  void _updateCameraState() {
    final shouldBeActive = _isOnJoinPage && _isOnQRTab;

    if (_isCameraActive != shouldBeActive) {
      debugPrint(
        "DEBUG: CameraStateManager - updating camera state: $_isCameraActive -> $shouldBeActive",
      );
      _isCameraActive = shouldBeActive;
      notifyListeners();
    }
  }

  /// Force stop the camera (called when navigating away)
  void stopCamera() {
    if (_isCameraActive) {
      debugPrint("DEBUG: CameraStateManager - force stopping camera");
      _isCameraActive = false;
      _isOnQRTab = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    NavigationObserver().removeListener(_onNavigationChanged);
    super.dispose();
  }
}
