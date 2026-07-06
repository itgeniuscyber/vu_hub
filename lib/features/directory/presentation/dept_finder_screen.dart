import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/feature_hero_banner.dart';
import '../../../core/widgets/firestore_error_state.dart';
import '../../../core/widgets/loading_shimmer.dart';
import '../../../core/widgets/section_header.dart';
import '../data/directory_models.dart';
import '../data/directory_repository.dart';

class DeptFinderScreen extends StatefulWidget {
  const DeptFinderScreen({super.key});

  @override
  State<DeptFinderScreen> createState() => _DeptFinderScreenState();
}

class _DeptFinderScreenState extends State<DeptFinderScreen> {
  final _searchController = TextEditingController();
  late final Stream<List<DirectoryEntry>> _entriesStream;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _entriesStream = DirectoryRepository().watchEntries();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FeatureHeroBanner(
                title: 'Dept Finder',
                subtitle:
                    'Search departments, offices, lecturers, and support staff without leaving the app.',
                icon: Icons.location_city_outlined,
                scheme: scheme,
                badge: 'Campus routing',
                height: 188,
              ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.05, end: 0),
              const SizedBox(height: 18),
              SizedBox(
                height: 108,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: const [
                    _DirectoryMetricCard(
                      icon: Icons.support_agent_outlined,
                      title: 'Support offices',
                      subtitle: 'Registry, ICT, Finance',
                      width: 194,
                    ),
                    SizedBox(width: 12),
                    _DirectoryMetricCard(
                      icon: Icons.school_outlined,
                      title: 'Academic contacts',
                      subtitle: 'Lecturers and departments',
                      width: 218,
                    ),
                    SizedBox(width: 12),
                    _DirectoryMetricCard(
                      icon: Icons.route_outlined,
                      title: 'Quick routing',
                      subtitle: 'Search by role or keyword',
                      width: 188,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              _FinderHero(scheme: scheme),
              const SizedBox(height: 18),
              const SectionHeader(title: 'Find the right office faster'),
              const SizedBox(height: 8),
              Text(
                'Search departments, lecturers, offices, and support staff. If the collection is empty, VU Hub falls back to a safe seeded directory.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              _DirectorySearchBar(
                controller: _searchController,
                query: _query,
                onChanged: (value) =>
                    setState(() => _query = value.trim().toLowerCase()),
                onClear: () {
                  _searchController.clear();
                  setState(() => _query = '');
                },
              ),
              const SizedBox(height: 16),
              Expanded(
                child: StreamBuilder<List<DirectoryEntry>>(
                  stream: _entriesStream,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return ListView(
                        children: const [
                          LoadingShimmer(height: 120),
                          SizedBox(height: 12),
                          LoadingShimmer(height: 120),
                          SizedBox(height: 12),
                          LoadingShimmer(height: 120),
                        ],
                      );
                    }
                    if (snapshot.hasError) {
                      return FirestoreErrorState(
                        error: snapshot.error!,
                        icon: Icons.location_city_outlined,
                        title: 'Directory unavailable',
                        fallbackMessage:
                            'Departments and office contacts could not be loaded.',
                      );
                    }
                    final items = (snapshot.data ?? [])
                        .where(_matches)
                        .toList();
                    final totalItems = (snapshot.data ?? []).length;
                    if (items.isEmpty) {
                      return const EmptyState(
                        icon: Icons.search_off,
                        title: 'No matching departments',
                        message:
                            'Try a broader search like finance, support, registry, or ICT.',
                      );
                    }
                    return Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '${items.length} result${items.length == 1 ? '' : 's'} found',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ),
                              if (_query.isNotEmpty)
                                Text(
                                  'from $totalItems contacts',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: ListView.separated(
                            itemCount: items.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) =>
                                _DirectoryCard(entry: items[index])
                                    .animate()
                                    .fadeIn(duration: 260.ms)
                                    .slideY(begin: 0.05, end: 0),
                          ),
                        ),
                      ],
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

  bool _matches(DirectoryEntry entry) {
    if (_query.isEmpty) return true;
    final haystack = [
      entry.name,
      entry.department,
      entry.role,
      entry.email,
      entry.phone,
      entry.location,
      ...entry.keywords,
    ].join(' ').toLowerCase();
    return haystack.contains(_query);
  }
}

class _FinderHero extends StatelessWidget {
  const _FinderHero({required this.scheme});

  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [
            scheme.primary.withValues(alpha: 0.12),
            scheme.secondary.withValues(alpha: 0.06),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.6)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: scheme.primary.withValues(alpha: 0.14),
            child: Icon(Icons.hub_outlined, color: scheme.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Smart routing for student support',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  'Use this when AI Desk points a student to Registry, Finance, ICT, or Student Support.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _RoutingTag(
                      icon: Icons.account_balance_outlined,
                      label: 'Registry',
                      tone: scheme.primary,
                    ),
                    _RoutingTag(
                      icon: Icons.payments_outlined,
                      label: 'Finance',
                      tone: scheme.secondary,
                    ),
                    _RoutingTag(
                      icon: Icons.memory_outlined,
                      label: 'ICT',
                      tone: scheme.tertiary,
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

class _DirectoryMetricCard extends StatelessWidget {
  const _DirectoryMetricCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.width,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final double width;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: width,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: scheme.primary),
              const Spacer(),
              Text(title, style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 4),
              Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}

class _DirectorySearchBar extends StatelessWidget {
  const _DirectorySearchBar({
    required this.controller,
    required this.query,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final String query;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [
            scheme.surface.withValues(alpha: 0.96),
            scheme.surfaceContainerHighest.withValues(alpha: 0.94),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: 'Search by office, role, keyword, or email',
          prefixIcon: Icon(Icons.search, color: scheme.primary),
          suffixIcon: query.isEmpty
              ? Icon(
                  Icons.travel_explore_outlined,
                  color: scheme.onSurfaceVariant,
                )
              : IconButton(
                  onPressed: onClear,
                  icon: Icon(Icons.close_rounded, color: scheme.primary),
                ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide(
              color: scheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide(color: scheme.primary, width: 1.2),
          ),
        ),
      ),
    );
  }
}

class _RoutingTag extends StatelessWidget {
  const _RoutingTag({
    required this.icon,
    required this.label,
    required this.tone,
  });

  final IconData icon;
  final String label;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: tone.withValues(alpha: 0.1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: tone),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(color: tone),
          ),
        ],
      ),
    );
  }
}

