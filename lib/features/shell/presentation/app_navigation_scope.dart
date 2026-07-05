import 'package:flutter/widgets.dart';

class AppNavigationScope extends InheritedWidget {
  const AppNavigationScope({
    super.key,
    required this.selectedIndex,
    required this.onSelectTab,
    required super.child,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelectTab;

  static AppNavigationScope of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<AppNavigationScope>();
    assert(
      scope != null,
      'AppNavigationScope was not found in the widget tree.',
    );
    return scope!;
  }

  @override
  bool updateShouldNotify(AppNavigationScope oldWidget) {
    return selectedIndex != oldWidget.selectedIndex ||
        onSelectTab != oldWidget.onSelectTab;
  }
}
