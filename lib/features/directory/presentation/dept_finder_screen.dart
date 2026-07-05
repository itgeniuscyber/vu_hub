import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/widgets/empty_state.dart';
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
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Dept Finder')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _FinderHero(scheme: scheme),
              const SizedBox(height: 18),
              const SectionHeader(title: 'Find the right office faster'),
              const SizedBox(height: 8),
              Text(
                'Search departments, lecturers, offices, and support staff. If the collection is empty, VU Hub falls back to a safe seeded directory.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              TextField(
                onChanged: (value) =>
                    setState(() => _query = value.trim().toLowerCase()),
                decoration: const InputDecoration(
                  hintText: 'Search by office, role, keyword, or email',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: StreamBuilder<List<DirectoryEntry>>(
                  stream: DirectoryRepository().watchEntries(),
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
                    if (items.isEmpty) {
                      return const EmptyState(
                        icon: Icons.search_off,
                        title: 'No matching departments',
                        message:
                            'Try a broader search like finance, support, registry, or ICT.',
                      );
                    }
                    return ListView.separated(
                      itemCount: items.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) =>
                          _DirectoryCard(entry: items[index])
                              .animate()
                              .fadeIn(duration: 260.ms)
                              .slideY(begin: 0.05, end: 0),
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
        color: scheme.surfaceContainer,
        border: Border.all(color: scheme.outlineVariant),
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
              ],
            ),
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