class _DirectoryCard extends StatelessWidget {
  const _DirectoryCard({required this.entry});

  final DirectoryEntry entry;

  Future<void> _launch(Uri uri) async {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

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
                CircleAvatar(
                  backgroundColor: scheme.secondary.withValues(alpha: 0.14),
                  child: Icon(Icons.apartment, color: scheme.secondary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${entry.department} • ${entry.role}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    color: scheme.surfaceContainerHighest,
                  ),
                  child: Text(
                    'Contact',
                    style: Theme.of(
                      context,
                    ).textTheme.labelMedium?.copyWith(color: scheme.primary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(
                  avatar: const Icon(Icons.location_on_outlined, size: 16),
                  label: Text(entry.location),
                ),
                ...entry.keywords
                    .take(2)
                    .map((word) => Chip(label: Text(word))),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                if (entry.email.isNotEmpty)
                  FilledButton.icon(
                    onPressed: () =>
                        _launch(Uri.parse('mailto:${entry.email}')),
                    icon: const Icon(Icons.mail_outline),
                    label: const Text('Email'),
                  ),
                if (entry.phone.isNotEmpty)
                  OutlinedButton.icon(
                    onPressed: () => _launch(Uri.parse('tel:${entry.phone}')),
                    icon: const Icon(Icons.call_outlined),
                    label: const Text('Call'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
