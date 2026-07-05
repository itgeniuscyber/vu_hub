import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/section_header.dart';
import '../../auth/data/app_session.dart';
import '../../auth/data/user_profile.dart';
import '../../community/presentation/community_screen.dart';
import '../../directory/presentation/dept_finder_screen.dart';
import '../../guild/presentation/guild_hub_screen.dart';
import '../../live/presentation/vu_live_screen.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final session = context.watch<AppSession>();
    final items = [
      _MoreItem(
        Icons.groups,
        'Guild Hub',
        'Verified guild updates and feedback',
        screen: const GuildHubScreen(),
      ),
      _MoreItem(
        Icons.location_city,
        'Dept Finder',
        'Departments, offices, and lecturers',
        screen: const DeptFinderScreen(),
      ),
      _MoreItem(
        Icons.live_tv,
        'VU Live',
        'Campus events and stream links',
        screen: const VuLiveScreen(),
      ),
      _MoreItem(
        Icons.forum,
        'Community',
        'Public chat, discussions, and posts',
        screen: const CommunityScreen(),
      ),
      _MoreItem(
        Icons.settings,
        'Settings',
        'Theme, notifications, and account',
      ),
    ];

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                color: scheme.surfaceContainer,
                border: Border.all(color: scheme.outlineVariant),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: scheme.primary.withValues(alpha: 0.14),
                    child: Icon(Icons.grid_view_rounded, color: scheme.primary),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      'Explore the wider campus toolkit: support routing, guild services, live events, and the student community.',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.05, end: 0),
            const SizedBox(height: 20),
            Card(
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: CircleAvatar(
                  backgroundColor: scheme.secondary.withValues(alpha: 0.14),
                  child: Icon(Icons.person_outline, color: scheme.secondary),
                ),
                title: Text(session.profile?.displayName ?? 'Signed-in user'),
                subtitle: Text(
                  'Role: ${_roleLabel(session.role)}'
                  '${session.firebaseUser?.email == null ? '' : ' • ${session.firebaseUser!.email}'}',
                ),
                trailing: TextButton(
                  onPressed: session.isSignedIn ? session.signOut : null,
                  child: const Text('Sign out'),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const SectionHeader(title: 'More'),
            const SizedBox(height: 8),
            Text(
              'These modules are now connected to real repositories where available and remain backward-compatible with the current Firebase collections.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            ...items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child:
                    Card(
                          child: InkWell(
                            borderRadius: BorderRadius.circular(24),
                            onTap: item.screen == null
                                ? null
                                : () => Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => item.screen!,
                                    ),
                                  ),
                            child: ListTile(
                              minVerticalPadding: 16,
                              leading: CircleAvatar(
                                backgroundColor: scheme.primary.withValues(
                                  alpha: 0.12,
                                ),
                                child: Icon(item.icon, color: scheme.primary),
                              ),
                              title: Text(item.title),
                              subtitle: Text(item.subtitle),
                              trailing: const Icon(Icons.chevron_right),
                            ),
                          ),
                        )
                        .animate()
                        .fadeIn(duration: 320.ms)
                        .slideX(begin: 0.04, end: 0),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _roleLabel(AppUserRole role) {
  switch (role) {
    case AppUserRole.admin:
      return 'Admin';
    case AppUserRole.lecturer:
      return 'Lecturer';
    case AppUserRole.guildOfficial:
      return 'Guild official';
    case AppUserRole.unknown:
      return 'Unknown';
    case AppUserRole.student:
      return 'Student';
  }
}

class _MoreItem {
  const _MoreItem(this.icon, this.title, this.subtitle, {this.screen});

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? screen;
}
