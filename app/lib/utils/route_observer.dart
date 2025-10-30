import "package:flutter/material.dart";

/// Custom route observer to track navigation changes
class NavigationObserver extends NavigatorObserver {
  static final NavigationObserver _instance = NavigationObserver._internal();
  factory NavigationObserver() => _instance;
  NavigationObserver._internal();

  final List<Route> _routeStack = [];
  final List<VoidCallback> _listeners = [];

  /// Current route name
  String? get currentRoute {
    if (_routeStack.isNotEmpty) {
      final route = _routeStack.last;
      return route.settings.name;
    }
    return null;
  }

  /// Previous route name
  String? get previousRoute {
    if (_routeStack.length > 1) {
      final route = _routeStack[_routeStack.length - 2];
      return route.settings.name;
    }
    return null;
  }

  /// Check if the current route is the join page
  bool get isOnJoinPage => currentRoute == "/join";

  /// Check if we're navigating away from the join page
  bool get isNavigatingAwayFromJoinPage {
    return previousRoute == "/join" && currentRoute != "/join";
  }

  /// Add a listener to be notified of navigation changes
  void addListener(VoidCallback listener) {
    _listeners.add(listener);
  }

  /// Remove a listener
  void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
  }

  /// Notify all listeners of navigation changes
  void _notifyListeners() {
    for (final listener in _listeners) {
      listener();
    }
  }

  @override
  void didPush(Route route, Route? previousRoute) {
    super.didPush(route, previousRoute);
    _routeStack.add(route);
    _notifyListeners();
  }

  @override
  void didPop(Route route, Route? previousRoute) {
    super.didPop(route, previousRoute);
    _routeStack.remove(route);
    _notifyListeners();
  }

  @override
  void didReplace({Route? newRoute, Route? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (oldRoute != null) {
      _routeStack.remove(oldRoute);
    }
    if (newRoute != null) {
      _routeStack.add(newRoute);
    }
    _notifyListeners();
  }

  @override
  void didRemove(Route route, Route? previousRoute) {
    super.didRemove(route, previousRoute);
    _routeStack.remove(route);
    _notifyListeners();
  }

  /// Clear the route stack (useful for testing)
  void clear() {
    _routeStack.clear();
    _notifyListeners();
  }
}
