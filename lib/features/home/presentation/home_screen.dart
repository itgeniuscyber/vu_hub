import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/widgets/metric_card.dart';
import '../../../core/widgets/section_header.dart';

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
                    childAspectRatio: 0.88,
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
                  _CampusPulseCard(scheme: scheme),
                ],
              ),
            ),
          ],
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
        borderRadius: BorderRadius.circular(8),
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
            'Good evening, Muhammad',
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
        trailing: const Icon(Icons.chevron_right),
      ),
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
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.insights, color: scheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Campus pulse',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'AI insights will summarize top student questions, resources, and guild feedback here.',
                    style: Theme.of(context).textTheme.bodyMedium,
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
