import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/section_header.dart';
import '../data/announcement.dart';
import '../data/announcement_repository.dart';

class FeedScreen extends StatelessWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionHeader(title: 'VU Feed'),
              const SizedBox(height: 8),
              Text(
                'Official notices, guild updates, and urgent campus communication.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              const _CategoryBar(),
              const SizedBox(height: 12),
              Expanded(
                child: StreamBuilder<List<Announcement>>(
                  stream: AnnouncementRepository().watchLatest(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError || (snapshot.data ?? []).isEmpty) {
                      return const EmptyState(
                        icon: Icons.campaign_outlined,
                        title: 'No official notices yet',
                        message:
                            'The Feed is ready. Add the announcements collection when admin publishing is built.',
                      );
                    }
                    final items = snapshot.data!;
                    return ListView.separated(
                      itemCount: items.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        return _AnnouncementCard(item: items[index])
                            .animate()
                            .fadeIn(duration: 300.ms)
                            .slideY(begin: 0.05, end: 0);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryBar extends StatelessWidget {
  const _CategoryBar();

  @override
  Widget build(BuildContext context) {
    const labels = ['All', 'Academic', 'Events', 'Guild', 'Urgent'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: labels
            .map(
              (label) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  selected: label == 'All',
                  label: Text(label),
                  onSelected: (_) {},
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _AnnouncementCard extends StatelessWidget {
  const _AnnouncementCard({required this.item});

  final Announcement item;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Chip(label: Text(item.category)),
                const Spacer(),
                if (item.isPinned) Icon(Icons.push_pin, color: scheme.primary),
              ],
            ),
            const SizedBox(height: 8),
            Text(item.title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(item.content, maxLines: 3, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.auto_awesome),
              label: const Text('Summarize'),
            ),
          ],
        ),
      ),
    );
  }
}
