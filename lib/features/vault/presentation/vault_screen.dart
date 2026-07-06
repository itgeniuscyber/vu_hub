import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/utils/firestore_error_message.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/feature_hero_banner.dart';
import '../../../core/widgets/firestore_error_state.dart';
import '../../../core/widgets/loading_shimmer.dart';
import '../../ai_desk/presentation/ai_insight_sheet.dart';
import '../../auth/data/app_session.dart';
import '../data/vault_repository.dart';
import '../data/vault_resource.dart';

class VaultScreen extends StatefulWidget {
  const VaultScreen({super.key});

  @override
  State<VaultScreen> createState() => _VaultScreenState();
}

class _VaultScreenState extends State<VaultScreen> {
  final _searchController = TextEditingController();
  late final Stream<List<VaultResource>> _vaultStream;
  String _query = '';
  String _faculty = 'All';
  _VaultViewMode _viewMode = _VaultViewMode.list;

  @override
  void initState() {
    super.initState();
    _vaultStream = VaultRepository().watchPastPapers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final session = context.watch<AppSession>();
    final width = MediaQuery.sizeOf(context).width;
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final toolbarHeight =
        198.0 + ((textScale - 1).clamp(0.0, 0.5) * 30) + (width < 380 ? 12 : 0);
    return Scaffold(
      body: SafeArea(
        child: StreamBuilder<List<VaultResource>>(
          stream: _vaultStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                children: const [
                  LoadingShimmer(height: 196),
                  SizedBox(height: 18),
                  LoadingShimmer(height: 70),
                  SizedBox(height: 12),
                  LoadingShimmer(height: 42),
                  SizedBox(height: 12),
                  LoadingShimmer(height: 152),
                  SizedBox(height: 12),
                  LoadingShimmer(height: 152),
                ],
              );
            }
            if (snapshot.hasError) {
              return FirestoreErrorState(
                error: snapshot.error!,
                title: 'Could not load VU Vault',
                fallbackMessage:
                    'Past papers and resources are unavailable right now.',
              );
            }

            final allResources = snapshot.data ?? [];
            final normalizedQuery = _query.trim().toLowerCase();
            final faculties = {
              'All',
              ...allResources
                  .map((item) => item.faculty)
                  .where((item) => item.isNotEmpty),
            }.toList();
            final resources = allResources.where((item) {
              final matchesQuery =
                  normalizedQuery.isEmpty ||
                  item.title.toLowerCase().contains(normalizedQuery) ||
                  item.faculty.toLowerCase().contains(normalizedQuery) ||
                  item.uploadedBy.toLowerCase().contains(normalizedQuery) ||
                  item.fileType.toLowerCase().contains(normalizedQuery) ||
                  (item.uploadedAt != null &&
                      DateFormat('MMM d yyyy')
                          .format(item.uploadedAt!)
                          .toLowerCase()
                          .contains(normalizedQuery));
              final matchesFaculty =
                  _faculty == 'All' || item.faculty == _faculty;
              return matchesQuery && matchesFaculty;
            }).toList();
            final spotlight = resources.take(5).toList();

            return CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                  sliver: SliverToBoxAdapter(
                    child: FeatureHeroBanner(
                      title: 'VU Vault',
                      subtitle:
                          'Past papers and study materials mapped safely from the existing `past_papers` collection.',
                      icon: Icons.folder_copy_outlined,
                      scheme: scheme,
                      badge: '${allResources.length} resources',
                      trailing: session.canUploadResources
                          ? FilledButton.icon(
                              onPressed: () => _openUploader(context, session),
                              icon: const Icon(Icons.upload_file_outlined),
                              label: const Text('Upload'),
                            )
                          : null,
                    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.05, end: 0),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  sliver: SliverToBoxAdapter(
                    child:
                        _VaultInsightStrip(
                              totalCount: allResources.length,
                              facultyCount: faculties.length - 1,
                              fileReadyCount: allResources
                                  .where((item) => item.fileUrl.isNotEmpty)
                                  .length,
                            )
                            .animate()
                            .fadeIn(duration: 260.ms)
                            .slideY(begin: 0.04, end: 0),
                  ),
                ),
                if (spotlight.isNotEmpty)
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                    sliver: SliverToBoxAdapter(
                      child: _VaultSpotlightRail(items: spotlight),
                    ),
                  ),
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _VaultToolbarDelegate(
                    extent: toolbarHeight,
                    child: Container(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _VaultSearchBar(
                            controller: _searchController,
                            query: _query,
                            onChanged: (value) =>
                                setState(() => _query = value),
                            onClear: () {
                              _searchController.clear();
                              setState(() => _query = '');
                            },
                          ),
                          const SizedBox(height: 12),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final resultsText =
                                  '${resources.length} result${resources.length == 1 ? '' : 's'}';
                              if (constraints.maxWidth < 360) {
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      resultsText,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodyMedium,
                                    ),
                                    const SizedBox(height: 8),
                                    _VaultViewToggle(
                                      mode: _viewMode,
                                      onChanged: (mode) =>
                                          setState(() => _viewMode = mode),
                                    ),
                                  ],
                                );
                              }

