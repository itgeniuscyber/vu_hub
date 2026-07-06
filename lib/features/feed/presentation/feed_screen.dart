import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/firestore_error_message.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/feature_hero_banner.dart';
import '../../../core/widgets/firestore_error_state.dart';
import '../../../core/widgets/loading_shimmer.dart';
import '../../ai_desk/presentation/ai_insight_sheet.dart';
import '../../auth/data/app_session.dart';
import '../data/announcement.dart';
import '../data/announcement_repository.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  String _selectedCategory = 'All';
  String _query = '';

  static const _categories = [
    'All',
    'General',
    'Academic',
    'Events',
    'Guild',
    'Urgent',
  ];

  @override
  Widget build(BuildContext context) {
    final session = context.watch<AppSession>();
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: StreamBuilder<List<Announcement>>(
          stream: AnnouncementRepository().watchLatest(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                children: const [
                  LoadingShimmer(height: 196),
                  SizedBox(height: 16),
                  LoadingShimmer(height: 70),
                  SizedBox(height: 12),
                  LoadingShimmer(height: 54),
                  SizedBox(height: 12),
                  LoadingShimmer(height: 156),
                  SizedBox(height: 12),
                  LoadingShimmer(height: 156),
                ],
              );
            }
            if (snapshot.hasError) {
              return FirestoreErrorState(
                error: snapshot.error!,
                title: 'Could not load announcements',
                fallbackMessage:
                    'The announcements feed is unavailable right now.',
              );
            }

            final allItems = snapshot.data ?? [];
            final items = allItems
                .where(
                  (item) =>
                      _selectedCategory == 'All' ||
                      item.category == _selectedCategory,
                )
                .where((item) {
                  if (_query.isEmpty) return true;
                  final needle = _query.toLowerCase();
                  return item.title.toLowerCase().contains(needle) ||
                      item.content.toLowerCase().contains(needle) ||
                      item.category.toLowerCase().contains(needle) ||
                      item.publishedBy.toLowerCase().contains(needle);
                })
                .toList();
            final pinned = allItems
                .where((item) => item.isPinned)
                .take(5)
                .toList();
            final urgentCount = allItems
                .where((item) => item.category.toLowerCase() == 'urgent')
                .length;

            return CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                  sliver: SliverToBoxAdapter(
                    child: _FeedHero(
                      canPublish: session.canPublishAnnouncements,
                      onPublish: () => _openPublisher(context, session),
                      scheme: scheme,
                      totalCount: allItems.length,
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  sliver: SliverToBoxAdapter(
                    child:
                        _FeedInsightStrip(
                              totalCount: allItems.length,
                              pinnedCount: pinned.length,
                              urgentCount: urgentCount,
                            )
                            .animate()
                            .fadeIn(duration: 280.ms)
                            .slideY(begin: 0.04, end: 0),
                  ),
                ),
                if (pinned.isNotEmpty)
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                    sliver: SliverToBoxAdapter(
                      child: _PinnedNoticeRail(items: pinned),
                    ),
                  ),
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _FeedToolbarDelegate(
                    child: Container(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
                      child: Column(
                        children: [
                          TextField(
                            onChanged: (value) =>
                                setState(() => _query = value.trim()),
                            decoration: const InputDecoration(
                              hintText: 'Search notices, deadlines, offices...',
                              prefixIcon: Icon(Icons.search),
                            ),
                          ),
                          const SizedBox(height: 12),
                          _CategoryBar(
                            selected: _selectedCategory,
                            onSelected: (value) =>
                                setState(() => _selectedCategory = value),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  sliver: items.isEmpty
                      ? const SliverToBoxAdapter(
                          child: EmptyState(
                            icon: Icons.campaign_outlined,
                            title: 'No official notices yet',
                            message:
                                'Announcements will appear here when the collection has matching items.',
                          ),
                        )
                      : SliverList(
                          delegate: SliverChildBuilderDelegate((
                            context,
                            index,
                          ) {
                            return Padding(
                              padding: EdgeInsets.only(
                                bottom: index == items.length - 1 ? 0 : 12,
                              ),
                              child: _AnnouncementCard(item: items[index])
                                  .animate()
                                  .fadeIn(duration: 300.ms)
                                  .slideY(begin: 0.05, end: 0),
                            );
                          }, childCount: items.length),
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _openPublisher(BuildContext context, AppSession session) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _AnnouncementComposerSheet(session: session),
    );
    if (!context.mounted || result != true) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Announcement published successfully.')),
    );
  }
}

class _FeedHero extends StatelessWidget {
  const _FeedHero({
    required this.canPublish,
    required this.onPublish,
    required this.scheme,
    required this.totalCount,
  });

  final bool canPublish;
  final VoidCallback onPublish;
  final ColorScheme scheme;
  final int totalCount;

  @override
  Widget build(BuildContext context) {
    return FeatureHeroBanner(
      title: 'VU Feed',
      subtitle:
          'Announcements, guild updates, urgent notices, and AI-ready summaries in one trusted space.',
      icon: Icons.verified,
      scheme: scheme,
      imageAsset: 'assets/images/vu_default_card.png',
      badge: '$totalCount notices',
      trailing: canPublish
          ? FilledButton.icon(
              onPressed: onPublish,
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Publish'),
            )
          : null,
    ).animate().fadeIn(duration: 320.ms).slideY(begin: 0.05, end: 0);
  }
}

class _FeedInsightStrip extends StatelessWidget {
  const _FeedInsightStrip({
    required this.totalCount,
    required this.pinnedCount,
    required this.urgentCount,
  });

  final int totalCount;
  final int pinnedCount;
  final int urgentCount;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: _FeedInsightCard(
            icon: Icons.campaign_outlined,
            label: 'Notices',
            value: '$totalCount',
            color: scheme.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _FeedInsightCard(
            icon: Icons.push_pin_outlined,
            label: 'Pinned',
            value: '$pinnedCount',
            color: scheme.secondary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _FeedInsightCard(
            icon: Icons.warning_amber_rounded,
            label: 'Urgent',
            value: '$urgentCount',
            color: const Color(0xFFEF4444),
          ),
        ),
      ],
    );
  }
}

class _FeedInsightCard extends StatelessWidget {
  const _FeedInsightCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
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
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _PinnedNoticeRail extends StatelessWidget {
  const _PinnedNoticeRail({required this.items});

  final List<Announcement> items;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Pinned now', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 4),
        Text(
          'The notices students should not miss today.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 164,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final item = items[index];
              return SizedBox(
                width: 268,
                child: InkWell(
                  borderRadius: BorderRadius.circular(26),
                  onTap: () => _showAnnouncementDetail(context, item),
                  child: Ink(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(26),
                      gradient: LinearGradient(
                        colors: [
                          _categoryColor(
                            item.category,
                            scheme,
                          ).withValues(alpha: 0.94),
                          scheme.surfaceContainerHighest,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _MetaBadge(
                            icon: Icons.push_pin,
                            label: item.category,
                            color: Colors.white,
                            background: Colors.white.withValues(alpha: 0.16),
                          ),
                          const Spacer(),
                          Text(
                            item.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(color: Colors.white),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            item.content,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.88),
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _FeedToolbarDelegate extends SliverPersistentHeaderDelegate {
  const _FeedToolbarDelegate({required this.child});

  final Widget child;

  @override
  double get minExtent => 126;

  @override
  double get maxExtent => 126;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return child;
  }

  @override
  bool shouldRebuild(covariant _FeedToolbarDelegate oldDelegate) {
    return child != oldDelegate.child;
  }
}

class _CategoryBar extends StatelessWidget {
  const _CategoryBar({required this.selected, required this.onSelected});

  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _FeedScreenState._categories
            .map(
              (label) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  selected: label == selected,
                  label: Text(label),
                  onSelected: (_) => onSelected(label),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _AnnouncementComposerSheet extends StatefulWidget {
  const _AnnouncementComposerSheet({required this.session});

  final AppSession session;

  @override
  State<_AnnouncementComposerSheet> createState() =>
      _AnnouncementComposerSheetState();
}

class _AnnouncementComposerSheetState
    extends State<_AnnouncementComposerSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  String _category = 'General';
  bool _isPinned = false;
  bool _isSaving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _publish() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    final profile = widget.session.profile;
    try {
      await AnnouncementRepository().publishAnnouncement(
        title: _titleController.text,
        content: _contentController.text,
        category: _category,
        publishedBy:
            profile?.displayName ??
            widget.session.firebaseUser?.email ??
            'VU Admin',
        authorId: widget.session.firebaseUser?.uid ?? '',
        isPinned: _isPinned,
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            describeFirestoreError(
              error,
              fallback: 'We could not publish this announcement.',
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
                  child: Icon(Icons.edit_outlined, color: scheme.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Publish announcement',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Create an official notice for students, lecturers, and staff.',
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
                'Tip: concise titles and clear deadlines make announcements feel more professional and easier to summarize with AI.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Title'),
              validator: (value) => (value == null || value.trim().isEmpty)
                  ? 'Enter a title'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _contentController,
              minLines: 4,
              maxLines: 8,
              decoration: const InputDecoration(labelText: 'Content'),
              validator: (value) => (value == null || value.trim().isEmpty)
                  ? 'Enter announcement content'
                  : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: const InputDecoration(labelText: 'Category'),
              items: _FeedScreenState._categories
                  .where((item) => item != 'All')
                  .map(
                    (item) => DropdownMenuItem<String>(
                      value: item,
                      child: Text(item),
                    ),
                  )
                  .toList(),
              onChanged: (value) =>
                  setState(() => _category = value ?? 'General'),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Pin this announcement'),
              value: _isPinned,
              onChanged: (value) => setState(() => _isPinned = value),
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: _isSaving ? null : _publish,
              icon: _isSaving
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.publish_outlined),
              label: const Text('Publish'),
            ),
          ],
        ),
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
    final accent = _categoryColor(item.category, scheme);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _showAnnouncementDetail(context, item),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    accent.withValues(alpha: 0.92),
                    accent.withValues(alpha: 0.72),
                    scheme.surfaceContainerHighest,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _MetaBadge(
                        icon: item.isPinned
                            ? Icons.push_pin
                            : Icons.verified_outlined,
                        label: item.category,
                        color: Colors.white,
                        background: Colors.white.withValues(alpha: 0.16),
                      ),
                      const Spacer(),
                      if (item.createdAt != null)
                        Text(
                          DateFormat('MMM d').format(item.createdAt!),
                          style: Theme.of(
                            context,
                          ).textTheme.labelLarge?.copyWith(color: Colors.white),
                        ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text(
                    item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(
                      context,
                    ).textTheme.titleLarge?.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item.content,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
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
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _MetaBadge(
                        icon: Icons.account_circle_outlined,
                        label: item.publishedBy,
                        color: scheme.primary,
                        background: scheme.surfaceContainerHighest,
                      ),
                      if (item.createdAt != null)
                        _MetaBadge(
                          icon: Icons.schedule,
                          label: DateFormat(
                            'EEE, MMM d',
                          ).format(item.createdAt!),
                          color: scheme.primary,
                          background: scheme.surfaceContainerHighest,
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.tonalIcon(
                          onPressed: () =>
                              _showAnnouncementDetail(context, item),
                          icon: const Icon(Icons.article_outlined),
                          label: const Text('Read'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => showAiInsightSheet(
                            context: context,
                            title: 'Announcement summary',
                            prompt:
                                'Summarize announcement "${item.title}". Category: ${item.category}. Content: ${item.content}',
                          ),
                          icon: const Icon(Icons.auto_awesome),
                          label: const Text('Summarize'),
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

class _MetaBadge extends StatelessWidget {
  const _MetaBadge({
    required this.icon,
    required this.label,
    required this.color,
    required this.background,
  });

  final IconData icon;
  final String label;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
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
    );
  }
}

Color _categoryColor(String category, ColorScheme scheme) {
  switch (category.trim().toLowerCase()) {
    case 'academic':
      return scheme.primary;
    case 'events':
      return const Color(0xFF8B5CF6);
    case 'guild':
      return scheme.secondary;
    case 'urgent':
      return const Color(0xFFEF4444);
    default:
      return const Color(0xFF0F766E);
  }
}

void _showAnnouncementDetail(BuildContext context, Announcement item) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) {
      final scheme = Theme.of(context).colorScheme;
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
                      _categoryColor(item.category, scheme),
                      scheme.surfaceContainerHighest,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _MetaBadge(
                      icon: item.isPinned
                          ? Icons.push_pin
                          : Icons.verified_outlined,
                      label: item.category,
                      color: Colors.white,
                      background: Colors.white.withValues(alpha: 0.16),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      item.title,
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
                  _MetaBadge(
                    icon: Icons.account_circle_outlined,
                    label: item.publishedBy,
                    color: scheme.primary,
                    background: scheme.surfaceContainerHighest,
                  ),
                  if (item.createdAt != null)
                    _MetaBadge(
                      icon: Icons.schedule,
                      label: DateFormat(
                        'EEE, MMM d • HH:mm',
                      ).format(item.createdAt!),
                      color: scheme.primary,
                      background: scheme.surfaceContainerHighest,
                    ),
                ],
              ),
              const SizedBox(height: 18),
              Text(item.content, style: Theme.of(context).textTheme.bodyLarge),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => showAiInsightSheet(
                    context: context,
                    title: 'Announcement summary',
                    prompt:
                        'Summarize announcement "${item.title}". Category: ${item.category}. Content: ${item.content}',
                  ),
                  icon: const Icon(Icons.auto_awesome),
                  label: const Text('Summarize with AI'),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
