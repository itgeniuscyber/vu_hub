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

class VuLiveScreen extends StatelessWidget {
  const VuLiveScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('VU Live')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: StreamBuilder<List<CampusEvent>>(
            stream: EventsRepository().watchEvents(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return ListView(
                  children: const [
                    LoadingShimmer(height: 154),
                    SizedBox(height: 12),
                    LoadingShimmer(height: 132),
                    SizedBox(height: 12),
                    LoadingShimmer(height: 132),
                  ],
                );
              }
              if (snapshot.hasError) {
                return FirestoreErrorState(
                  error: snapshot.error!,
                  icon: Icons.live_tv_outlined,
                  title: 'Events unavailable',
                  fallbackMessage:
                      'Campus events could not be loaded right now.',
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

              final featured = events.where((item) => item.isFeatured).toList();
              final upcoming = events
                  .where((item) => item.status == CampusEventStatus.upcoming)
                  .toList();
              final live = events
                  .where((item) => item.status == CampusEventStatus.live)
                  .toList();
              final completed = events
                  .where((item) => item.status == CampusEventStatus.completed)
                  .toList();

              return ListView(
                children: [
                  if (featured.isNotEmpty)
                    _FeaturedEventCard(event: featured.first),
                  if (featured.isNotEmpty) const SizedBox(height: 20),
                  _EventSection(title: 'Happening now', items: live),
                  const SizedBox(height: 16),
                  _EventSection(title: 'Upcoming', items: upcoming),
                  const SizedBox(height: 16),
                  _EventSection(
                    title: 'Completed',
                    items: completed.take(3).toList(),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _FeaturedEventCard extends StatelessWidget {
  const _FeaturedEventCard({required this.event});

  final CampusEvent event;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final start = event.startTime;
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Stack(
        children: [
          Positioned.fill(child: _EventImage(event: event)),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withValues(alpha: 0.68),
                    scheme.primary.withValues(alpha: 0.42),
                  ],
                  begin: Alignment.bottomLeft,
                  end: Alignment.topRight,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Chip(label: Text('Featured')),
                    const Spacer(),
                    Icon(
                      Icons.podcasts,
                      color: Colors.white.withValues(alpha: 0.92),
                    ),
                  ],
                ),
                const SizedBox(height: 44),
                Text(
                  event.title,
                  style: Theme.of(
                    context,
                  ).textTheme.headlineMedium?.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 8),
                Text(
                  event.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _Pill(
                      label: event.location,
                      icon: Icons.location_on_outlined,
                    ),
                    _Pill(
                      label: start == null
                          ? 'Date TBC'
                          : DateFormat('EEE, MMM d • HH:mm').format(start),
                      icon: Icons.schedule,
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
  const _EventSection({required this.title, required this.items});

  final String title;
  final List<CampusEvent> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: title),
        const SizedBox(height: 12),
        if (items.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'No events in this state right now.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          )
        else
          ...items.map(
            (event) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _EventTile(
                event: event,
              ).animate().fadeIn(duration: 240.ms).slideY(begin: 0.04, end: 0),
            ),
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
    final scheme = Theme.of(context).colorScheme;
    final start = event.startTime;
    final statusColor = switch (event.status) {
      CampusEventStatus.live => const Color(0xFFEF4444),
      CampusEventStatus.completed => scheme.outline,
      CampusEventStatus.upcoming => scheme.primary,
    };
    final label = switch (event.status) {
      CampusEventStatus.live => 'Live now',
      CampusEventStatus.completed => 'Completed',
      CampusEventStatus.upcoming => 'Upcoming',
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 92,
                height: 108,
                child: _EventImage(event: event),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Chip(
                        avatar: Icon(
                          Icons.circle,
                          color: statusColor,
                          size: 12,
                        ),
                        label: Text(label),
                      ),
                      const Spacer(),
                      Text(
                        event.category,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    event.title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    event.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Chip(
                        avatar: const Icon(Icons.schedule, size: 16),
                        label: Text(
                          start == null
                              ? 'Date TBC'
                              : DateFormat('MMM d • HH:mm').format(start),
                        ),
                      ),
                      Chip(
                        avatar: const Icon(Icons.place_outlined, size: 16),
                        label: Text(event.location),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      FilledButton.icon(
                        onPressed:
                            event.streamUrl == null || event.streamUrl!.isEmpty
                            ? null
                            : _openStream,
                        icon: const Icon(Icons.open_in_new),
                        label: const Text('Open stream'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.notifications_active_outlined),
                        label: const Text('Remind me'),
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

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
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
          Text(label, style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }
}
