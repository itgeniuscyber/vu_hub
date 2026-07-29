import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vu_hub/core/widgets/app_fui_icon.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/app_page_route.dart';
import '../../../core/utils/firestore_error_message.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/feature_hero_banner.dart';
import '../../../core/widgets/firestore_error_state.dart';
import '../../../core/widgets/loading_shimmer.dart';
import '../../../core/widgets/section_header.dart';
import '../../auth/data/app_session.dart';
import '../../auth/data/user_profile.dart';
import '../data/guild_repository.dart';
import '../data/guild_models.dart';
import 'guild_cabinet_screen.dart';

class GuildHubScreen extends StatelessWidget {
  const GuildHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final session = context.watch<AppSession>();
    final canPublishGuild =
        session.role == AppUserRole.admin ||
        session.role == AppUserRole.guildOfficial;
    return Scaffold(
      floatingActionButton: canPublishGuild
          ? FloatingActionButton.extended(
              onPressed: () => _openGuildComposer(context, session),
              icon: const FUI(BoldRounded.add, width: 18, height: 18),
              label: const Text('Post notice'),
            )
          : null,
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.fromLTRB(20, 18, 20, canPublishGuild ? 96 : 24),
          children: [
            FeatureHeroBanner(
              title: 'Guild Hub',
              subtitle:
                  'Track verified student representation updates, common campus concerns, and the feedback themes that matter most.',
              icon: BoldRounded.user,
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
                    icon: BoldRounded.shieldCheck,
                    title: 'Trusted notices',
                    subtitle: 'Curated from verified resource flows',
                    width: 210,
                    gradientColors: [scheme.primary, scheme.secondary],
                  ),
                  const SizedBox(width: 12),
                  _GuildMetricCard(
                    icon: BoldRounded.megaphone,
                    title: 'Student feedback',
                    subtitle: 'Grouped into moderation-ready themes',
                    width: 224,
                    gradientColors: [scheme.secondary, scheme.tertiary],
                  ),
                  const SizedBox(width: 12),
                  _GuildMetricCard(
                    icon: BoldRounded.network,
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
                        child: FUI(
                          BoldRounded.network,
                          color: scheme.primary,
                          width: 22,
                          height: 22,
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
                      icon: const FUI(
                        BoldRounded.arrowRight,
                        width: 20,
                        height: 20,
                      ),
                      label: const Text('View full cabinet'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                const Expanded(child: SectionHeader(title: 'Guild notices')),
                if (canPublishGuild)
                  FilledButton.tonalIcon(
                    onPressed: () => _openGuildComposer(context, session),
                    icon: const FUI(BoldRounded.add, width: 17, height: 17),
                    label: const Text('Upload'),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            StreamBuilder<List<GuildNotice>>(
              stream: GuildRepository().watchNotices(),
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
                    icon: BoldRounded.user,
                    title: 'Guild feed unavailable',
                    fallbackMessage:
                        'Guild updates could not be loaded right now.',
                  );
                }
                final notices = snapshot.data ?? [];
                if (notices.isEmpty) {
                  return const EmptyState(
                    icon: BoldRounded.megaphone,
                    title: 'No guild updates yet',
                    message:
                        'Guild notices from `guild_posts` will appear here when published.',
                  );
                }
                return Column(
                  children: notices
                      .take(8)
                      .map(
                        (notice) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _GuildNoticeCard(notice: notice)
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
                            icon: const FUI(
                              BoldRounded.comment,
                              width: 18,
                              height: 18,
                            ),
                            label: const Text('Open feedback form'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {},
                            icon: const FUI(
                              BoldRounded.shield,
                              width: 18,
                              height: 18,
                            ),
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
}

class _GuildMetricCard extends StatelessWidget {
  const _GuildMetricCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.width,
    required this.gradientColors,
  });

  final String icon;
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
                child: FUI(
                  icon,
                  color: gradientColors[0],
                  width: 20,
                  height: 20,
                ),
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
            FUI(
              BoldRounded.magicWand,
              color: scheme.primary,
              width: 22,
              height: 22,
            ),
          ],
        ),
      ),
    );
  }
}

class _GuildNoticeCard extends StatelessWidget {
  const _GuildNoticeCard({required this.notice});

