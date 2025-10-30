import "package:flutter/material.dart";

/// Provider to track navigation direction for animated page transitions
class NavigationDirectionProvider extends InheritedWidget {
  final int
  direction; // 1 for right-to-left, -1 for left-to-right, 0 for no animation

  const NavigationDirectionProvider({
    super.key,
    required this.direction,
    required super.child,
  });

  static NavigationDirectionProvider? of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<NavigationDirectionProvider>();
  }

  @override
  bool updateShouldNotify(NavigationDirectionProvider oldWidget) {
    return direction != oldWidget.direction;
  }
}
