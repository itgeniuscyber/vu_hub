import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/firestore_error_state.dart';
import '../../../core/widgets/loading_shimmer.dart';
import '../../../core/widgets/section_header.dart';
import '../data/campus_event.dart';
import '../data/events_repository.dart';

class VuLiveScreen extends StatefulWidget {
  const VuLiveScreen({super.key});

  @override
  State<VuLiveScreen> createState() => _VuLiveScreenState();
}

class _VuLiveScreenState extends State<VuLiveScreen> {
  String _selectedFilter = 'All';

  static const _filters = [
    'All',
    'Live',
    'Today',
    'This week',
    'Featured',
    'Technology',
    'Entertainment',
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('VU Live')),
      body: SafeArea(
        child: StreamBuilder<List<CampusEvent>>(
          stream: EventsRepository().watchEvents(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                children: const [
                  LoadingShimmer(height: 220),
                  SizedBox(height: 16),
                  LoadingShimmer(height: 46),
                  SizedBox(height: 16),
                  LoadingShimmer(height: 164),
                  SizedBox(height: 12),
                  LoadingShimmer(height: 164),
                ],
              );
            }
            if (snapshot.hasError) {
              return FirestoreErrorState(
                error: snapshot.error!,
                icon: Icons.live_tv_outlined,
                title: 'Events unavailable',
                fallbackMessage: 'Campus events could not be loaded right now.',
              );
            }
            final events = snapshot.data ?? [];
            if (events.isEmpty) {
              return const EmptyState(
                icon: Icons.event_busy_outlined,
                title: 'No campus events yet',
                message:
                    'Upcoming events and stream links from the existing collection will appear here.',
              );
            }

            final filtered = events.where(_matchesFilter).toList();
            final fallbackLiveCount = events
                .where((item) => item.status == CampusEventStatus.live)
                .length;
            final fallbackUpcomingCount = events
                .where((item) => item.status == CampusEventStatus.upcoming)
                .length;
            final fallbackCompletedCount = events
                .where((item) => item.status == CampusEventStatus.completed)
                .length;
            final live = filtered
                .where((item) => item.status == CampusEventStatus.live)
                .toList();
            final upcoming = filtered
                .where((item) => item.status == CampusEventStatus.upcoming)
                .toList();
            final completed = filtered
                .where((item) => item.status == CampusEventStatus.completed)
                .toList();

            if (filtered.isEmpty) {
              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                children: [
                  SizedBox(
                    height: 40,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _filters.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final label = _filters[index];
                        return ChoiceChip(
                          selected: _selectedFilter == label,
                          label: Text(label),
                          onSelected: (_) =>
                              setState(() => _selectedFilter = label),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 18),
                  _InsightStrip(
                    liveCount: fallbackLiveCount,
                    upcomingCount: fallbackUpcomingCount,
                    completedCount: fallbackCompletedCount,
                  ),
                  const SizedBox(height: 24),
                  EmptyState(
                    icon: Icons.filter_alt_off_outlined,
                    title: 'No events for "$_selectedFilter"',
                    message:
                        'Try another filter or switch back to All to browse the rest of campus events.',
                  ),
                ],
              );
            }

            final featuredPool = filtered
                .where((item) => item.isFeatured)
                .toList();
            final streamReady = filtered
                .where(
                  (item) =>
                      item.status == CampusEventStatus.live ||
                      (item.streamUrl != null && item.streamUrl!.isNotEmpty),
                )
                .take(6)
                .toList();
            final heroEvent = featuredPool.isNotEmpty
                ? featuredPool.first
                : filtered.firstWhere(
                    (item) =>
                        item.status == CampusEventStatus.live ||
                        item.status == CampusEventStatus.upcoming,
                    orElse: () => filtered.first,
                  );

            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              children: [
                _LiveHeroCard(
                      event: heroEvent,
                      totalCount: filtered.length,
                      liveCount: live.length,
                      scheme: scheme,
                    )
                    .animate()
                    .fadeIn(duration: 320.ms)
                    .slideY(begin: 0.05, end: 0),
                const SizedBox(height: 18),
                SizedBox(
                  height: 40,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _filters.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final label = _filters[index];
                      return ChoiceChip(
                        selected: _selectedFilter == label,
                        label: Text(label),
                        onSelected: (_) =>
                            setState(() => _selectedFilter = label),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 18),
                _InsightStrip(
                  liveCount: live.length,
                  upcomingCount: upcoming.length,
                  completedCount: completed.length,
                ),
                const SizedBox(height: 18),
                _StreamLounge(
                  items: streamReady.isNotEmpty
                      ? streamReady
                      : featuredPool.take(4).toList(),
                ),
                const SizedBox(height: 18),
                _EventSection(
                  title: 'Happening now',
                  subtitle:
                      'Join active campus sessions and livestreams quickly.',
                  items: live,
                ),
                const SizedBox(height: 18),
                _EventSection(
                  title: 'Upcoming',
                  subtitle: 'The next events students should notice this week.',
                  items: upcoming,
                ),
                const SizedBox(height: 18),
                _EventSection(
                  title: 'Past highlights',
                  subtitle: 'Recently completed sessions and showcases.',
                  items: completed.take(4).toList(),
                  compact: true,
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  bool _matchesFilter(CampusEvent event) {
    final start = event.startTime;
    final now = DateTime.now();

    switch (_selectedFilter) {
      case 'All':
        return true;
      case 'Live':
        return event.status == CampusEventStatus.live;
      case 'Today':
        return start != null &&
            start.year == now.year &&
            start.month == now.month &&
            start.day == now.day;
      case 'This week':
        if (start == null) return false;
        return start.isAfter(now.subtract(const Duration(days: 1))) &&
            start.isBefore(now.add(const Duration(days: 7)));
      case 'Featured':
        return event.isFeatured;
      default:
        return event.category.toLowerCase() == _selectedFilter.toLowerCase();
    }
  }
}

class _LiveHeroCard extends StatelessWidget {
  const _LiveHeroCard({
    required this.event,
    required this.totalCount,
    required this.liveCount,
    required this.scheme,
  });

  final CampusEvent event;
  final int totalCount;
  final int liveCount;
  final ColorScheme scheme;

  Future<void> _openStream() async {
    final url = event.streamUrl;
    if (url == null || url.isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: SizedBox(
        height: 216,
        child: Stack(
          children: [
            Positioned.fill(child: _EventImage(event: event)),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withValues(alpha: 0.22),
                      scheme.primary.withValues(alpha: 0.36),
                      Colors.black.withValues(alpha: 0.78),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _GlassBadge(
                        label: event.status == CampusEventStatus.live
                            ? 'Live now'
                            : event.isFeatured
                            ? 'Featured'
                            : 'Next big event',
                        icon: event.status == CampusEventStatus.live
                            ? Icons.podcasts
                            : Icons.auto_awesome,
                        pulse: event.status == CampusEventStatus.live,
                      ),
                      _GlassBadge(
                        label: event.category,
                        icon: Icons.sell_outlined,
                      ),
                      _GlassBadge(label: '$liveCount live', icon: Icons.bolt),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    'Campus energy, all in one place',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Colors.white.withValues(alpha: 0.92),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    event.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(
                      context,
                    ).textTheme.headlineMedium?.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    event.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.92),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _Pill(
                        label: _dateLabel(event, short: false),
                        icon: Icons.schedule,
                        maxWidth: 150,
                      ),
                      _Pill(
                        label: event.location,
                        icon: Icons.location_on_outlined,
                        maxWidth: 180,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed:
                              event.streamUrl == null ||
                                  event.streamUrl!.isEmpty
                              ? null
                              : _openStream,
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(0, 42),
                          ),
                          icon: Icon(
                            event.status == CampusEventStatus.live
                                ? Icons.live_tv
                                : Icons.open_in_new,
                          ),
                          label: Text(
                            event.status == CampusEventStatus.live
                                ? 'Join now'
                                : 'Open stream',
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      IconButton.filledTonal(
                        onPressed: () {},
                        icon: const Icon(Icons.notifications_active_outlined),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InsightStrip extends StatelessWidget {
  const _InsightStrip({
    required this.liveCount,
    required this.upcomingCount,
    required this.completedCount,
  });

  final int liveCount;
  final int upcomingCount;
  final int completedCount;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: _InsightCard(
            icon: Icons.radio_button_checked,
            label: 'Live',
            value: '$liveCount',
            color: const Color(0xFFEF4444),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _InsightCard(
            icon: Icons.upcoming,
            label: 'Upcoming',
            value: '$upcomingCount',
            color: scheme.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _InsightCard(
            icon: Icons.celebration_outlined,
            label: 'Completed',
            value: '$completedCount',
            color: scheme.tertiary,
          ),
        ),
      ],
    );
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: color.withValues(alpha: 0.14),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 10),
            Text(value, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _StreamLounge extends StatelessWidget {
  const _StreamLounge({required this.items});

  final List<CampusEvent> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Campus stream lounge'),
        const SizedBox(height: 4),
        Text(
          'A live-style showcase for sessions, premieres, and moments happening around campus.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 210,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) =>
                SizedBox(width: 240, child: _StreamCard(event: items[index])),
          ),
        ),
      ],
    );
  }
}

class _EventImage extends StatelessWidget {
  const _EventImage({required this.event});

  final CampusEvent event;

  @override
  Widget build(BuildContext context) {
    final imageUrl = event.imageUrl;
    if (imageUrl == null || imageUrl.isEmpty) {
      return Image.asset(
        'assets/images/vu_default_card.png',
        fit: BoxFit.cover,
      );
    }
    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: BoxFit.cover,
      errorWidget: (_, _, _) =>
          Image.asset('assets/images/vu_default_card.png', fit: BoxFit.cover),
    );
  }
}

class _EventSection extends StatelessWidget {
  const _EventSection({
    required this.title,
    required this.subtitle,
    required this.items,
    this.compact = false,
  });

  final String title;
  final String subtitle;
  final List<CampusEvent> items;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: title),
        const SizedBox(height: 4),
        Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 12),
        if (items.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              color: Theme.of(context).colorScheme.surfaceContainer,
              border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.12),
                  child: Icon(
                    Icons.event_busy_outlined,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'No events in this state right now.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          )
        else
          ...items.map(
            (event) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: compact
                  ? _CompactEventTile(event: event)
                  : _EventTile(event: event),
            ).animate().fadeIn(duration: 240.ms).slideY(begin: 0.04, end: 0),
          ),
      ],
    );
  }
}

class _EventTile extends StatelessWidget {
  const _EventTile({required this.event});

