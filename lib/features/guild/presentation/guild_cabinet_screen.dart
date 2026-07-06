import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/widgets/feature_hero_banner.dart';
import '../../../core/widgets/section_header.dart';
import '../data/guild_models.dart';

class GuildCabinetScreen extends StatelessWidget {
  const GuildCabinetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
          children: [
            FeatureHeroBanner(
              title: 'Guild Cabinet',
              subtitle:
                  'Explore the guild office in a clearer hierarchy so students know which leaders handle representation, welfare, academics, and communication.',
              icon: Icons.account_tree_outlined,
              scheme: scheme,
              badge: 'Leadership structure',
              height: 188,
            ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.05, end: 0),
            const SizedBox(height: 20),
            _GuildCabinetSpotlight(member: _guildCabinet.first),
            const SizedBox(height: 18),
            const SectionHeader(title: 'Office structure'),
            const SizedBox(height: 8),
            Text(
              'The cabinet is grouped by leadership level and support portfolio so students can quickly understand where to raise the right issue.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            ..._guildCabinetGroups.map(
              (group) => Padding(
                padding: const EdgeInsets.only(bottom: 18),
                child: _GuildCabinetGroup(
                  title: group.title,
                  subtitle: group.subtitle,
                  members: group.members,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GuildCabinetSpotlight extends StatelessWidget {
  const _GuildCabinetSpotlight({required this.member});

  final GuildCabinetMember member;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final icon = IconData(member.iconCodePoint, fontFamily: 'MaterialIcons');
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          colors: [
            scheme.primary.withValues(alpha: 0.94),
            scheme.secondary.withValues(alpha: 0.82),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: 0.18),
            blurRadius: 20,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Colors.white.withValues(alpha: 0.16),
            ),
            child: Icon(icon, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    color: Colors.white.withValues(alpha: 0.16),
                  ),
                  child: Text(
                    'Executive lead',
                    style: Theme.of(
                      context,
                    ).textTheme.labelLarge?.copyWith(color: Colors.white),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  member.role,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  member.name ?? 'Office holder profile can be updated here',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.94),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  member.scope,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _GuildPill(
                      icon: Icons.apartment_outlined,
                      label: member.office,
                      dark: true,
                    ),
                    _GuildPill(
                      icon: Icons.contact_support_outlined,
                      label: member.contactHint,
                      dark: true,
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

class _GuildCabinetGroup extends StatelessWidget {
  const _GuildCabinetGroup({
    required this.title,
    required this.subtitle,
    required this.members,
  });

  final String title;
  final String subtitle;
  final List<GuildCabinetMember> members;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 4),
        Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 720;
            final cardWidth = compact
                ? constraints.maxWidth
                : (constraints.maxWidth - 12) / 2;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: members
                  .map(
                    (member) => SizedBox(
                      width: cardWidth,
                      child: _GuildCabinetMemberCard(member: member),
                    ),
                  )
                  .toList(),
            );
          },
        ),
      ],
    );
  }
}

class _GuildCabinetMemberCard extends StatelessWidget {
  const _GuildCabinetMemberCard({required this.member});

  final GuildCabinetMember member;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final icon = IconData(member.iconCodePoint, fontFamily: 'MaterialIcons');
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: scheme.primary.withValues(alpha: 0.1),
                  ),
                  child: Icon(icon, color: scheme.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        member.role,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        member.name ?? 'Office bearer update pending',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(member.scope, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _GuildPill(icon: Icons.badge_outlined, label: member.office),
                _GuildPill(
                  icon: Icons.route_outlined,
                  label: member.contactHint,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _GuildPill extends StatelessWidget {
  const _GuildPill({
    required this.icon,
    required this.label,
    this.dark = false,
  });

  final IconData icon;
  final String label;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final background = dark
        ? Colors.white.withValues(alpha: 0.14)
        : scheme.surfaceContainerHighest;
    final foreground = dark ? Colors.white : scheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: background,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: foreground),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(color: foreground),
          ),
        ],
      ),
    );
  }
}

class _GuildCabinetGroupData {
  const _GuildCabinetGroupData({
    required this.title,
    required this.subtitle,
    required this.members,
  });

  final String title;
  final String subtitle;
  final List<GuildCabinetMember> members;
}

final _guildCabinet = [
  GuildCabinetMember(
    role: 'Guild President',
    office: 'Executive office',
    scope:
        'Leads the guild cabinet, represents students in top-level engagements, and coordinates the overall student agenda.',
    contactHint: 'Policy, urgent representation, executive direction',
    iconCodePoint: 0xe491,
    isExecutive: true,
  ),
  GuildCabinetMember(
    role: 'Vice President',
    office: 'Deputy executive office',
    scope:
        'Supports cabinet leadership, follows up strategic actions, and keeps cross-portfolio work moving.',
    contactHint: 'Escalations, coordination, cabinet follow-up',
    iconCodePoint: 0xe7ef,
    isExecutive: true,
  ),
  GuildCabinetMember(
    role: 'General Secretary',
    office: 'Administration and records',
    scope:
        'Manages cabinet records, formal communication, meeting flow, and internal office documentation.',
    contactHint: 'Records, minutes, formal notices',
    iconCodePoint: 0xe24d,
  ),
  GuildCabinetMember(
    role: 'Finance Secretary',
    office: 'Finance and accountability',
    scope:
        'Handles guild finance coordination, accountability topics, and questions around student-facing funding matters.',
    contactHint: 'Budget issues, accountability, finance concerns',
    iconCodePoint: 0xe57d,
  ),
  GuildCabinetMember(
    role: 'Academic Affairs Secretary',
    office: 'Academic welfare desk',
    scope:
        'Handles teaching, timetable, assessment, and classroom-related student concerns across faculties.',
    contactHint: 'Lectures, timetable, coursework, exams',
    iconCodePoint: 0xe80c,
  ),
  GuildCabinetMember(
    role: 'Minister of Welfare',
    office: 'Student welfare office',
    scope:
        'Supports student wellbeing matters including accommodation, social welfare, and student support advocacy.',
    contactHint: 'Welfare, accommodation, wellbeing support',
    iconCodePoint: 0xe7f3,
  ),
  GuildCabinetMember(
    role: 'Minister of Sports and Culture',
    office: 'Activities and student life',
    scope:
        'Coordinates student life initiatives, talent, clubs, sports, and culture-led campus engagement.',
    contactHint: 'Events, sports, clubs, talent support',
    iconCodePoint: 0xe4dc,
  ),
  GuildCabinetMember(
    role: 'Publicity Secretary',
    office: 'Media and communication',
    scope:
        'Handles announcements, awareness campaigns, and communication that keeps students informed.',
    contactHint: 'Campaigns, publicity, student communication',
    iconCodePoint: 0xe0e1,
  ),
];

final _guildCabinetGroups = [
  _GuildCabinetGroupData(
    title: 'Executive Office',
    subtitle: 'Core leadership and cabinet coordination.',
    members: [_guildCabinet[1], _guildCabinet[2], _guildCabinet[3]],
  ),
  _GuildCabinetGroupData(
    title: 'Student Support Portfolios',
    subtitle:
        'Offices students can approach for academics, welfare, and campus life.',
    members: [
      _guildCabinet[4],
      _guildCabinet[5],
      _guildCabinet[6],
      _guildCabinet[7],
    ],
  ),
];