                              return Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      resultsText,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodyMedium,
                                    ),
                                  ),
                                  _VaultViewToggle(
                                    mode: _viewMode,
                                    onChanged: (mode) =>
                                        setState(() => _viewMode = mode),
                                  ),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 40,
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 2,
                                ),
                                itemCount: faculties.length,
                                separatorBuilder: (_, _) =>
                                    const SizedBox(width: 8),
                                itemBuilder: (context, index) {
                                  final label = faculties[index];
                                  return Center(
                                    child: ConstrainedBox(
                                      constraints: const BoxConstraints(
                                        maxWidth: 220,
                                      ),
                                      child: ChoiceChip(
                                        showCheckmark: false,
                                        materialTapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                        ),
                                        labelPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 2,
                                            ),
                                        visualDensity: const VisualDensity(
                                          horizontal: -1,
                                          vertical: -2,
                                        ),
                                        selected: _faculty == label,
                                        label: Text(
                                          label,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelLarge
                                              ?.copyWith(fontSize: 13),
                                        ),
                                        onSelected: (_) =>
                                            setState(() => _faculty = label),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  sliver: resources.isEmpty
                      ? const SliverToBoxAdapter(
                          child: EmptyState(
                            icon: Icons.folder_copy_outlined,
                            title: 'No matching resources',
                            message:
                                'Try a different faculty filter or broader search term.',
                          ),
                        )
                      : _viewMode == _VaultViewMode.list
                      ? SliverList(
                          delegate: SliverChildBuilderDelegate((
                            context,
                            index,
                          ) {
                            return Padding(
                              padding: EdgeInsets.only(
                                bottom: index == resources.length - 1 ? 0 : 12,
                              ),
                              child:
                                  _VaultResourceCard(resource: resources[index])
                                      .animate()
                                      .fadeIn(duration: 280.ms)
                                      .slideY(begin: 0.04, end: 0),
                            );
                          }, childCount: resources.length),
                        )
                      : SliverLayoutBuilder(
                          builder: (context, constraints) {
                            final width = constraints.crossAxisExtent;
                            final crossAxisCount = width >= 1100
                                ? 4
                                : width >= 760
                                ? 3
                                : 2;
                            return SliverGrid(
                              delegate: SliverChildBuilderDelegate((
                                context,
                                index,
                              ) {
                                return _VaultResourceGridCard(
                                      resource: resources[index],
                                    )
                                    .animate()
                                    .fadeIn(duration: 260.ms)
                                    .slideY(begin: 0.04, end: 0);
                              }, childCount: resources.length),
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: crossAxisCount,
                                    mainAxisSpacing: 12,
                                    crossAxisSpacing: 12,
                                    childAspectRatio: width < 420 ? 0.64 : 0.71,
                                  ),
                            );
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _openUploader(BuildContext context, AppSession session) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _VaultUploadSheet(session: session),
    );
    if (!context.mounted || result != true) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Resource uploaded successfully.')),
    );
  }
}

