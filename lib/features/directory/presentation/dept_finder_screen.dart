import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  String _selectedRoute = 'All';

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
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
              sliver: SliverList.list(
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
                  _FinderHero(scheme: scheme, onRouteTap: _setSearch),
                  const SizedBox(height: 14),
                  _ProblemShortcutStrip(onSelected: _setSearch),
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
                  StreamBuilder<List<DirectoryEntry>>(
                    stream: _entriesStream,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Column(
                          children: [
                            LoadingShimmer(height: 120),
                            SizedBox(height: 12),
                            LoadingShimmer(height: 120),
                            SizedBox(height: 12),
                            LoadingShimmer(height: 120),
                            SizedBox(height: 96),
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

                      final allItems = snapshot.data ?? [];
                      final routes = _routesFor(allItems);
                      final items = allItems.where(_matches).toList();
                      final totalItems = allItems.length;

                      if (items.isEmpty) {
                        return Column(
                          children: [
                            _RouteFilterBar(
                              routes: routes,
                              selectedRoute: _selectedRoute,
                              onSelected: (value) =>
                                  setState(() => _selectedRoute = value),
                            ),
                            const SizedBox(height: 18),
                            const SizedBox(
                              height: 320,
                              child: EmptyState(
                                icon: Icons.search_off,
                                title: 'No matching departments',
                                message:
                                    'Try a broader search like finance, support, registry, retake, or ICT.',
                              ),
                            ),
                            const SizedBox(height: 96),
                          ],
                        );
                      }

                      return Column(
                        children: [
                          _RouteFilterBar(
                            routes: routes,
                            selectedRoute: _selectedRoute,
                            onSelected: (value) =>
                                setState(() => _selectedRoute = value),
                          ),
                          const SizedBox(height: 12),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    '${items.length} result${items.length == 1 ? '' : 's'} found',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyMedium,
                                  ),
                                ),
                                if (_query.isNotEmpty)
                                  Text(
                                    'from $totalItems contacts',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
                              ],
                            ),
                          ),
                          ...items.map(
                            (entry) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child:
                                  _DirectoryCard(
                                        entry: entry,
                                        onOpen: () => _openEntrySheet(entry),
                                      )
                                      .animate()
                                      .fadeIn(duration: 260.ms)
                                      .slideY(begin: 0.05, end: 0),
                            ),
                          ),
                          const SizedBox(height: 96),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _matches(DirectoryEntry entry) {
    final routeMatch =
        _selectedRoute == 'All' || entry.routeLabel == _selectedRoute;
    if (!routeMatch) return false;
    if (_query.isEmpty) return true;
    final haystack = [
      entry.name,
      entry.department,
      entry.role,
      entry.email,
      entry.phone,
      entry.location,
      entry.category,
      entry.description,
      entry.officeHours,
      entry.building,
      ...entry.keywords,
      ...entry.services,
    ].join(' ').toLowerCase();
    return haystack.contains(_query);
  }

  List<String> _routesFor(List<DirectoryEntry> entries) {
    final routes = entries.map((entry) => entry.routeLabel).toSet().toList()
      ..sort();
    return ['All', ...routes];
  }

  void _setSearch(String value) {
    _searchController.text = value;
    _searchController.selection = TextSelection.collapsed(
      offset: _searchController.text.length,
    );
    setState(() => _query = value.trim().toLowerCase());
  }

  void _openEntrySheet(DirectoryEntry entry) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => _DirectoryDetailSheet(entry: entry),
    );
  }
}

class _FinderHero extends StatelessWidget {
  const _FinderHero({required this.scheme, required this.onRouteTap});

  final ColorScheme scheme;
  final ValueChanged<String> onRouteTap;

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
                      onTap: () => onRouteTap('retake'),
                    ),
                    _RoutingTag(
                      icon: Icons.payments_outlined,
                      label: 'Finance',
                      tone: scheme.secondary,
                      onTap: () => onRouteTap('fees'),
                    ),
                    _RoutingTag(
                      icon: Icons.memory_outlined,
                      label: 'ICT',
                      tone: scheme.tertiary,
                      onTap: () => onRouteTap('vclass'),
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

class _ProblemShortcutStrip extends StatelessWidget {
  const _ProblemShortcutStrip({required this.onSelected});

  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final items = [
      _ShortcutQuery('Retake', 'retake', Icons.assignment_return_outlined),
      _ShortcutQuery('Fees', 'fees', Icons.payments_outlined),
      _ShortcutQuery('VClass', 'vclass', Icons.computer_outlined),
      _ShortcutQuery('Wi-Fi', 'wifi', Icons.wifi_outlined),
      _ShortcutQuery('Lecturer', 'lecturer', Icons.school_outlined),
      _ShortcutQuery('Support', 'support', Icons.volunteer_activism_outlined),
    ];

    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final item = items[index];
          return ActionChip(
            avatar: Icon(item.icon, size: 17, color: scheme.primary),
            label: Text(item.label),
            onPressed: () => onSelected(item.query),
          );
        },
      ),
    );
  }
}