  final CampusEvent event;

  Future<void> _openStream() async {
    final url = event.streamUrl;
    if (url == null || url.isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final label = switch (event.status) {
      CampusEventStatus.live => 'Live now',
      CampusEventStatus.completed => 'Completed',
      CampusEventStatus.upcoming => 'Upcoming',
    };

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              SizedBox(
                height: 176,
                width: double.infinity,
                child: _EventImage(event: event),
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withValues(alpha: 0.04),
                        Colors.black.withValues(alpha: 0.0),
                        Colors.black.withValues(alpha: 0.46),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 14,
                top: 14,
                child: _GlassBadge(
                  label: label,
                  icon: event.status == CampusEventStatus.live
                      ? Icons.podcasts
                      : Icons.schedule,
                  pulse: event.status == CampusEventStatus.live,
                ),
              ),
              Positioned(
                right: 14,
                top: 14,
                child: _GlassBadge(
                  label: event.category,
                  icon: Icons.sell_outlined,
                ),
              ),
              Positioned(
                left: 14,
                right: 14,
                bottom: 14,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        event.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(
                          context,
                        ).textTheme.titleLarge?.copyWith(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                    _SoftMetaPill(
                      icon: Icons.schedule,
                      label: _dateLabel(event, short: true),
                      maxWidth: 150,
                    ),
                    _SoftMetaPill(
                      icon: Icons.place_outlined,
                      label: event.location,
                      maxWidth: 210,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed:
                            event.streamUrl == null || event.streamUrl!.isEmpty
                            ? null
                            : _openStream,
                        icon: Icon(
                          event.status == CampusEventStatus.live
                              ? Icons.live_tv
                              : Icons.open_in_new,
                        ),
                        label: Text(
                          event.status == CampusEventStatus.live
                              ? 'Join now'
                              : 'Open stream',
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    IconButton.filledTonal(
                      onPressed: () {},
                      icon: const Icon(Icons.notifications_active_outlined),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CompactEventTile extends StatelessWidget {
  const _CompactEventTile({required this.event});

  final CampusEvent event;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: SizedBox(
                width: 72,
                height: 86,
                child: _EventImage(event: event),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    event.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 10),
                  _SoftMetaPill(
                    icon: Icons.schedule,
                    label: _dateLabel(event, short: true),
                    maxWidth: 140,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StreamCard extends StatelessWidget {
  const _StreamCard({required this.event});

  final CampusEvent event;

  Future<void> _openStream() async {
    final url = event.streamUrl;
    if (url == null || url.isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final live = event.status == CampusEventStatus.live;
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: Stack(
        children: [
          Positioned.fill(child: _EventImage(event: event)),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withValues(alpha: 0.18),
                    scheme.primary.withValues(alpha: 0.22),
                    Colors.black.withValues(alpha: 0.74),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _GlassBadge(
                  label: live ? 'Streaming' : 'Showcase',
                  icon: live ? Icons.podcasts : Icons.live_tv_outlined,
                  pulse: live,
                ),
                const Spacer(),
                Text(
                  event.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 6),
                Text(
                  event.location,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.84),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed:
                        event.streamUrl == null || event.streamUrl!.isEmpty
                        ? null
                        : _openStream,
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: scheme.primary,
                    ),
                    icon: Icon(
                      live ? Icons.play_arrow_rounded : Icons.open_in_new,
                    ),
                    label: Text(live ? 'Watch now' : 'Preview stream'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.icon, this.maxWidth = 180});

  final String label;
  final IconData icon;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: Colors.white.withValues(alpha: 0.14),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: Colors.white),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SoftMetaPill extends StatelessWidget {
  const _SoftMetaPill({
    required this.icon,
    required this.label,
    this.maxWidth = 180,
  });

  final IconData icon;
  final String label;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: scheme.surfaceContainerHighest,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: scheme.primary),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlassBadge extends StatelessWidget {
  const _GlassBadge({
    required this.label,
    required this.icon,
    this.pulse = false,
  });

  final String label;
  final IconData icon;
  final bool pulse;

  @override
  Widget build(BuildContext context) {
    final badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 8),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(color: Colors.white),
          ),
        ],
      ),
    );

    if (!pulse) return badge;
    return badge
        .animate(onPlay: (controller) => controller.repeat(reverse: true))
        .fade(begin: 0.82, end: 1);
  }
}

String _dateLabel(CampusEvent event, {required bool short}) {
  final start = event.startTime;
  if (start == null) return 'Date TBC';

  final now = DateTime.now();
  final sameDay =
      start.year == now.year &&
      start.month == now.month &&
      start.day == now.day;
  if (sameDay) {
    final diff = start.difference(now);
    if (diff.inMinutes > 0 && diff.inHours < 12) {
      final hours = diff.inHours;
      final minutes = diff.inMinutes.remainder(60);
      if (hours > 0) {
        return 'Starts in ${hours}h ${minutes}m';
      }
      return 'Starts in ${diff.inMinutes}m';
    }
    return short
        ? 'Today • ${DateFormat('HH:mm').format(start)}'
        : 'Today at ${DateFormat('HH:mm').format(start)}';
  }
  return short
      ? DateFormat('MMM d • HH:mm').format(start)
      : DateFormat('EEE, MMM d • HH:mm').format(start);
}
