import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/firestore_error_state.dart';
import '../../../core/widgets/loading_shimmer.dart';
import '../../../core/widgets/section_header.dart';
import '../../directory/data/vu_resource.dart';
import '../../directory/data/vu_resource_repository.dart';
import '../data/guild_models.dart';

class GuildHubScreen extends StatelessWidget {
  const GuildHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Guild Hub')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            _GuildHero(scheme: scheme),
            const SizedBox(height: 20),
            const SectionHeader(title: 'Verified updates'),
            const SizedBox(height: 12),
            StreamBuilder<List<VuResource>>(
              stream: VuResourceRepository().watchResources(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Column(
                    children: [
                      LoadingShimmer(height: 120),
                      SizedBox(height: 12),
                      LoadingShimmer(height: 120),
                    ],
                  );
                }
                if (snapshot.hasError) {
                  return FirestoreErrorState(
                    error: snapshot.error!,
                    icon: Icons.groups_outlined,
                    title: 'Guild feed unavailable',
                    fallbackMessage:
                        'Guild updates could not be loaded right now.',
                  );
                }
                final updates = _buildUpdates(snapshot.data ?? []);
                if (updates.isEmpty) {
                  return const EmptyState(
                    icon: Icons.groups_outlined,
                    title: 'No guild updates yet',
                    message:
                        'Verified guild notices will appear here when published.',
                  );
                }
                return Column(
                  children: updates
                      .take(3)
                      .map(
                        (update) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _GuildUpdateCard(update: update)
                              .animate()
                              .fadeIn(duration: 240.ms)
                              .slideX(begin: 0.04, end: 0),
                        ),
                      )
                      .toList(),
                );
              },
            ),
            const SizedBox(height: 8),
            const SectionHeader(title: 'Feedback categories'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: const [
                Chip(label: Text('Wi-Fi')),
                Chip(label: Text('Timetable')),
                Chip(label: Text('Tuition')),
                Chip(label: Text('Exams')),
                Chip(label: Text('Security')),
                Chip(label: Text('Facilities')),
              ],
            ),
            const SizedBox(height: 18),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Student feedback form',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'The feedback submission flow can connect to `guild_feedback` later. For now this screen surfaces moderation-ready categories and AI insight groupings.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 14),
                    FilledButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.rate_review_outlined),
                      label: const Text('Open feedback form'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            const SectionHeader(title: 'AI feedback insights'),
            const SizedBox(height: 12),
            ..._insights.map(
              (insight) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: CircleAvatar(child: Text('${insight.count}')),
                    title: Text(insight.label),
                    subtitle: Text(insight.description),
                    trailing: const Icon(Icons.insights_outlined),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<GuildUpdate> _buildUpdates(List<VuResource> resources) {
    final guildResources = resources.where((item) {
      final content = '${item.title} ${item.description} ${item.category}'
          .toLowerCase();
      return content.contains('guild') || content.contains('student');
    });
    return guildResources
        .map(
          (item) => GuildUpdate(
            title: item.title,
            body: item.description,
            category: item.category,
            isVerified: true,
          ),
        )
        .toList();
  }
}

class _GuildHero extends StatelessWidget {
  const _GuildHero({required this.scheme});

  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [scheme.primary, scheme.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.14),
            ),
            child: const Icon(Icons.verified, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Student guild, clearly verified',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  'Track trusted guild updates, structured feedback, and emerging student themes.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.88),
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

class _GuildUpdateCard extends StatelessWidget {
  const _GuildUpdateCard({required this.update});

  final GuildUpdate update;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Chip(
                  avatar: const Icon(Icons.verified, size: 16),
                  label: Text(update.category),
                ),
                const Spacer(),
                if (update.isVerified)
                  const Icon(Icons.verified_user_outlined, size: 18),
              ],
            ),
            const SizedBox(height: 10),
            Text(update.title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(update.body, maxLines: 3, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}

const _insights = [
  FeedbackInsight(
    label: 'Wi-Fi reliability',
    count: 14,
    description:
        'Most recent concerns focus on slow connectivity in lecture blocks and residence hotspots.',
  ),
  FeedbackInsight(
    label: 'Timetable clashes',
    count: 9,
    description:
        'Students are flagging overlapping tutorials and assessment deadlines across faculties.',
  ),
  FeedbackInsight(
    label: 'Facilities and security',
    count: 6,
    description:
        'Lighting, library seating, and evening movement around campus are recurring themes.',
  ),
];