class _VaultToolbarDelegate extends SliverPersistentHeaderDelegate {
  const _VaultToolbarDelegate({required this.child, required this.extent});

  final Widget child;
  final double extent;

  @override
  double get minExtent => extent;

  @override
  double get maxExtent => extent;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return child;
  }

  @override
  bool shouldRebuild(covariant _VaultToolbarDelegate oldDelegate) {
    return child != oldDelegate.child;
  }
}

enum _VaultViewMode { list, grid }

class _VaultInsightStrip extends StatelessWidget {
  const _VaultInsightStrip({
    required this.totalCount,
    required this.facultyCount,
    required this.fileReadyCount,
  });

  final int totalCount;
  final int facultyCount;
  final int fileReadyCount;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 390;
        final cards = [
          _VaultInsightCard(
            icon: Icons.folder_copy_outlined,
            label: 'Resources',
            value: '$totalCount',
            color: scheme.primary,
            compact: compact,
          ),
          _VaultInsightCard(
            icon: Icons.apartment_outlined,
            label: 'Faculties',
            value: '$facultyCount',
            color: scheme.secondary,
            compact: compact,
          ),
          _VaultInsightCard(
            icon: Icons.file_open_outlined,
            label: 'Ready',
            value: '$fileReadyCount',
            color: scheme.tertiary,
            compact: compact,
          ),
        ];

        if (compact) {
          return SizedBox(
            height: 122,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: cards.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (context, index) =>
                  SizedBox(width: 118, child: cards[index]),
            ),
          );
        }

        return Row(
          children: [
            Expanded(child: cards[0]),
            const SizedBox(width: 12),
            Expanded(child: cards[1]),
            const SizedBox(width: 12),
            Expanded(child: cards[2]),
          ],
        );
      },
    );
  }
}

class _VaultInsightCard extends StatelessWidget {
  const _VaultInsightCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.compact = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 10 : 12,
          vertical: compact ? 12 : 14,
        ),
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
              maxLines: compact ? 2 : 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontSize: compact ? 13 : 14),
            ),
          ],
        ),
      ),
    );
  }
}

class _VaultSearchBar extends StatelessWidget {
  const _VaultSearchBar({
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
            color: scheme.primary.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Search past papers, faculties, and subjects',
          prefixIcon: Container(
            margin: const EdgeInsets.only(left: 10, right: 6),
            child: Icon(Icons.search, color: scheme.primary),
          ),
          suffixIcon: AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: query.trim().isNotEmpty
                ? IconButton(
                    key: const ValueKey('clear'),
                    onPressed: onClear,
                    icon: Icon(Icons.close_rounded, color: scheme.primary),
                    tooltip: 'Clear search',
                  )
                : Container(
                    key: const ValueKey('tune'),
                    margin: const EdgeInsets.only(right: 8),
                    child: Icon(
                      Icons.tune_rounded,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
          ),
          filled: false,
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
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 18,
          ),
        ),
      ),
    );
  }
}

class _VaultViewToggle extends StatelessWidget {
  const _VaultViewToggle({required this.mode, required this.onChanged});

  final _VaultViewMode mode;
  final ValueChanged<_VaultViewMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: scheme.surfaceContainerHighest,
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _VaultViewToggleButton(
            icon: Icons.view_agenda_rounded,
            selected: mode == _VaultViewMode.list,
            onTap: () => onChanged(_VaultViewMode.list),
          ),
          const SizedBox(width: 4),
          _VaultViewToggleButton(
            icon: Icons.grid_view_rounded,
            selected: mode == _VaultViewMode.grid,
            onTap: () => onChanged(_VaultViewMode.grid),
          ),
        ],
      ),
    );
  }
}

