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
      _isOnJoinPage = isOnJoinPage;
      _updateCameraState();
    }
  }

  /// Update the state when we're on the QR tab
  void setOnQRTab(bool isOnQRTab) {
    if (_isOnQRTab != isOnQRTab) {
      _isOnQRTab = isOnQRTab;
      _updateCameraState();
    }
  }

  /// Called when navigation changes
  void _onNavigationChanged() {
    final observer = NavigationObserver();
    final wasOnJoinPage = _isOnJoinPage;
    _isOnJoinPage = observer.isOnJoinPage;

    // If we're navigating away from the join page, stop the camera
    if (wasOnJoinPage && !_isOnJoinPage) {
      _isOnQRTab = false; // We're no longer on any tab in the join page
    }

    _updateCameraState();
  }

  /// Update the camera state based on current conditions
  void _updateCameraState() {
    final shouldBeActive = _isOnJoinPage && _isOnQRTab;

    if (_isCameraActive != shouldBeActive) {
      _isCameraActive = shouldBeActive;
      notifyListeners();
    }
  }

  /// Force stop the camera (called when navigating away)
  void stopCamera() {
    if (_isCameraActive) {
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
