import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/app_page_route.dart';
import '../../../core/widgets/feature_hero_banner.dart';
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
    final quickStats = [
      _MoreStat('Modules', '${items.length}', Icons.widgets_outlined),
      _MoreStat('Role', _roleLabel(session.role), Icons.verified_user_outlined),
      _MoreStat(
        'Access',
        session.canUploadResources ? 'Staff tools' : 'Student view',
        Icons.hub_outlined,
      ),
    ];

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
          children: [
            FeatureHeroBanner(
              title: 'More from VU Hub',
              subtitle:
                  'Explore the wider campus toolkit: support routing, guild services, live events, and the student community.',
              icon: Icons.grid_view_rounded,
              scheme: scheme,
              badge: 'Campus toolkit',
              height: 184,
            ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.05, end: 0),
            const SizedBox(height: 20),
            SizedBox(
              height: 118,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: quickStats.length,
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (context, index) => SizedBox(
                  width: 168,
                  child: _MoreOverviewCard(stat: quickStats[index]),
                ),
              ),
            ),
            const SizedBox(height: 18),
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
            const SectionHeader(title: 'Campus spaces'),
            const SizedBox(height: 8),
            Text(
              'These modules are now connected to real repositories where available and remain backward-compatible with the current Firebase collections.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            // LayoutBuilder(
            //   builder: (context, constraints) {
            //     final compact = constraints.maxWidth < 720;
            //     final cardWidth = compact
            //         ? constraints.maxWidth
            //         : (constraints.maxWidth - 12) / 2;
            //     return Wrap(
            //       spacing: 12,
            //       runSpacing: 12,
            //       children: items
            //           .map(
            //             (item) => SizedBox(
            //               width: cardWidth,
            //               child: _MoreFeatureCard(item: item),
            //             ),
            //           )
            //           .toList(),
            //     );
            //   },
            // ),
            const SizedBox(height: 20),
            const SectionHeader(title: 'Quick actions'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _MoreQuickActionChip(
                  icon: Icons.live_tv,
                  label: 'Campus live',
                  tone: scheme.primary,
                ),
                _MoreQuickActionChip(
                  icon: Icons.auto_awesome,
                  label: 'AI support routes',
                  tone: scheme.secondary,
                ),
                _MoreQuickActionChip(
                  icon: Icons.groups_2_outlined,
                  label: 'Guild feedback',
                  tone: scheme.tertiary,
                ),
              ],
            ),
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: scheme.primary.withValues(alpha: 0.12),
                      ),
                      child: Icon(
                        Icons.explore_outlined,
                        color: scheme.primary,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Refined campus navigation',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'This area is now structured as a cleaner launch point into student services, community spaces, and live campus activity.',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
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
                                : () => Navigator.of(
                                    context,
                                  ).push(buildAppPageRoute(item.screen!)),
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

class _MoreStat {
  const _MoreStat(this.label, this.value, this.icon);

  final String label;
  final String value;
  final IconData icon;
}

class _MoreOverviewCard extends StatelessWidget {
  const _MoreOverviewCard({required this.stat});

  final _MoreStat stat;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: scheme.primary.withValues(alpha: 0.12),
              ),
              child: Icon(stat.icon, color: scheme.primary),
            ),
            const Spacer(),
            Text(stat.value, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(stat.label, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}

class _MoreQuickActionChip extends StatelessWidget {
  const _MoreQuickActionChip({
    required this.icon,
    required this.label,
    required this.tone,
  });

  final IconData icon;
  final String label;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: tone.withValues(alpha: 0.1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: tone),
          const SizedBox(width: 8),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(color: tone),
          ),
        ],
      ),
    );
  }
}