class _VaultViewToggleButton extends StatelessWidget {
  const _VaultViewToggleButton({
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: selected ? scheme.primary : Colors.transparent,
        ),
        child: Icon(
          icon,
          size: 18,
          color: selected ? Colors.white : scheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

enum _VaultActionStyle { primary, secondary }

class _VaultActionButton extends StatelessWidget {
  const _VaultActionButton({
    required this.icon,
    required this.label,
    required this.style,
    required this.onTap,
    this.enabled = true,
    this.compact = false,
  });

  final IconData icon;
  final String label;
  final _VaultActionStyle style;
  final VoidCallback onTap;
  final bool enabled;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isPrimary = style == _VaultActionStyle.primary;
    final foreground = enabled
        ? (isPrimary ? Colors.white : scheme.primary)
        : scheme.onSurface.withValues(alpha: 0.38);
    final background = enabled
        ? (isPrimary ? scheme.primary : scheme.surfaceContainerHighest)
        : scheme.surfaceContainerHighest.withValues(alpha: 0.6);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      height: compact ? 42 : 54,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(compact ? 16 : 18),
        gradient: enabled && isPrimary
            ? LinearGradient(
                colors: [
                  scheme.primary,
                  scheme.primary.withValues(alpha: 0.82),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: isPrimary ? null : background,
        border: isPrimary
            ? null
            : Border.all(color: scheme.outlineVariant.withValues(alpha: 0.6)),
        boxShadow: enabled && isPrimary
            ? [
                BoxShadow(
                  color: scheme.primary.withValues(alpha: 0.22),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(compact ? 16 : 18),
          onTap: enabled ? onTap : null,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: compact ? 15 : 18, color: foreground),
                SizedBox(width: compact ? 5 : 8),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: foreground,
                      fontSize: compact ? 12 : 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _VaultSpotlightRail extends StatelessWidget {
  const _VaultSpotlightRail({required this.items});

  final List<VaultResource> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Study spotlight', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 4),
        Text(
          'A quick way to jump into the most visible resources right now.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 174,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) => SizedBox(
              width: 248,
              child: _VaultSpotlightCard(resource: items[index]),
            ),
          ),
        ),
      ],
    );
  }
}

class _VaultSpotlightCard extends StatelessWidget {
  const _VaultSpotlightCard({required this.resource});

  final VaultResource resource;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _showResourceDetail(context, resource),
        child: Stack(
          children: [
            Positioned.fill(
              child: resource.thumbnailUrl == null
                  ? Image.asset(
                      'assets/images/vu_default_card.png',
                      fit: BoxFit.cover,
                    )
                  : CachedNetworkImage(
                      imageUrl: resource.thumbnailUrl!,
                      fit: BoxFit.cover,
                      errorWidget: (_, _, _) => Image.asset(
                        'assets/images/vu_default_card.png',
                        fit: BoxFit.cover,
                      ),
                    ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      scheme.primary.withValues(alpha: 0.18),
                      Colors.black.withValues(alpha: 0.12),
                      Colors.black.withValues(alpha: 0.72),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _VaultBadge(
                    icon: Icons.bookmark_outline,
                    label: resource.fileType.toUpperCase(),
                    color: Colors.white,
                    background: Colors.white.withValues(alpha: 0.16),
                  ),
                  const Spacer(),
                  Text(
                    resource.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(
                      context,
                    ).textTheme.titleLarge?.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    resource.faculty,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.88),
                    ),
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

class _VaultResourceCard extends StatelessWidget {
  const _VaultResourceCard({required this.resource});

  final VaultResource resource;

  Future<void> _openResource() async {
    final uri = Uri.tryParse(resource.fileUrl);
    if (uri != null) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _showResourceDetail(context, resource),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 184,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  resource.thumbnailUrl == null
                      ? Image.asset(
                          'assets/images/vu_default_card.png',
                          fit: BoxFit.cover,
                        )
                      : CachedNetworkImage(
                          imageUrl: resource.thumbnailUrl!,
                          fit: BoxFit.cover,
                          errorWidget: (_, _, _) => Image.asset(
                            'assets/images/vu_default_card.png',
                            fit: BoxFit.cover,
                          ),
                        ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          scheme.primary.withValues(alpha: 0.18),
                          Colors.black.withValues(alpha: 0.12),
                          Colors.black.withValues(alpha: 0.7),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _VaultBadge(
                              icon: Icons.apartment_outlined,
                              label: resource.faculty,
                              color: Colors.white,
                              background: Colors.white.withValues(alpha: 0.16),
                              maxWidth: 190,
                            ),
                            _VaultBadge(
                              icon: Icons.insert_drive_file_outlined,
                              label: resource.fileType.toUpperCase(),
                              color: Colors.white,
                              background: Colors.white.withValues(alpha: 0.16),
                              maxWidth: 88,
                            ),
                          ],
                        ),
                        const Spacer(),
                        Text(
                          resource.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(color: Colors.white, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    resource.uploadedAt == null
                        ? 'Uploaded by ${resource.uploadedBy}'
                        : 'Uploaded by ${resource.uploadedBy} • ${DateFormat.MMMd().format(resource.uploadedAt!)}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _VaultBadge(
                        icon: Icons.auto_awesome,
                        label: 'AI summary',
                        color: scheme.primary,
                        background: scheme.surfaceContainerHighest,
                        maxWidth: 120,
                      ),
                      _VaultBadge(
                        icon: Icons.quiz_outlined,
                        label: 'Revision ready',
                        color: scheme.primary,
                        background: scheme.surfaceContainerHighest,
                        maxWidth: 140,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _VaultActionButton(
                          icon: Icons.open_in_new,
                          label: 'Open paper',
                          style: _VaultActionStyle.primary,
                          enabled: resource.fileUrl.isNotEmpty,
                          onTap: _openResource,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _VaultActionButton(
                          icon: Icons.auto_awesome,
                          label: 'AI summary',
                          style: _VaultActionStyle.secondary,
                          onTap: () => showAiInsightSheet(
                            context: context,
                            title: 'Study with AI',
                            prompt:
                                'Summarize resource "${resource.title}" from ${resource.faculty}. File type: ${resource.fileType}. Study with AI.',
                          ),
                        ),
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

class _VaultResourceGridCard extends StatelessWidget {
  const _VaultResourceGridCard({required this.resource});

  final VaultResource resource;

  Future<void> _openResource() async {
    final uri = Uri.tryParse(resource.fileUrl);
    if (uri != null) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _showResourceDetail(context, resource),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  resource.thumbnailUrl == null
                      ? Image.asset(
                          'assets/images/vu_default_card.png',
                          fit: BoxFit.cover,
                        )
                      : CachedNetworkImage(
                          imageUrl: resource.thumbnailUrl!,
                          fit: BoxFit.cover,
                          errorWidget: (_, _, _) => Image.asset(
                            'assets/images/vu_default_card.png',
                            fit: BoxFit.cover,
                          ),
                        ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          scheme.primary.withValues(alpha: 0.16),
                          Colors.black.withValues(alpha: 0.14),
                          Colors.black.withValues(alpha: 0.72),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _VaultBadge(
                          icon: Icons.insert_drive_file_outlined,
                          label: resource.fileType.toUpperCase(),
                          color: Colors.white,
                          background: Colors.white.withValues(alpha: 0.16),
                          maxWidth: 82,
                        ),
                        const Spacer(),
                        Text(
                          resource.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(color: Colors.white, height: 1.08),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    resource.faculty,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(
                      context,
                    ).textTheme.labelLarge?.copyWith(color: scheme.primary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    resource.uploadedAt == null
                        ? resource.uploadedBy
                        : '${resource.uploadedBy} • ${DateFormat.MMMd().format(resource.uploadedAt!)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _VaultActionButton(
                          icon: Icons.open_in_new,
                          label: 'Open',
                          style: _VaultActionStyle.primary,
                          enabled: resource.fileUrl.isNotEmpty,
                          compact: true,
                          onTap: _openResource,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _VaultActionButton(
                          icon: Icons.auto_awesome,
                          label: 'AI',
                          style: _VaultActionStyle.secondary,
                          compact: true,
                          onTap: () => showAiInsightSheet(
                            context: context,
                            title: 'Study with AI',
                            prompt:
                                'Summarize resource "${resource.title}" from ${resource.faculty}. File type: ${resource.fileType}. Study with AI.',
                          ),
                        ),
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

class _VaultUploadSheet extends StatefulWidget {
  const _VaultUploadSheet({required this.session});

  final AppSession session;

  @override
  State<_VaultUploadSheet> createState() => _VaultUploadSheetState();
}

class _VaultUploadSheetState extends State<_VaultUploadSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _facultyController = TextEditingController();
  final _externalUrlController = TextEditingController();
  final _thumbnailUrlController = TextEditingController();

  PlatformFile? _selectedFile;
  PlatformFile? _selectedThumbnail;
  String _fileType = 'pdf';
  bool _isSaving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _facultyController.dispose();
    _externalUrlController.dispose();
    _thumbnailUrlController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      withData: true,
      allowedExtensions: ['pdf', 'doc', 'docx', 'ppt', 'pptx'],
      type: FileType.custom,
    );
    if (!mounted || result == null || result.files.isEmpty) return;
    final file = result.files.single;
    setState(() {
      _selectedFile = file;
      final extension = file.extension?.toLowerCase();
      if (extension != null && extension.isNotEmpty) {
        _fileType = extension;
      }
    });
  }

  Future<void> _pickThumbnail() async {
    final result = await FilePicker.platform.pickFiles(
      withData: true,
      allowedExtensions: ['png', 'jpg', 'jpeg', 'webp'],
      type: FileType.custom,
    );
    if (!mounted || result == null || result.files.isEmpty) return;
    setState(() => _selectedThumbnail = result.files.single);
  }

  Future<void> _upload() async {
    if (!_formKey.currentState!.validate()) return;
    if ((_selectedFile?.bytes == null || _selectedFile!.bytes!.isEmpty) &&
        _externalUrlController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pick a file or provide an external resource URL.'),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    final profile = widget.session.profile;
    try {
      await VaultRepository().uploadPastPaper(
        title: _titleController.text,
        faculty: _facultyController.text,
        uploadedBy:
            profile?.displayName ??
            widget.session.firebaseUser?.email ??
            'VU Staff',
        uploaderId: widget.session.firebaseUser?.uid ?? '',
        fileType: _fileType,
        fileName: _selectedFile?.name ?? 'resource.$_fileType',
        fileBytes: _selectedFile?.bytes,
        externalFileUrl: _externalUrlController.text,
        thumbnailUrl: _thumbnailUrlController.text,
        thumbnailBytes: _selectedThumbnail?.bytes,
        thumbnailFileName: _selectedThumbnail?.name,
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            describeFirestoreError(
              error,
              fallback: 'We could not upload this resource.',
            ),
          ),
        ),
      );
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: scheme.primary.withValues(alpha: 0.12),
                    ),
                    child: Icon(
                      Icons.cloud_upload_outlined,
                      color: scheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Upload VU Vault resource',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Add a past paper or study resource without changing the existing collection structure.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: scheme.primary.withValues(alpha: 0.08),
                ),
                child: Text(
                  'You can upload directly to Firebase Storage or provide an external file URL. Titles, faculty names, and file types should stay clean for search and AI study support.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Subject or title',
                ),
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'Enter a resource title'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _facultyController,
                decoration: const InputDecoration(labelText: 'Faculty'),
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'Enter the faculty'
                    : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _fileType,
                decoration: const InputDecoration(labelText: 'File type'),
                items: const [
                  DropdownMenuItem(value: 'pdf', child: Text('PDF')),
                  DropdownMenuItem(value: 'docx', child: Text('DOCX')),
                  DropdownMenuItem(value: 'pptx', child: Text('PPTX')),
                ],
                onChanged: (value) =>
                    setState(() => _fileType = value ?? 'pdf'),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  color: scheme.surfaceContainerHighest,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Files and preview',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _pickFile,
                      icon: const Icon(Icons.attach_file),
                      label: Text(
                        _selectedFile == null
                            ? 'Pick file'
                            : _selectedFile!.name,
                      ),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: _pickThumbnail,
                      icon: const Icon(Icons.image_outlined),
                      label: Text(
                        _selectedThumbnail == null
                            ? 'Pick thumbnail image'
                            : _selectedThumbnail!.name,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _externalUrlController,
                decoration: const InputDecoration(
                  labelText: 'External file URL',
                  hintText: 'Optional if you upload a file directly',
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _thumbnailUrlController,
                decoration: const InputDecoration(
                  labelText: 'Thumbnail URL',
                  hintText: 'Optional preview image',
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _isSaving ? null : _upload,
                icon: _isSaving
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.cloud_upload_outlined),
                label: const Text('Upload resource'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VaultBadge extends StatelessWidget {
  const _VaultBadge({
    required this.icon,
    required this.label,
    required this.color,
    required this.background,
    this.maxWidth = 180,
  });

  final IconData icon;
  final String label;
  final Color color;
  final Color background;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(color: color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void _showResourceDetail(BuildContext context, VaultResource resource) {
  final scheme = Theme.of(context).colorScheme;
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) {
      return Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 8,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: LinearGradient(
                    colors: [
                      scheme.primary.withValues(alpha: 0.92),
                      scheme.secondary.withValues(alpha: 0.66),
                      scheme.surfaceContainerHighest,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _VaultBadge(
                          icon: Icons.apartment_outlined,
                          label: resource.faculty,
                          color: Colors.white,
                          background: Colors.white.withValues(alpha: 0.16),
                        ),
                        _VaultBadge(
                          icon: Icons.insert_drive_file_outlined,
                          label: resource.fileType.toUpperCase(),
                          color: Colors.white,
                          background: Colors.white.withValues(alpha: 0.16),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      resource.title,
                      style: Theme.of(
                        context,
                      ).textTheme.headlineMedium?.copyWith(color: Colors.white),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _VaultBadge(
                    icon: Icons.account_circle_outlined,
                    label: resource.uploadedBy,
                    color: scheme.primary,
                    background: scheme.surfaceContainerHighest,
                  ),
                  if (resource.uploadedAt != null)
                    _VaultBadge(
                      icon: Icons.schedule,
                      label: DateFormat(
                        'EEE, MMM d',
                      ).format(resource.uploadedAt!),
                      color: scheme.primary,
                      background: scheme.surfaceContainerHighest,
                    ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                'This resource is available in VU Vault and supports open/download actions plus AI-assisted study prompts.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () async {
                        final uri = Uri.tryParse(resource.fileUrl);
                        if (uri != null) {
                          await launchUrl(
                            uri,
                            mode: LaunchMode.externalApplication,
                          );
                        }
                      },
                      icon: const Icon(Icons.open_in_new),
                      label: const Text('Open resource'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => showAiInsightSheet(
                        context: context,
                        title: 'Study with AI',
                        prompt:
                            'Summarize resource "${resource.title}" from ${resource.faculty}. File type: ${resource.fileType}. Study with AI.',
                      ),
                      icon: const Icon(Icons.auto_awesome),
                      label: const Text('Study with AI'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}
