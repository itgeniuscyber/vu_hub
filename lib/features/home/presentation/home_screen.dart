import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/feature_hero_banner.dart';
import '../../../core/widgets/firestore_error_state.dart';
import '../../../core/widgets/loading_shimmer.dart';
import '../../../core/widgets/metric_card.dart';
import '../../../core/widgets/section_header.dart';
import '../../auth/data/app_session.dart';
import '../../feed/data/announcement.dart';
import '../../feed/data/announcement_repository.dart';
import '../../live/data/campus_event.dart';
import '../../live/data/events_repository.dart';
import '../../shell/presentation/app_navigation_scope.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final navigation = AppNavigationScope.of(context);
    final session = context.watch<AppSession>();
    final cards = [
      _QuickAction(
        icon: Icons.auto_awesome,
        title: 'Ask VU AI',
        subtitle: 'Campus help, summaries, study support',
        color: scheme.primary,
        onTap: () => navigation.onSelectTab(3),
      ),
      _QuickAction(
        icon: Icons.folder_copy,
        title: 'Past papers',
        subtitle: 'Open VU Vault resources',
        color: scheme.secondary,
        onTap: () => navigation.onSelectTab(2),
      ),
      _QuickAction(
        icon: Icons.support_agent,
        title: 'Help desk',
        subtitle: 'Find the right office faster',
        color: const Color(0xFF22C55E),
        onTap: () => navigation.onSelectTab(4),
      ),
    ];

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async =>
              Future<void>.delayed(const Duration(milliseconds: 500)),
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
                sliver: SliverList.list(
                  children: [
                    _HeroHeader(scheme: scheme, session: session),
                    const SizedBox(height: 22),
                    _StoryStrip(scheme: scheme),
                    const SizedBox(height: 18),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final crossAxisCount = constraints.maxWidth >= 720
                            ? 3
                            : 2;
                        return GridView.count(
                          crossAxisCount: crossAxisCount,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: constraints.maxWidth >= 720
                              ? 1.15
                              : 1.05,
                          children: [
                            _MetricAction(
                              onTap: () => navigation.onSelectTab(1),
                              child: MetricCard(
                                icon: Icons.campaign,
                                label: 'Latest notices',
                                value: 'Feed',
                                color: scheme.primary,
                              ),
                            ),
                            _MetricAction(
                              onTap: () => navigation.onSelectTab(4),
                              child: const MetricCard(
                                icon: Icons.event_available,
                                label: 'Campus events',
                                value: 'Live',
                                color: Color(0xFFFBBF24),
                              ),
                            ),
                            _MetricAction(
                              onTap: () => navigation.onSelectTab(4),
                              child: MetricCard(
                                icon: Icons.chat_bubble,
                                label: 'Community',
                                value: 'Chat',
                                color: scheme.secondary,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    const SectionHeader(title: 'Quick actions'),
                    const SizedBox(height: 12),
                    ...cards
                        .map(
                          (card) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: card,
                          ),
                        )
                        .toList()
                        .animate(interval: 90.ms)
                        .fadeIn(duration: 350.ms)
                        .slideX(begin: 0.08, end: 0),
                    const SizedBox(height: 12),
                    const SectionHeader(title: 'Today at VU'),
                    const SizedBox(height: 12),
                    _DashboardEventCard(scheme: scheme),
                    const SizedBox(height: 12),
                    _DashboardAnnouncementCard(scheme: scheme),
                    const SizedBox(height: 12),
                    _CampusPulseCard(scheme: scheme),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroHeader extends StatelessWidget {
  const _HeroHeader({required this.scheme, required this.session});

  final ColorScheme scheme;
  final AppSession session;

  @override
  Widget build(BuildContext context) {
    final name = session.profile?.displayName.trim().isNotEmpty == true
        ? session.profile!.displayName.trim().split(' ').first
        : 'Student';
    return FeatureHeroBanner(
      title: 'Good evening, $name',
      subtitle:
          'Your campus command center for announcements, resources, events, and AI-powered support.',
      icon: Icons.school,
      scheme: scheme,
      badge: 'Victoria University',
      height: 232,
      trailing: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.16),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.24)),
        ),
        child: const Icon(Icons.notifications_none, color: Colors.white),
      ),
    ).animate().fadeIn(duration: 450.ms).slideY(begin: 0.08, end: 0);
  }
}

class _StoryStrip extends StatelessWidget {
  const _StoryStrip({required this.scheme});

  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 92,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: const [
          _StoryBubble(
            label: 'Live now',
            icon: Icons.podcasts,
            highlighted: true,
          ),
          _StoryBubble(label: 'Guild', icon: Icons.groups_2_outlined),
          _StoryBubble(label: 'Events', icon: Icons.celebration_outlined),
          _StoryBubble(label: 'AI Tips', icon: Icons.auto_awesome),
          _StoryBubble(label: 'Support', icon: Icons.support_agent),
        ],
      ),
    );
  }
}

