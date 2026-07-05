import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

import '../../../core/widgets/firestore_error_state.dart';
import '../../../core/widgets/loading_shimmer.dart';
import '../../../core/widgets/metric_card.dart';
import '../../../core/widgets/section_header.dart';
import '../../feed/data/announcement.dart';
import '../../feed/data/announcement_repository.dart';
import '../../live/data/campus_event.dart';
import '../../live/data/events_repository.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final cards = [
      _QuickAction(
        icon: Icons.auto_awesome,
        title: 'Ask VU AI',
        subtitle: 'Campus help, summaries, study support',
        color: scheme.primary,
      ),
      _QuickAction(
        icon: Icons.folder_copy,
        title: 'Past papers',
        subtitle: 'Open VU Vault resources',
        color: scheme.secondary,
      ),
      _QuickAction(
        icon: Icons.support_agent,
        title: 'Help desk',
        subtitle: 'Find the right office faster',
        color: const Color(0xFF22C55E),
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
                    _HeroHeader(scheme: scheme),
                    const SizedBox(height: 22),
                    GridView.count(
                      crossAxisCount: 3,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 0.92,
                      children: [
                        MetricCard(
                          icon: Icons.campaign,
                          label: 'Latest notices',
                          value: 'Feed',
                          color: scheme.primary,
                        ),
                        MetricCard(
                          icon: Icons.event_available,
                          label: 'Campus events',
                          value: 'Live',
                          color: const Color(0xFFFBBF24),
                        ),
                        MetricCard(
                          icon: Icons.chat_bubble,
                          label: 'Community',
                          value: 'Chat',
                          color: scheme.secondary,
                        ),
                      ],
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
  const _HeroHeader({required this.scheme});

  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          colors: [scheme.primary, scheme.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.school, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                'Victoria University',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'Good evening, Student',
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            'Your campus command center for announcements, resources, events, and AI-powered support.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.86),
            ),
          ),
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
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        minVerticalPadding: 16,
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.14),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: Theme.of(context).textTheme.titleMedium),
        subtitle: Text(subtitle),
        trailing: Icon(Icons.chevron_right, color: color),
      ),
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
          child: Padding(
            padding: const EdgeInsets.all(18),
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
