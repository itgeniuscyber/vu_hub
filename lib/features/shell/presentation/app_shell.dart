import 'package:flutter/material.dart';
import 'dart:ui';

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
            extendBody: true,
            body: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 102),
                  child: content,
                ),
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 18,
                  child: _FloatingBottomBar(
                    selectedIndex: _index,
                    destinations: destinations,
                    onSelected: (value) => setState(() => _index = value),
                  ),
                ),
              ],
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

class _FloatingBottomBar extends StatelessWidget {
  const _FloatingBottomBar({
    required this.selectedIndex,
    required this.destinations,
    required this.onSelected,
  });

  final int selectedIndex;
  final List<_ShellDestination> destinations;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: scheme.surface.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: scheme.outlineVariant.withValues(alpha: 0.5),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: List.generate(destinations.length, (index) {
              final item = destinations[index];
              final selected = selectedIndex == index;
              return Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: selected
                        ? LinearGradient(
                            colors: [
                              scheme.primary.withValues(alpha: 0.18),
                              scheme.secondary.withValues(alpha: 0.16),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => onSelected(index),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 10,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            selected ? item.selectedIcon : item.icon,
                            color: selected
                                ? scheme.primary
                                : scheme.onSurface.withValues(alpha: 0.72),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(
                                  fontSize: 12,
                                  color: selected
                                      ? scheme.primary
                                      : scheme.onSurface.withValues(alpha: 0.68),
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