  final GuildNotice notice;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tone = notice.isHighPriority
        ? Colors.redAccent
        : _guildTone(notice.category, scheme);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: tone.withValues(alpha: 0.13),
                  child: FUI(
                    notice.isHighPriority
                        ? BoldRounded.exclamation
                        : BoldRounded.megaphone,
                    color: tone,
                    width: 20,
                    height: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notice.authorName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        '${notice.category} • ${_guildTimeAgo(notice.createdAt)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (notice.isPinned)
                  FUI(
                    BoldRounded.bookmark,
                    color: scheme.primary,
                    width: 18,
                    height: 18,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              notice.title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
            ),
            if (notice.body.trim().isNotEmpty) ...[
              const SizedBox(height: 7),
              Text(
                notice.body,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _GuildNoticeChip(
                  icon: BoldRounded.shieldCheck,
                  label: 'Verified guild',
                  tone: scheme.secondary,
                ),
                if (notice.isHighPriority)
                  const _GuildNoticeChip(
                    icon: BoldRounded.exclamation,
                    label: 'Priority',
                    tone: Colors.redAccent,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _GuildNoticeChip extends StatelessWidget {
  const _GuildNoticeChip({
    required this.icon,
    required this.label,
    required this.tone,
  });

  final String icon;
  final String label;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: tone.withValues(alpha: 0.1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FUI(icon, width: 14, height: 14, color: tone),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: tone,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> _openGuildComposer(
  BuildContext context,
  AppSession session,
) async {
  final user = session.firebaseUser;
  if (user == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please sign in before posting a notice.')),
    );
    return;
  }

  final published = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => _GuildNoticeComposerSheet(session: session),
  );
  if (!context.mounted || published != true) return;
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Guild notice published successfully.')),
  );
}

class _GuildNoticeComposerSheet extends StatefulWidget {
  const _GuildNoticeComposerSheet({required this.session});

  final AppSession session;

  @override
  State<_GuildNoticeComposerSheet> createState() =>
      _GuildNoticeComposerSheetState();
}

class _GuildNoticeComposerSheetState extends State<_GuildNoticeComposerSheet> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  String _category = 'Guild';
  String _priority = 'normal';
  bool _isPinned = false;
  bool _isPublishing = false;

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return SafeArea(
      top: false,
      child: ListView(
        shrinkWrap: true,
        padding: EdgeInsets.fromLTRB(20, 8, 20, bottomInset + 20),
        children: [
          Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  color: scheme.primaryContainer,
                ),
                child: FUI(
                  BoldRounded.megaphone,
                  width: 24,
                  height: 24,
                  color: scheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Post guild notice',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Publish a verified update for students.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          TextField(
            controller: _titleController,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              prefixIcon: FUI(BoldRounded.bookmark),
              labelText: 'Notice title',
              hintText: 'e.g. Guild meeting reminder',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _bodyController,
            minLines: 4,
            maxLines: 7,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              prefixIcon: FUI(BoldRounded.comment),
              labelText: 'Notice message',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _category,
                  decoration: const InputDecoration(
                    prefixIcon: FUI(BoldRounded.grid),
                    labelText: 'Category',
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Guild', child: Text('Guild')),
                    DropdownMenuItem(
                      value: 'Academic',
                      child: Text('Academic'),
                    ),
                    DropdownMenuItem(value: 'Events', child: Text('Events')),
                    DropdownMenuItem(value: 'Welfare', child: Text('Welfare')),
                    DropdownMenuItem(value: 'Urgent', child: Text('Urgent')),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _category = value);
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _priority,
                  decoration: const InputDecoration(
                    prefixIcon: FUI(BoldRounded.exclamation),
                    labelText: 'Priority',
                  ),
                  items: const [
                    DropdownMenuItem(value: 'normal', child: Text('Normal')),
                    DropdownMenuItem(value: 'high', child: Text('High')),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _priority = value);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _isPinned,
            onChanged: (value) => setState(() => _isPinned = value),
            title: const Text('Pin as important guild update'),
            subtitle: const Text('Useful for deadlines or urgent notices.'),
            secondary: FUI(
              BoldRounded.bookmark,
              width: 20,
              height: 20,
              color: _isPinned ? scheme.primary : scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _isPublishing ? null : _publish,
              icon: _isPublishing
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: scheme.onPrimary,
                      ),
                    )
                  : const FUI(BoldRounded.upload, width: 18, height: 18),
              label: Text(_isPublishing ? 'Publishing...' : 'Publish notice'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _publish() async {
    final title = _titleController.text.trim();
    final body = _bodyController.text.trim();
    if (title.isEmpty || body.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add a title and message first.')),
      );
      return;
    }

    final user = widget.session.firebaseUser;
    if (user == null) return;
    setState(() => _isPublishing = true);
    try {
      await GuildRepository().publishNotice(
        title: title,
        body: body,
        category: _category,
        priority: _priority,
        isPinned: _isPinned,
        authorId: user.uid,
        authorName:
            widget.session.profile?.displayName ??
            user.displayName ??
            user.email ??
            'VU Guild',
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _isPublishing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            describeFirestoreError(
              error,
              fallback: 'We could not publish this guild notice.',
            ),
          ),
        ),
      );
    }
  }
}

Color _guildTone(String category, ColorScheme scheme) {
  switch (category.toLowerCase()) {
    case 'academic':
      return scheme.primary;
    case 'events':
      return const Color(0xFF8B5CF6);
    case 'welfare':
      return const Color(0xFF22C55E);
    case 'urgent':
      return Colors.redAccent;
    default:
      return scheme.secondary;
  }
}

String _guildTimeAgo(DateTime? date) {
  if (date == null) return 'just now';
  final diff = DateTime.now().difference(date);
  if (diff.inMinutes < 1) return 'just now';
  if (diff.inHours < 1) return '${diff.inMinutes}m ago';
  if (diff.inDays < 1) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  return '${date.day}/${date.month}/${date.year}';
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
