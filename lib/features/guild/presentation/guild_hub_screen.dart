import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/utils/app_page_route.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/feature_hero_banner.dart';
import '../../../core/widgets/firestore_error_state.dart';
import '../../../core/widgets/loading_shimmer.dart';
import '../../../core/widgets/section_header.dart';
import '../../directory/data/vu_resource.dart';
import '../../directory/data/vu_resource_repository.dart';
import '../data/guild_models.dart';
import 'guild_cabinet_screen.dart';

class GuildHubScreen extends StatelessWidget {
  const GuildHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
          children: [
            FeatureHeroBanner(
              title: 'Guild Hub',
              subtitle:
                  'Track verified student representation updates, common campus concerns, and the feedback themes that matter most.',
              icon: Icons.groups_outlined,
              scheme: scheme,
              badge: 'Verified voice',
              height: 220,
            ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.05, end: 0),
            const SizedBox(height: 20),
            SizedBox(
              height: 144,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _GuildMetricCard(
                    icon: Icons.verified_outlined,
                    title: 'Trusted notices',
                    subtitle: 'Curated from verified resource flows',
                    width: 210,
                    gradientColors: [scheme.primary, scheme.secondary],
                  ),
                  const SizedBox(width: 12),
                  _GuildMetricCard(
                    icon: Icons.campaign_outlined,
                    title: 'Student feedback',
                    subtitle: 'Grouped into moderation-ready themes',
                    width: 224,
                    gradientColors: [scheme.secondary, scheme.tertiary],
                  ),
                  const SizedBox(width: 12),
                  _GuildMetricCard(
                    icon: Icons.account_tree_outlined,
                    title: 'Cabinet structure',
                    subtitle: 'View leadership in a dedicated screen',
                    width: 224,
                    gradientColors: [scheme.tertiary, scheme.primary],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const SectionHeader(title: 'Guild cabinet'),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                color: scheme.surfaceContainerHigh.withValues(alpha: 0.6),
                border: Border.all(
                  color: scheme.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: scheme.primary.withValues(alpha: 0.12),
                          border: Border.all(
                            color: scheme.primary.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Icon(
                          Icons.account_tree_outlined,
                          color: scheme.primary,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Guild Cabinet Structure',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Explore the executive hierarchy, cabinet offices, and student-facing portfolios.',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                    height: 1.3,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: const [
                      _GuildPreviewPill(label: 'Executive office'),
                      _GuildPreviewPill(label: 'Academic affairs'),
                      _GuildPreviewPill(label: 'Student welfare'),
                      _GuildPreviewPill(label: 'Media & publicity'),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () => Navigator.of(
                        context,
                      ).push(buildAppPageRoute(const GuildCabinetScreen())),
                      icon: const Icon(Icons.arrow_forward_rounded, size: 20),
                      label: const Text('View full cabinet'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
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
              children: [
                _GuildCategoryChip(label: 'Wi-Fi', tone: scheme.primary),
                _GuildCategoryChip(label: 'Timetable', tone: scheme.secondary),
                _GuildCategoryChip(label: 'Tuition', tone: scheme.tertiary),
                _GuildCategoryChip(label: 'Exams', tone: scheme.primary),
                _GuildCategoryChip(label: 'Security', tone: scheme.secondary),
                _GuildCategoryChip(label: 'Facilities', tone: scheme.tertiary),
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
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: () {},
                            icon: const Icon(Icons.rate_review_outlined),
                            label: const Text('Open feedback form'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {},
                            icon: const Icon(Icons.shield_outlined),
                            label: const Text('Review themes'),
                          ),
                        ),
                      ],
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
                child: _GuildInsightCard(insight: insight),
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

class _GuildMetricCard extends StatelessWidget {
  const _GuildMetricCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.width,
    required this.gradientColors,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final double width;
  final List<Color> gradientColors;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              colors: [
                gradientColors[0].withValues(alpha: 0.12),
                gradientColors[1].withValues(alpha: 0.04),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: gradientColors[0].withValues(alpha: 0.2),
                radius: 18,
                child: Icon(icon, color: gradientColors[0], size: 20),
              ),
              const Spacer(),
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GuildCategoryChip extends StatelessWidget {
  const _GuildCategoryChip({required this.label, required this.tone});

  final String label;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: tone.withValues(alpha: 0.1),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(color: tone),
      ),
    );
  }
}

class _GuildPreviewPill extends StatelessWidget {
  const _GuildPreviewPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: scheme.surfaceContainerHighest,
      ),
      child: Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.labelLarge?.copyWith(color: scheme.primary),
      ),
    );
  }
}

class _GuildInsightCard extends StatelessWidget {
  const _GuildInsightCard({required this.insight});

  final FeedbackInsight insight;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: scheme.primary.withValues(alpha: 0.12),
              child: Text(
                '${insight.count}',
                style: TextStyle(
                  color: scheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    insight.label,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    insight.description,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Icon(Icons.insights_outlined, color: scheme.primary),
          ],
        ),
      ),
    );
  }
}

class _GuildUpdateCard extends StatelessWidget {
  const _GuildUpdateCard({required this.update});

  final GuildUpdate update;

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
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    color: scheme.primary.withValues(alpha: 0.1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.verified, size: 14, color: scheme.primary),
                      const SizedBox(width: 6),
                      Text(
                        update.category,
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(color: scheme.primary),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                if (update.isVerified)
                  Icon(
                    Icons.verified_user_outlined,
                    size: 18,
                    color: scheme.secondary,
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(update.title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(update.body, maxLines: 3, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 14),
            Row(
              children: [
                Icon(Icons.campaign_outlined, size: 18, color: scheme.primary),
                const SizedBox(width: 6),
                Text(
                  'Verified update',
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(color: scheme.primary),
                ),
              ],
            ),
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
