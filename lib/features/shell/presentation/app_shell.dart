import 'package:flutter/material.dart';

import '../../ai_desk/presentation/ai_desk_screen.dart';
import '../../feed/presentation/feed_screen.dart';
import '../../home/presentation/home_screen.dart';
import '../../more/presentation/more_screen.dart';
import '../../vault/presentation/vault_screen.dart';
import 'app_navigation_scope.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  final _screens = const [
    HomeScreen(),
    FeedScreen(),
    VaultScreen(),
    AiDeskScreen(),
    MoreScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final destinations = _destinations;
    return AppNavigationScope(
      selectedIndex: _index,
      onSelectTab: (value) => setState(() => _index = value),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final useRail = constraints.maxWidth >= 840;
          final content = Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: useRail ? 1180 : double.infinity,
              ),
              child: IndexedStack(index: _index, children: _screens),
            ),
          );

          if (useRail) {
            return Scaffold(
              body: Row(
                children: [
                  NavigationRail(
                    selectedIndex: _index,
                    onDestinationSelected: (value) =>
                        setState(() => _index = value),
                    labelType: NavigationRailLabelType.all,
                    leading: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Icon(
                        Icons.school,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    destinations: destinations
                        .map(
                          (item) => NavigationRailDestination(
                            icon: Icon(item.icon),
                            selectedIcon: Icon(item.selectedIcon),
                            label: Text(item.label),
                          ),
                        )
                        .toList(),
                  ),
                  VerticalDivider(
                    width: 1,
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                  Expanded(child: content),
                ],
              ),
            );
          }

          return Scaffold(
            body: content,
            bottomNavigationBar: NavigationBar(
              selectedIndex: _index,
              onDestinationSelected: (value) => setState(() => _index = value),
              destinations: destinations
                  .map(
                    (item) => NavigationDestination(
                      icon: Icon(item.icon),
                      selectedIcon: Icon(item.selectedIcon),
                      label: item.label,
                    ),
                  )
                  .toList(),
            ),
          );
        },
      ),
    );
  }
}

const _destinations = [
  _ShellDestination(
    icon: Icons.dashboard_outlined,
    selectedIcon: Icons.dashboard,
    label: 'Home',
  ),
  _ShellDestination(
    icon: Icons.campaign_outlined,
    selectedIcon: Icons.campaign,
    label: 'Feed',
  ),
  _ShellDestination(
    icon: Icons.folder_copy_outlined,
    selectedIcon: Icons.folder_copy,
    label: 'Vault',
  ),
  _ShellDestination(
    icon: Icons.auto_awesome_outlined,
    selectedIcon: Icons.auto_awesome,
    label: 'AI',
  ),
  _ShellDestination(
    icon: Icons.apps_outlined,
    selectedIcon: Icons.apps,
    label: 'More',
  ),
];

class _ShellDestination {
  const _ShellDestination({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
}
