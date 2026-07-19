import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vu_hub/core/widgets/app_fui_icon.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/firestore_error_state.dart';
import '../../../core/widgets/loading_shimmer.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/utils/app_page_route.dart';
import '../../auth/data/app_session.dart';
import '../../community/presentation/community_screen.dart';
import '../../feed/data/announcement.dart';
import '../../feed/data/announcement_repository.dart';
import '../../live/data/campus_event.dart';
import '../../live/data/events_repository.dart';
import '../../notifications/data/notification_repository.dart';
import '../../notifications/presentation/notifications_screen.dart';
import '../../shell/presentation/app_navigation_scope.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final navigation = AppNavigationScope.of(context);
    final session = context.watch<AppSession>();
    final bgColor = isDark ? scheme.surface : Colors.white;

    final quickActions = [
      _QuickAction(
        icon: BoldRounded.magicWand,
        title: 'Ask VU AI',
        subtitle: 'Campus help, summaries, study support',
        color: scheme.primary,
        onTap: () => navigation.onSelectTab(3),
      ),
      _QuickAction(
        icon: BoldRounded.folder,
        title: 'Past papers',
        subtitle: 'Open VU Vault resources',
        color: scheme.secondary,
        onTap: () => navigation.onSelectTab(2),
      ),
      _QuickAction(
        icon: BoldRounded.headset,
        title: 'Help desk',
        subtitle: 'Find the right office faster',
        color: const Color(0xFF22C55E),
        onTap: () => navigation.onSelectTab(4),
      ),
    ];

    return Scaffold(
      backgroundColor: bgColor,
      body: RefreshIndicator(
        onRefresh: () async =>
            Future<void>.delayed(const Duration(milliseconds: 500)),
        child: CustomScrollView(
          slivers: [
            // Premium Header with Background Image
            SliverToBoxAdapter(child: _PremiumHomeHeader(session: session)),

            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
              sliver: SliverList.list(
                children: [
                  const SizedBox(height: 24),
                  _StoryStrip(scheme: scheme),
                  const SizedBox(height: 24),

                  // Metric / Navigation Cards
                  LayoutBuilder(
                        builder: (context, constraints) {
                          final crossAxisCount = constraints.maxWidth >= 720
                              ? 3
                              : 2;
                          return GridView.count(
                            crossAxisCount: crossAxisCount,
                            shrinkWrap: true,
                            padding: EdgeInsets.zero,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: constraints.maxWidth >= 720
                                ? 1.3
                                : 1.1,
                            children: [
                              _PremiumMetricCard(
                                icon: BoldRounded.megaphone,
                                title: 'Feed',
                                subtitle: 'Latest notices',
                                color: scheme.primary,
                                onTap: () => navigation.onSelectTab(1),
                              ),
                              _PremiumMetricCard(
                                icon: BoldRounded.calendar,
                                title: 'Live',
                                subtitle: 'Campus events',
                                color: const Color(0xFFFBBF24),
                                onTap: () => navigation.onSelectTab(4),
                              ),
                              _PremiumMetricCard(
                                icon: BoldRounded.comment,
                                title: 'Chat',
                                subtitle: 'Community room',
                                color: scheme.secondary,
                                onTap: () => Navigator.of(context).push(
                                  buildAppPageRoute(const CommunityScreen()),
                                ),
                              ),
                              _PremiumMetricCard(
                                icon: BoldRounded.comments,
                                title: 'Discussions',
                                subtitle: 'Academic threads',
                                color: const Color(0xFF8B5CF6),
                                onTap: () => Navigator.of(context).push(
                                  buildAppPageRoute(
                                    const CommunityDiscussionsScreen(),
                                  ),
                                ),
                              ),
                              _PremiumMetricCard(
                                icon: BoldRounded.grid,
                                title: 'Posts',
                                subtitle: 'Campus moments',
                                color: const Color(0xFFF97316),
                                onTap: () => Navigator.of(context).push(
                                  buildAppPageRoute(
                                    const CommunityPostsScreen(),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      )
                      .animate()
                      .fadeIn(duration: 400.ms)
                      .slideY(begin: 0.05, end: 0),

                  const SizedBox(height: 32),
                  const SectionHeader(title: 'Quick Actions'),
                  const SizedBox(height: 16),
                  ...quickActions
                      .map(
                        (card) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: card,
                        ),
                      )
                      .toList()
                      .animate(interval: 60.ms)
                      .fadeIn(duration: 300.ms)
                      .slideX(begin: 0.05, end: 0),

                  const SizedBox(height: 24),
                  const SectionHeader(title: 'Today at VU'),
                  const SizedBox(height: 16),
                  _DashboardEventCard(scheme: scheme),
                  const SizedBox(height: 16),
                  _DashboardAnnouncementCard(scheme: scheme),
                  const SizedBox(height: 16),
                  _CampusPulseCard(scheme: scheme),
                  const SizedBox(height: 80), // Bottom padding for shell nav
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PremiumHomeHeader extends StatelessWidget {
  const _PremiumHomeHeader({required this.session});
  final AppSession session;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? scheme.surface : Colors.white;

    final name = session.profile?.displayName.trim().isNotEmpty == true
        ? session.profile!.displayName.trim().split(' ').first
        : 'Student';

    return SizedBox(
      height: 260,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background Image
          Image.asset(
            'assets/images/p6.jpeg',
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
          ),
          // Gradient Overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.3),
                  Colors.black.withValues(alpha: 0.6),
                  bgColor,
                ],
                stops: const [0.0, 0.6, 1.0],
              ),
            ),
          ),
          // Content
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Profile Badge
                      Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.4),
                            width: 2,
                          ),
                        ),
                        child: const CircleAvatar(
                          radius: 20,
                          backgroundColor: Colors.white24,
                          child: FUI(
                            SolidRounded.user,
                            color: Colors.white,
                            width: 20,
                            height: 20,
                          ),
                        ),
                      ),
                      StreamBuilder<int>(
                        stream: NotificationRepository().watchRecentCount(),
                        builder: (context, snapshot) {
                          final count = snapshot.data ?? 0;
                          return InkWell(
                            borderRadius: BorderRadius.circular(22),
                            onTap: () => Navigator.of(context).push(
                              buildAppPageRoute(const NotificationsScreen()),
                            ),
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.15),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white.withValues(
                                        alpha: 0.2,
                                      ),
                                    ),
                                  ),
                                  child: const FUI(
                                    RegularRounded.bell,
                                    color: Colors.white,
                                    width: 18,
                                    height: 18,
                                  ),
                                ),
                                if (count > 0)
                                  Positioned(
                                    right: -1,
                                    top: -1,
                                    child: Container(
                                      constraints: const BoxConstraints(
                                        minWidth: 18,
                                        minHeight: 18,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFF006E),
                                        borderRadius: BorderRadius.circular(
                                          999,
                                        ),
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 1.5,
                                        ),
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        count > 9 ? '9+' : '$count',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const Spacer(),
                  // Greeting
                  Text(
                        'Good evening,\n$name',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              height: 1.1,
                            ),
                      )
                      .animate()
                      .fadeIn(duration: 400.ms)
                      .slideY(begin: 0.2, end: 0),
                  const SizedBox(height: 8),
                  Text(
                    'Your campus command center',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.2, end: 0),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PremiumMetricCard extends StatelessWidget {
  const _PremiumMetricCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final String icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? scheme.surfaceContainerHigh : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDark
                ? Colors.white12
                : Colors.black.withValues(alpha: 0.05),
          ),
          boxShadow: isDark
              ? []
              : [
                  BoxShadow(
                    color: color.withValues(alpha: 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: FUI(icon, color: color, width: 20, height: 20),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white54 : Colors.black54,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StoryStrip extends StatelessWidget {
  const _StoryStrip({required this.scheme});

  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 84,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: const [
          _StoryBubble(
            label: 'Live now',
            icon: BoldRounded.videoCamera,
            highlighted: true,
          ),
          _StoryBubble(label: 'Guild', icon: BoldRounded.user),
          _StoryBubble(label: 'Events', icon: BoldRounded.calendar),
          _StoryBubble(label: 'AI Tips', icon: BoldRounded.magicWand),
          _StoryBubble(label: 'Support', icon: BoldRounded.headset),
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
  final String icon;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(right: 14),
      child: Column(
        children: [
          Container(
            width: 54,
            height: 54,
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
              child: FUI(
                icon,
                color: highlighted ? Colors.white : scheme.primary,
                width: 20,
                height: 20,
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

  final String icon;
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
                child: FUI(icon, color: color, width: 20, height: 20),
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
                child: FUI(
                  BoldRounded.arrowSmallRight,
                  color: color,
                  width: 18,
                  height: 18,
                ),
              ),
            ],
          ),
        ),
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
                      avatar: FUI(
                        event.status == CampusEventStatus.live
                            ? SolidRounded.circle
                            : RegularRounded.clock,
                        width: 14,
                        height: 14,
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
                      avatar: const FUI(
                        RegularRounded.map,
                        width: 16,
                        height: 16,
                      ),
                      label: Text(event.location),
                    ),
                    Chip(
                      avatar: const FUI(
                        RegularRounded.calendar,
                        width: 16,
                        height: 16,
                      ),
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
                      FUI(
                        BoldRounded.bookmark,
                        color: scheme.primary,
                        width: 18,
                        height: 18,
                      ),
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
                FUI(
                  BoldRounded.magicWand,
                  color: scheme.primary,
                  width: 21,
                  height: 21,
                ),
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