class _StoryBubble extends StatelessWidget {
  const _StoryBubble({
    required this.label,
    required this.icon,
    this.highlighted = false,
  });

  final String label;
  final IconData icon;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(right: 14),
      child: Column(
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: highlighted
                  ? LinearGradient(
                      colors: [
                        scheme.primary,
                        scheme.secondary,
                        scheme.tertiary,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: highlighted ? null : scheme.surfaceContainerHighest,
            ),
            padding: const EdgeInsets.all(2),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: highlighted
                    ? Colors.white.withValues(alpha: 0.12)
                    : scheme.surface,
              ),
              child: Icon(
                icon,
                color: highlighted ? Colors.white : scheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    ).animate().fadeIn(duration: 450.ms).slideY(begin: 0.08, end: 0);
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  color: color.withValues(alpha: 0.14),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(subtitle),
                  ],
                ),
              ),
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: 0.12),
                ),
                child: Icon(Icons.chevron_right, color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricAction extends StatelessWidget {
  const _MetricAction({required this.onTap, required this.child});

  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: child,
    );
  }
}

class _DashboardEventCard extends StatelessWidget {
  const _DashboardEventCard({required this.scheme});

  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<CampusEvent>>(
      stream: EventsRepository().watchEvents(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingShimmer(height: 178);
        }
        if (snapshot.hasError) {
          return FirestoreErrorState(
            error: snapshot.error!,
            title: 'Could not load campus events',
            fallbackMessage:
                'Upcoming campus events are unavailable right now.',
          );
        }
        final event = (snapshot.data ?? [])
            .where((item) {
              return item.status == CampusEventStatus.upcoming ||
                  item.status == CampusEventStatus.live;
            })
            .cast<CampusEvent?>()
            .firstOrNull;
        if (event == null) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Text(
                'Upcoming campus events will appear here as soon as Firestore returns them.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          );
        }
        return Card(
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                colors: [
                  scheme.primary.withValues(alpha: 0.08),
                  scheme.secondary.withValues(alpha: 0.06),
                  scheme.surface,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Chip(
                      avatar: Icon(
                        event.status == CampusEventStatus.live
                            ? Icons.circle
                            : Icons.schedule,
                        size: 16,
                      ),
                      label: Text(
                        event.status == CampusEventStatus.live
                            ? 'Live now'
                            : 'Upcoming',
                      ),
                    ),
                    const Spacer(),
                    Text(
                      event.category,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  event.title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 6),
                Text(
                  event.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Chip(
                      avatar: const Icon(Icons.place_outlined, size: 16),
                      label: Text(event.location),
                    ),
                    Chip(
                      avatar: const Icon(Icons.event, size: 16),
                      label: Text(
                        event.startTime == null
                            ? 'Date TBC'
                            : DateFormat(
                                'EEE, MMM d • HH:mm',
                              ).format(event.startTime!),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DashboardAnnouncementCard extends StatelessWidget {
  const _DashboardAnnouncementCard({required this.scheme});

  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Announcement>>(
      stream: AnnouncementRepository().watchLatest(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingShimmer(height: 164);
        }
        if (snapshot.hasError) {
          return FirestoreErrorState(
            error: snapshot.error!,
            title: 'Could not load announcements',
            fallbackMessage:
                'Official announcements are unavailable right now.',
          );
        }
        final item = (snapshot.data ?? []).cast<Announcement?>().firstOrNull;
        if (item == null) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Text(
                'Latest notices from the official announcements collection will appear here.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          );
        }
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Chip(label: Text(item.category)),
                    const Spacer(),
                    if (item.isPinned)
                      Icon(Icons.push_pin, color: scheme.primary, size: 18),
                  ],
                ),
                const SizedBox(height: 10),
                Text(item.title, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 6),
                Text(
                  item.content,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Text(
                  item.createdAt == null
                      ? 'Published recently'
                      : 'Published ${DateFormat('MMM d').format(item.createdAt!)}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CampusPulseCard extends StatelessWidget {
  const _CampusPulseCard({required this.scheme});

  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.insights, color: scheme.primary),
                const SizedBox(width: 12),
                Text(
                  'Campus pulse',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'AI insights will summarize top student questions, resources, and guild feedback here.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: const [
                Chip(label: Text('Support trends')),
                Chip(label: Text('Event reminders')),
                Chip(label: Text('Guild sentiment')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