class _ShortcutQuery {
  const _ShortcutQuery(this.label, this.query, this.icon);

  final String label;
  final String query;
  final IconData icon;
}

class _RouteFilterBar extends StatelessWidget {
  const _RouteFilterBar({
    required this.routes,
    required this.selectedRoute,
    required this.onSelected,
  });

  final List<String> routes;
  final String selectedRoute;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: routes.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final route = routes[index];
          return FilterChip(
            selected: selectedRoute == route,
            avatar: Icon(_routeIcon(route), size: 16),
            label: Text(route),
            onSelected: (_) => onSelected(route),
          );
        },
      ),
    );
  }
}

class _RoutingTag extends StatelessWidget {
  const _RoutingTag({
    required this.icon,
    required this.label,
    required this.tone,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final Color tone;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
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
      ),
    );
  }
}

IconData _routeIcon(String route) {
  switch (route.toLowerCase()) {
    case 'academic':
      return Icons.school_outlined;
    case 'digital':
      return Icons.memory_outlined;
    case 'faculty':
      return Icons.apartment_outlined;
    case 'finance':
      return Icons.payments_outlined;
    case 'support':
      return Icons.support_agent_outlined;
    case 'all':
      return Icons.all_inclusive;
    default:
      return Icons.location_city_outlined;
  }
}

Color _routeColor(BuildContext context, String route) {
  final scheme = Theme.of(context).colorScheme;
  switch (route.toLowerCase()) {
    case 'academic':
      return const Color(0xFF8B5CF6);
    case 'digital':
      return scheme.secondary;
    case 'faculty':
      return const Color(0xFF14B8A6);
    case 'finance':
      return const Color(0xFFF59E0B);
    case 'support':
      return const Color(0xFF22C55E);
    default:
      return scheme.primary;
  }
}

class _DirectoryCard extends StatelessWidget {
  const _DirectoryCard({required this.entry, required this.onOpen});

  final DirectoryEntry entry;
  final VoidCallback onOpen;

  Future<void> _launch(Uri uri) async {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final tone = _routeColor(context, entry.routeLabel);
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: tone.withValues(alpha: 0.14),
                    child: Icon(_routeIcon(entry.routeLabel), color: tone),
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
                  _RouteBadge(label: entry.routeLabel, tone: tone),
                ],
              ),
              const SizedBox(height: 12),
              if (entry.description.isNotEmpty) ...[
                Text(
                  entry.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
              ],
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Chip(
                    avatar: const Icon(Icons.location_on_outlined, size: 16),
                    label: Text(entry.location),
                  ),
                  if (entry.officeHours.isNotEmpty)
                    Chip(
                      avatar: const Icon(Icons.schedule_outlined, size: 16),
                      label: Text(entry.officeHours),
                    ),
                  ...entry.services
                      .take(2)
                      .map((word) => Chip(label: Text(word))),
                  if (entry.services.isEmpty)
                    ...entry.keywords
                        .take(2)
                        .map((word) => Chip(label: Text(word))),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: Wrap(
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
                            onPressed: () =>
                                _launch(Uri.parse('tel:${entry.phone}')),
                            icon: const Icon(Icons.call_outlined),
                            label: const Text('Call'),
                          ),
                      ],
                    ),
                  ),
                  IconButton.filledTonal(
                    tooltip: 'Open details',
                    onPressed: onOpen,
                    icon: const Icon(Icons.open_in_new_rounded),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RouteBadge extends StatelessWidget {
  const _RouteBadge({required this.label, required this.tone});

  final String label;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: tone.withValues(alpha: 0.11),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(color: tone),
      ),
    );
  }
}

class _DirectoryDetailSheet extends StatelessWidget {
  const _DirectoryDetailSheet({required this.entry});

  final DirectoryEntry entry;

  Future<void> _launch(Uri uri) async {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _copy(BuildContext context, String value, String label) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tone = _routeColor(context, entry.routeLabel);
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.78,
      minChildSize: 0.45,
      maxChildSize: 0.94,
      builder: (context, controller) {
        return ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: tone.withValues(alpha: 0.14),
                  child: Icon(_routeIcon(entry.routeLabel), color: tone),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.name,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${entry.department} • ${entry.role}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                _RouteBadge(label: entry.routeLabel, tone: tone),
              ],
            ),
            const SizedBox(height: 18),
            if (entry.description.isNotEmpty)
              _DetailPanel(
                icon: Icons.info_outline,
                title: 'What this office helps with',
                child: Text(entry.description),
              ),
            if (entry.services.isNotEmpty) ...[
              const SizedBox(height: 12),
              _DetailPanel(
                icon: Icons.checklist_rounded,
                title: 'Services',
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: entry.services
                      .map((service) => Chip(label: Text(service)))
                      .toList(),
                ),
              ),
            ],
            const SizedBox(height: 12),
            _DetailPanel(
              icon: Icons.place_outlined,
              title: 'Visit',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _DetailRow(
                    icon: Icons.location_on_outlined,
                    label: 'Location',
                    value: entry.location,
                    onCopy: () => _copy(context, entry.location, 'Location'),
                  ),
                  if (entry.building.isNotEmpty)
                    _DetailRow(
                      icon: Icons.apartment_outlined,
                      label: 'Building',
                      value: entry.building,
                      onCopy: () => _copy(context, entry.building, 'Building'),
                    ),
                  if (entry.officeHours.isNotEmpty)
                    _DetailRow(
                      icon: Icons.schedule_outlined,
                      label: 'Hours',
                      value: entry.officeHours,
                      onCopy: () => _copy(context, entry.officeHours, 'Hours'),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _DetailPanel(
              icon: Icons.contact_mail_outlined,
              title: 'Contact',
              child: Column(
                children: [
                  if (entry.email.isNotEmpty)
                    _DetailRow(
                      icon: Icons.mail_outline,
                      label: 'Email',
                      value: entry.email,
                      onCopy: () => _copy(context, entry.email, 'Email'),
                    ),
                  if (entry.phone.isNotEmpty)
                    _DetailRow(
                      icon: Icons.call_outlined,
                      label: 'Phone',
                      value: entry.phone,
                      onCopy: () => _copy(context, entry.phone, 'Phone'),
                    ),
                  if (!entry.hasDirectContact)
                    Text(
                      'No direct contact is listed yet. Visit the office location or ask VU AI Desk for routing guidance.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                if (entry.email.isNotEmpty)
                  FilledButton.icon(
                    onPressed: () =>
                        _launch(Uri.parse('mailto:${entry.email}')),
                    icon: const Icon(Icons.mail_outline),
                    label: const Text('Email office'),
                  ),
                if (entry.phone.isNotEmpty)
                  OutlinedButton.icon(
                    onPressed: () => _launch(Uri.parse('tel:${entry.phone}')),
                    icon: const Icon(Icons.call_outlined),
                    label: const Text('Call'),
                  ),
                if (entry.mapUrl.isNotEmpty)
                  OutlinedButton.icon(
                    onPressed: () => _launch(Uri.parse(entry.mapUrl)),
                    icon: const Icon(Icons.directions_outlined),
                    label: const Text('Directions'),
                  ),
                if (entry.website.isNotEmpty)
                  OutlinedButton.icon(
                    onPressed: () => _launch(Uri.parse(entry.website)),
                    icon: const Icon(Icons.language_outlined),
                    label: const Text('Website'),
                  ),
              ],
            ),
            if (entry.keywords.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text('Keywords', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: entry.keywords
                    .map(
                      (keyword) => Chip(
                        label: Text(keyword),
                        backgroundColor: scheme.surfaceContainerHighest,
                      ),
                    )
                    .toList(),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _DetailPanel extends StatelessWidget {
  const _DetailPanel({
    required this.icon,
    required this.title,
    required this.child,
  });

  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.45),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: scheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onCopy,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.labelMedium),
                const SizedBox(height: 2),
                Text(value),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Copy',
            onPressed: onCopy,
            icon: const Icon(Icons.copy_rounded, size: 18),
          ),
        ],
      ),
    );
  }
}
