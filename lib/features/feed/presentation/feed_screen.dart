import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vu_hub/core/widgets/app_fui_icon.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/utils/firestore_error_message.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/firestore_error_state.dart';
import '../../../core/widgets/loading_shimmer.dart';
import '../../ai_desk/presentation/ai_insight_sheet.dart';
import '../../auth/data/app_session.dart';
import '../../auth/data/user_profile.dart';
import '../data/announcement.dart';
import '../data/announcement_repository.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final _repository = AnnouncementRepository();
  final Map<String, int> _localLikes = {};
  final Set<String> _savedPosts = {};
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
      backgroundColor: scheme.surface,
      body: SafeArea(
        bottom: false,
        child: StreamBuilder<List<Announcement>>(
          stream: _repository.watchLatest(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const _PulseLoading();
            }
            if (snapshot.hasError) {
              return FirestoreErrorState(
                error: snapshot.error!,
                title: 'Could not load VU Feed',
                fallbackMessage: 'The campus feed is unavailable right now.',
              );
            }

            final allItems = snapshot.data ?? [];
            final items = _filterItems(allItems);
            final pinned = allItems
                .where((item) => item.isPinned)
                .take(6)
                .toList();
            final featured = pinned.isNotEmpty
                ? pinned.first
                : allItems.isNotEmpty
                ? allItems.first
                : null;

            return RefreshIndicator(
              onRefresh: () async => Future<void>.delayed(450.ms),
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverAppBar(
                    pinned: true,
                    floating: true,
                    elevation: 0,
                    backgroundColor: scheme.surface.withValues(alpha: 0.96),
                    surfaceTintColor: Colors.transparent,
                    titleSpacing: 20,
                    title: const _PulseWordmark(),
                    actions: [
                      IconButton(
                        tooltip: 'Search',
                        onPressed: () => _openSearchSheet(context),
                        icon: const FUI(BoldRounded.search),
                      ),
                      if (session.canPublishAnnouncements)
                        IconButton.filledTonal(
                          tooltip: 'Create post',
                          onPressed: () => _openPublisher(context, session),
                          icon: const FUI(BoldRounded.add),
                        ),
                      const SizedBox(width: 12),
                    ],
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    sliver: SliverToBoxAdapter(
                      child: _PulseStories(
                        selected: _selectedCategory,
                        items: allItems,
                        canPublish: session.canPublishAnnouncements,
                        onCreate: () => _openPublisher(context, session),
                        onSelected: (value) =>
                            setState(() => _selectedCategory = value),
                      ),
                    ),
                  ),
                  if (featured != null)
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
                      sliver: SliverToBoxAdapter(
                        child:
                            _FeaturedPulseCard(
                                  item: featured,
                                  onOpen: () => _showPostDetail(
                                    context,
                                    featured,
                                    _repository,
                                    session,
                                  ),
                                )
                                .animate()
                                .fadeIn(duration: 320.ms)
                                .slideY(begin: 0.04),
                      ),
                    ),
                  if (items.isEmpty)
                    const SliverPadding(
                      padding: EdgeInsets.fromLTRB(24, 26, 24, 32),
                      sliver: SliverToBoxAdapter(
                        child: EmptyState(
                          icon: BoldRounded.megaphone,
                          title: 'No Pulse posts yet',
                          message:
                              'Official campus posts matching your filters will appear here.',
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 96),
                      sliver: SliverList.separated(
                        itemBuilder: (context, index) {
                          final item = items[index];
                          return _PulsePostCard(
                                item: item,
                                likedCount:
                                    item.likeCount +
                                    (_localLikes[item.id] ?? 0),
                                isSaved: _savedPosts.contains(item.id),
                                onLike: () => _like(item),
                                onComment: () => _showPostDetail(
                                  context,
                                  item,
                                  _repository,
                                  session,
                                ),
                                onShare: () => _share(item),
                                onSave: () => _toggleSave(item),
                                onOpen: () => _showPostDetail(
                                  context,
                                  item,
                                  _repository,
                                  session,
                                ),
                              )
                              .animate()
                              .fadeIn(duration: 260.ms)
                              .slideY(begin: 0.03);
                        },
                        separatorBuilder: (_, _) => const SizedBox(height: 18),
                        itemCount: items.length,
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  List<Announcement> _filterItems(List<Announcement> allItems) {
    return allItems
        .where(
          (item) =>
              _selectedCategory == 'All' ||
              item.category.toLowerCase() == _selectedCategory.toLowerCase(),
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
  }

  Future<void> _like(Announcement item) async {
    setState(() {
      _localLikes[item.id] = (_localLikes[item.id] ?? 0) + 1;
    });
    try {
      await _repository.like(item.id);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        final next = (_localLikes[item.id] ?? 1) - 1;
        if (next <= 0) {
          _localLikes.remove(item.id);
        } else {
          _localLikes[item.id] = next;
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            describeFirestoreError(
              error,
              fallback: 'We could not record that like.',
            ),
          ),
        ),
      );
    }
  }

  void _toggleSave(Announcement item) {
    setState(() {
      if (_savedPosts.contains(item.id)) {
        _savedPosts.remove(item.id);
      } else {
        _savedPosts.add(item.id);
      }
    });
  }

  Future<void> _share(Announcement item) async {
    final message = [
      'VU Feed: ${item.title}',
      if (item.content.trim().isNotEmpty) item.content,
      'Posted by ${item.publishedBy}',
      if (item.linkUrl.trim().isNotEmpty) item.linkUrl,
      'Open VU Hub > Feed to view more campus updates.',
    ].join('\n');
    await SharePlus.instance.share(
      ShareParams(text: message, subject: item.title),
    );
  }

  void _openSearchSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            8,
            20,
            MediaQuery.viewInsetsOf(context).bottom + 24,
          ),
          child: TextField(
            autofocus: true,
            onChanged: (value) => setState(() => _query = value.trim()),
            decoration: const InputDecoration(
              prefixIcon: FUI(BoldRounded.search),
              labelText: 'Search VU Feed',
              hintText: 'Events, deadlines, guild, lecturer...',
            ),
          ),
        );
      },
    );
  }

  Future<void> _openPublisher(BuildContext context, AppSession session) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => _AnnouncementComposerSheet(session: session),
    );
    if (!context.mounted || result != true) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('VU Feed post published.')));
  }
}

class _PulseLoading extends StatelessWidget {
  const _PulseLoading();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
      children: const [
        LoadingShimmer(height: 48),
        SizedBox(height: 16),
        LoadingShimmer(height: 84),
        SizedBox(height: 18),
        LoadingShimmer(height: 220),
        SizedBox(height: 16),
        LoadingShimmer(height: 360),
        SizedBox(height: 16),
        LoadingShimmer(height: 320),
      ],
    );
  }
}

class _PulseWordmark extends StatelessWidget {
  const _PulseWordmark();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: scheme.primary,
          ),
          child: FUI(
            BoldRounded.megaphone,
            color: scheme.onPrimary,
            width: 21,
            height: 21,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          'VU Feed',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }
}

class _PulseStories extends StatelessWidget {
  const _PulseStories({
    required this.selected,
    required this.items,
    required this.canPublish,
    required this.onCreate,
    required this.onSelected,
  });

  final String selected;
  final List<Announcement> items;
  final bool canPublish;
  final VoidCallback onCreate;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final categories = _FeedScreenState._categories;
    final extraCreateItem = canPublish ? 1 : 0;
    return SizedBox(
      height: 82,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length + extraCreateItem,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          if (canPublish && index == 0) {
            return _PulseCategoryPill(
              label: 'Create',
              icon: BoldRounded.add,
              selected: false,
              onTap: onCreate,
              count: 0,
            );
          }
          final label = categories[index - extraCreateItem];
          final isAll = label == 'All';
          final count = items.where((item) {
            return isAll || item.category.toLowerCase() == label.toLowerCase();
          }).length;
          return _PulseCategoryPill(
            label: label,
            icon: _categoryFuiIcon(label),
            selected: selected == label,
            onTap: () => onSelected(label),
            count: count,
          );
        },
      ),
    );
  }
}

class _PulseCategoryPill extends StatelessWidget {
  const _PulseCategoryPill({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
    required this.count,
  });

  final String label;
  final String icon;
  final bool selected;
  final VoidCallback onTap;
  final int count;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = _categoryColor(label, scheme);
    final ringBase = selected ? scheme.primary : scheme.outlineVariant;
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: SizedBox(
        width: 70,
        child: Column(
          children: [
            AnimatedContainer(
              duration: 180.ms,
              width: 52,
              height: 52,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: SweepGradient(
                  colors: [ringBase, accent, const Color(0xFFFFC107), ringBase],
                ),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: accent.withValues(alpha: 0.26),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ]
                    : null,
              ),
              child: CircleAvatar(
                backgroundColor: scheme.surface,
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    FUI(
                      icon,
                      color: selected ? scheme.primary : accent,
                      width: 20,
                      height: 20,
                      semanticLabel: label,
                    ),
                    if (count > 0)
                      Positioned(
                        right: -8,
                        bottom: -6,
                        child: Container(
                          constraints: const BoxConstraints(minWidth: 20),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: scheme.primary,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: scheme.surface, width: 2),
                          ),
                          child: Text(
                            _compactCount(count),
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: scheme.onPrimary,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 10,
                                  height: 1,
                                ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: scheme.onSurface,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
                fontSize: 11,
              ),
            ),
            if (selected)
              Container(
                margin: const EdgeInsets.only(top: 4),
                width: 16,
                height: 2.5,
                decoration: BoxDecoration(
                  color: scheme.primary,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _FeaturedPulseCard extends StatelessWidget {
  const _FeaturedPulseCard({required this.item, required this.onOpen});

  final Announcement item;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(28),
      onTap: onOpen,
      child: Container(
        height: 220,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          color: scheme.surfaceContainerHighest,
          image: item.imageUrl.isEmpty
              ? null
              : DecorationImage(
                  image: CachedNetworkImageProvider(item.imageUrl),
                  fit: BoxFit.cover,
                ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: item.imageUrl.isEmpty
                        ? _pulseGradientColors(item.category)
                        : [
                            Colors.black.withValues(alpha: 0.08),
                            Colors.black.withValues(alpha: 0.78),
                          ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
            Positioned(
              left: 18,
              right: 18,
              bottom: 18,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _GlassBadge(
                    icon: item.isPinned
                        ? BoldRounded.bookmark
                        : _categoryFuiIcon(item.category),
                    label: item.isPinned
                        ? 'Pinned ${item.category}'
                        : item.category,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.content,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.86),
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

class _PulsePostCard extends StatelessWidget {
  const _PulsePostCard({
    required this.item,
    required this.likedCount,
    required this.isSaved,
    required this.onLike,
    required this.onComment,
    required this.onShare,
    required this.onSave,
    required this.onOpen,
  });

  final Announcement item;
  final int likedCount;
  final bool isSaved;
  final VoidCallback onLike;
  final VoidCallback onComment;
  final VoidCallback onShare;
  final VoidCallback onSave;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final role = item.authorRole.isEmpty
        ? _roleForCategory(item.category)
        : item.authorRole;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? scheme.surfaceContainerLowest
            : Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.45),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: Theme.of(context).brightness == Brightness.dark
                  ? 0.22
                  : 0.06,
            ),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onOpen,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 10, 10),
                  child: Row(
                    children: [
                      _AuthorAvatar(item: item),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    item.publishedBy,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(
                                          color: scheme.onSurface,
                                          fontWeight: FontWeight.w900,
                                        ),
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Icon(
                                  Icons.verified_rounded,
                                  size: 16,
                                  color: _categoryColor(item.category, scheme),
                                ),
                              ],
                            ),
                            Text(
                              '$role • ${_timeAgo(item.createdAt)}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: scheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'More',
                        onPressed: () => _showPostActions(context, item),
                        icon: FUI(
                          BoldRounded.menuDots,
                          color: scheme.onSurfaceVariant,
                          width: 20,
                          height: 20,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
                  child: Text(
                    item.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: scheme.onSurface,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                if (item.content.trim().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                    child: Text(
                      item.content,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: _PulseMedia(item: item),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 6, 8, 0),
                  child: Row(
                    children: [
                      _PulseIconButton(
                        icon: RegularRounded.heart,
                        activeIcon: SolidRounded.heart,
                        active: likedCount > item.likeCount,
                        activeColor: const Color(0xFFE11D48),
                        onTap: onLike,
                      ),
                      _PulseIconButton(
                        icon: RegularRounded.comment,
                        onTap: onComment,
                      ),
                      _PulseIconButton(
                        icon: RegularRounded.paperPlane,
                        onTap: onShare,
                      ),
                      const Spacer(),
                      _PulseIconButton(
                        icon: RegularRounded.bookmark,
                        activeIcon: SolidRounded.bookmark,
                        active: isSaved,
                        activeColor: scheme.primary,
                        onTap: onSave,
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_compactCount(likedCount)} likes • ${_compactCount(item.commentCount)} comments • ${_compactCount(item.viewCount)} views',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: scheme.onSurface,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _PostChip(
                            icon: _categoryFuiIcon(item.category),
                            label: item.category,
                          ),
                          if (item.isPinned)
                            const _PostChip(
                              icon: BoldRounded.bookmark,
                              label: 'Pinned',
                            ),
                          if (item.linkUrl.isNotEmpty)
                            _PostChip(
                              icon: BoldRounded.link,
                              label: 'Open link',
                              onTap: () => _launchLink(item.linkUrl),
                            ),
                        ],
                      ),
                    ],
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

class _AuthorAvatar extends StatelessWidget {
  const _AuthorAvatar({required this.item});

  final Announcement item;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (item.authorAvatarUrl.isNotEmpty) {
      return CircleAvatar(
        radius: 22,
        backgroundImage: CachedNetworkImageProvider(item.authorAvatarUrl),
      );
    }
    return CircleAvatar(
      radius: 22,
      backgroundColor: _categoryColor(
        item.category,
        scheme,
      ).withValues(alpha: 0.14),
      child: FUI(
        _categoryFuiIcon(item.category),
        color: _categoryColor(item.category, scheme),
        width: 22,
        height: 22,
      ),
    );
  }
}

class _PulseMedia extends StatelessWidget {
  const _PulseMedia({required this.item});

  final Announcement item;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = _categoryColor(item.category, scheme);
    return AspectRatio(
      aspectRatio: 1.08,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (item.imageUrl.isNotEmpty)
              CachedNetworkImage(
                imageUrl: item.imageUrl,
                fit: BoxFit.cover,
                errorWidget: (_, _, _) => _GeneratedPulseVisual(item: item),
              )
            else
              _GeneratedPulseVisual(item: item),
            Positioned(
              left: 12,
              top: 12,
              child: _GlassBadge(
                icon: _categoryFuiIcon(item.category),
                label: item.category,
              ),
            ),
            if (item.isPinned)
              const Positioned(
                right: 12,
                top: 12,
                child: _GlassBadge(icon: BoldRounded.bookmark, label: 'Pinned'),
              ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 84,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      accent.withValues(alpha: 0.56),
                      Colors.black.withValues(alpha: 0.55),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GeneratedPulseVisual extends StatelessWidget {
  const _GeneratedPulseVisual({required this.item});

  final Announcement item;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _pulseGradientColors(item.category),
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -26,
            top: -20,
            child: FUI(
              _categoryFuiIcon(item.category),
              color: Colors.white.withValues(alpha: 0.18),
              width: 168,
              height: 168,
            ),
          ),
          Positioned(
            left: 22,
            right: 22,
            bottom: 22,
            child: Text(
              item.title,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PulseIconButton extends StatelessWidget {
  const _PulseIconButton({
    required this.icon,
    required this.onTap,
    this.activeIcon,
    this.active = false,
    this.activeColor,
  });

  final String icon;
  final String? activeIcon;
  final VoidCallback onTap;
  final bool active;
  final Color? activeColor;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      icon: AnimatedSwitcher(
        duration: 180.ms,
        child: FUI(
          active ? activeIcon ?? icon : icon,
          key: ValueKey(active),
          color: active ? activeColor : null,
          width: 23,
          height: 23,
        ),
      ),
    );
  }
}

class _PostChip extends StatelessWidget {
  const _PostChip({required this.icon, required this.label, this.onTap});

  final String icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ActionChip(
      avatar: FUI(icon, width: 16, height: 16),
      label: Text(label),
      onPressed: onTap,
      backgroundColor: scheme.surfaceContainerHighest,
      side: BorderSide.none,
      visualDensity: VisualDensity.compact,
    );
  }
}

class _GlassBadge extends StatelessWidget {
  const _GlassBadge({required this.icon, required this.label});

  final String icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.38),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FUI(icon, color: Colors.white, width: 15, height: 15),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _PulseImagePickerTile extends StatelessWidget {
  const _PulseImagePickerTile({
    required this.file,
    required this.onPick,
    required this.onRemove,
  });

  final PlatformFile? file;
  final VoidCallback? onPick;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bytes = file?.bytes;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? scheme.surfaceContainerHighest
            : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: SizedBox(
                width: 72,
                height: 72,
                child: bytes == null
                    ? ColoredBox(
                        color: scheme.surface,
                        child: FUI(
                          BoldRounded.picture,
                          color: scheme.primary,
                          width: 26,
                          height: 26,
                        ),
                      )
                    : Image.memory(bytes, fit: BoxFit.cover),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    file == null ? 'Upload from device' : file!.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: scheme.onSurface,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    file == null
                        ? 'Use a poster, notice artwork, or campus photo.'
                        : 'This image will be uploaded to Firebase Storage.',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      FilledButton.tonalIcon(
                        onPressed: onPick,
                        icon: const FUI(
                          BoldRounded.picture,
                          width: 18,
                          height: 18,
                        ),
                        label: Text(file == null ? 'Choose image' : 'Change'),
                      ),
                      if (file != null)
                        IconButton.filledTonal(
                          tooltip: 'Remove image',
                          onPressed: onRemove,
                          icon: const FUI(BoldRounded.cross),
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

class _ComposerCategoryPicker extends StatelessWidget {
  const _ComposerCategoryPicker({
    required this.selected,
    required this.onSelected,
  });

  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final categories = _FeedScreenState._categories
        .where((item) => item != 'All')
        .toList();
    return LayoutBuilder(
      builder: (context, constraints) {
        final spacing = 8.0;
        final itemWidth = (constraints.maxWidth - spacing) / 2;
        return Wrap(
          spacing: spacing,
          runSpacing: 8,
          children: categories.map((category) {
            return SizedBox(
              width: itemWidth,
              child: _ComposerCategoryChip(
                category: category,
                selected: selected == category,
                onTap: () => onSelected(category),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _ComposerCategoryChip extends StatelessWidget {
  const _ComposerCategoryChip({
    required this.category,
    required this.selected,
    required this.onTap,
  });

  final String category;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = _categoryColor(category, scheme);
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: AnimatedContainer(
        duration: 160.ms,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? accent.withValues(alpha: 0.14)
              : scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? accent : scheme.outlineVariant,
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Row(
          children: [
            FUI(
              _categoryFuiIcon(category),
              color: accent,
              width: 19,
              height: 19,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                category,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: scheme.onSurface,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            if (selected)
              FUI(SolidRounded.check, color: accent, width: 18, height: 18),
          ],
        ),
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
  final _imageController = TextEditingController();
  final _linkController = TextEditingController();
  PlatformFile? _selectedImage;
  String _category = 'General';
  bool _isPinned = false;
  bool _isSaving = false;
  String? _publishError;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _imageController.dispose();
    _linkController.dispose();
    super.dispose();
  }

  Future<void> _publish() async {
    if (!_formKey.currentState!.validate()) return;
    final user = widget.session.firebaseUser;
    if (user == null) {
      setState(() {
        _publishError = 'Please sign in again before publishing.';
      });
      return;
    }
    setState(() {
      _isSaving = true;
      _publishError = null;
    });
    final profile = widget.session.profile;
    try {
      await AnnouncementRepository().publishAnnouncement(
        title: _titleController.text,
        content: _contentController.text,
        category: _category,
        publishedBy:
            profile?.displayName ??
            widget.session.firebaseUser?.email ??
            'VU Publisher',
        authorId: user.uid,
        authorRole: _roleLabel(profile?.role ?? AppUserRole.student),
        imageUrl: _imageController.text,
        imageFile: _selectedImage,
        linkUrl: _linkController.text,
        isPinned: _isPinned,
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _publishError = _describePublishError(error);
        _isSaving = false;
      });
    }
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
      withData: true,
    );
    final file = result?.files.single;
    if (file == null) return;
    if ((file.bytes == null || file.bytes!.isEmpty) && file.path == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('We could not read that image.')),
      );
      return;
    }
    setState(() => _selectedImage = file);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        8,
        20,
        MediaQuery.of(context).viewInsets.bottom + 22,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: scheme.primaryContainer,
                    child: FUI(
                      BoldRounded.megaphone,
                      color: scheme.primary,
                      width: 22,
                      height: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Create VU Feed post',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        Text(
                          'Admins, lecturers, and guild officials can publish.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _ComposerCategoryPicker(
                selected: _category,
                onSelected: (value) => setState(() => _category = value),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Headline',
                  hintText: 'Orientation week schedule is out',
                ),
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'Enter a headline'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _contentController,
                minLines: 4,
                maxLines: 8,
                decoration: const InputDecoration(
                  labelText: 'Caption',
                  hintText: 'Share the update students need to see...',
                ),
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'Enter post caption'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _imageController,
                keyboardType: TextInputType.url,
                decoration: const InputDecoration(
                  labelText: 'Image URL',
                  hintText: 'Paste image link, or pick from device below',
                  prefixIcon: FUI(BoldRounded.picture),
                ),
              ),
              const SizedBox(height: 10),
              _PulseImagePickerTile(
                file: _selectedImage,
                onPick: _isSaving ? null : _pickImage,
                onRemove: _isSaving
                    ? null
                    : () => setState(() => _selectedImage = null),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _linkController,
                keyboardType: TextInputType.url,
                decoration: const InputDecoration(
                  labelText: 'Action link',
                  hintText: 'Optional event, resource, or form link',
                  prefixIcon: FUI(BoldRounded.link),
                ),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Pin as campus highlight'),
                subtitle: const Text(
                  'Use for urgent or high-priority updates.',
                ),
                value: _isPinned,
                onChanged: (value) => setState(() => _isPinned = value),
              ),
              if (_publishError != null) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: scheme.errorContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    _publishError!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onErrorContainer,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _isSaving ? null : _publish,
                  icon: _isSaving
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const FUI(BoldRounded.upload, width: 18, height: 18),
                  label: const Text('Publish to VU Feed'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void _showPostDetail(
  BuildContext context,
  Announcement item,
  AnnouncementRepository repository,
  AppSession session,
) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) {
      final scheme = Theme.of(context).colorScheme;
      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.82,
        minChildSize: 0.45,
        maxChildSize: 0.94,
        builder: (context, controller) {
          return ListView(
            controller: controller,
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            children: [
              _PulseMedia(item: item),
              const SizedBox(height: 18),
              Row(
                children: [
                  _AuthorAvatar(item: item),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.publishedBy,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        Text(
                          '${item.authorRole.isEmpty ? _roleForCategory(item.category) : item.authorRole} • ${_dateLabel(item.createdAt)}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  _PostChip(
                    icon: _categoryFuiIcon(item.category),
                    label: item.category,
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                item.title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              Text(item.content, style: Theme.of(context).textTheme.bodyLarge),
              const SizedBox(height: 18),
              if (item.linkUrl.isNotEmpty)
                FilledButton.icon(
                  onPressed: () => _launchLink(item.linkUrl),
                  icon: const FUI(BoldRounded.link, width: 18, height: 18),
                  label: const Text('Open attached link'),
                ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () => showAiInsightSheet(
                  context: context,
                  title: 'VU Feed summary',
                  prompt:
                      'Summarize this VU Feed post for students. Title: ${item.title}. Category: ${item.category}. Content: ${item.content}',
                ),
                icon: const FUI(BoldRounded.magicWand, width: 18, height: 18),
                label: const Text('Summarize with AI'),
              ),
              const SizedBox(height: 14),
              Divider(color: scheme.outlineVariant),
              const SizedBox(height: 14),
              Text(
                'Campus replies',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 12),
              StreamBuilder<List<AnnouncementComment>>(
                stream: repository.watchComments(item.id),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: LoadingShimmer(height: 82),
                    );
                  }
                  if (snapshot.hasError) {
                    return Text(
                      describeFirestoreError(
                        snapshot.error!,
                        fallback: 'Comments are unavailable right now.',
                      ),
                      style: Theme.of(context).textTheme.bodyMedium,
                    );
                  }
                  final comments = snapshot.data ?? const [];
                  if (comments.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Text(
                        'No replies yet. Start the conversation for this campus update.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    );
                  }
                  return Column(
                    children: comments
                        .map(
                          (comment) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _PulseCommentTile(comment: comment),
                          ),
                        )
                        .toList(),
                  );
                },
              ),
              const SizedBox(height: 12),
              _PulseCommentComposer(
                repository: repository,
                item: item,
                session: session,
              ),
            ],
          );
        },
      );
    },
  );
}

class _PulseCommentTile extends StatelessWidget {
  const _PulseCommentTile({required this.comment});

  final AnnouncementComment comment;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 17,
          backgroundColor: scheme.primaryContainer,
          child: Text(
            comment.displayName.trim().isEmpty
                ? 'V'
                : comment.displayName.trim()[0].toUpperCase(),
            style: TextStyle(
              color: scheme.onPrimaryContainer,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          comment.displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                      ),
                      Text(
                        _timeAgo(comment.createdAt),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(comment.text),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PulseCommentComposer extends StatefulWidget {
  const _PulseCommentComposer({
    required this.repository,
    required this.item,
    required this.session,
  });

  final AnnouncementRepository repository;
  final Announcement item;
  final AppSession session;

  @override
  State<_PulseCommentComposer> createState() => _PulseCommentComposerState();
}

class _PulseCommentComposerState extends State<_PulseCommentComposer> {
  final _controller = TextEditingController();
  bool _isSending = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isSending) return;
    setState(() => _isSending = true);
    final name =
        widget.session.profile?.displayName ??
        widget.session.firebaseUser?.displayName ??
        widget.session.firebaseUser?.email ??
        'VU Student';
    try {
      await widget.repository.sendComment(
        announcementId: widget.item.id,
        text: text,
        displayName: name,
      );
      _controller.clear();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            describeFirestoreError(
              error,
              fallback: 'We could not send this comment.',
            ),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      minLines: 1,
      maxLines: 4,
      textInputAction: TextInputAction.send,
      onSubmitted: (_) => _send(),
      decoration: InputDecoration(
        hintText: 'Reply to this update...',
        prefixIcon: const FUI(BoldRounded.comment),
        suffixIcon: IconButton.filled(
          tooltip: 'Send reply',
          onPressed: _isSending ? null : _send,
          icon: _isSending
              ? const SizedBox.square(
                  dimension: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const FUI(BoldRounded.paperPlane),
        ),
      ),
    );
  }
}

void _showPostActions(BuildContext context, Announcement item) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const FUI(BoldRounded.magicWand),
              title: const Text('Summarize with AI'),
              onTap: () {
                Navigator.pop(context);
                showAiInsightSheet(
                  context: context,
                  title: 'VU Feed summary',
                  prompt:
                      'Summarize this VU Feed post for students. Title: ${item.title}. Category: ${item.category}. Content: ${item.content}',
                );
              },
            ),
            if (item.linkUrl.isNotEmpty)
              ListTile(
                leading: const FUI(BoldRounded.link),
                title: const Text('Open attached link'),
                onTap: () {
                  Navigator.pop(context);
                  _launchLink(item.linkUrl);
                },
              ),
            const ListTile(
              leading: FUI(BoldRounded.flag),
              title: Text('Report post'),
            ),
          ],
        ),
      );
    },
  );
}

Future<void> _launchLink(String value) async {
  final uri = Uri.tryParse(value);
  if (uri == null) return;
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}

String _categoryFuiIcon(String category) {
  switch (category.trim().toLowerCase()) {
    case 'all':
      return BoldRounded.grid;
    case 'academic':
      return BoldRounded.book;
    case 'events':
      return BoldRounded.calendar;
    case 'guild':
      return BoldRounded.user;
    case 'urgent':
      return BoldRounded.exclamation;
    case 'general':
      return BoldRounded.megaphone;
    default:
      return BoldRounded.megaphone;
  }
}

Color _categoryColor(String category, ColorScheme scheme) {
  switch (category.trim().toLowerCase()) {
    case 'all':
      return const Color(0xFF2563EB);
    case 'academic':
      return const Color(0xFF2563EB);
    case 'events':
      return const Color(0xFF7C3AED);
    case 'guild':
      return const Color(0xFF0891B2);
    case 'urgent':
      return const Color(0xFFE11D48);
    case 'general':
      return const Color(0xFF059669);
    default:
      return scheme.primary;
  }
}

List<Color> _pulseGradientColors(String category) {
  switch (category.trim().toLowerCase()) {
    case 'academic':
      return const [Color(0xFF1D4ED8), Color(0xFF0F766E), Color(0xFF312E81)];
    case 'events':
      return const [Color(0xFF7C3AED), Color(0xFFBE123C), Color(0xFF0F172A)];
    case 'guild':
      return const [Color(0xFF0891B2), Color(0xFF1D4ED8), Color(0xFF581C87)];
    case 'urgent':
      return const [Color(0xFFE11D48), Color(0xFFEA580C), Color(0xFF1E1B4B)];
    case 'general':
      return const [Color(0xFF059669), Color(0xFF0E7490), Color(0xFF1E3A8A)];
    default:
      return const [Color(0xFF2563EB), Color(0xFF0891B2), Color(0xFF312E81)];
  }
}

String _roleForCategory(String category) {
  switch (category.trim().toLowerCase()) {
    case 'academic':
      return 'Lecturer';
    case 'guild':
      return 'Guild official';
    case 'urgent':
      return 'Admin notice';
    default:
      return 'Campus publisher';
  }
}

String _roleLabel(AppUserRole role) {
  switch (role) {
    case AppUserRole.admin:
      return 'Admin';
    case AppUserRole.lecturer:
      return 'Lecturer';
    case AppUserRole.guildOfficial:
      return 'Guild official';
    case AppUserRole.student:
    case AppUserRole.unknown:
      return 'Campus publisher';
  }
}

String _describePublishError(Object error) {
  final message = describeFirestoreError(
    error,
    fallback: 'We could not publish this VU Feed post.',
  );
  if (message != 'We could not publish this VU Feed post.') {
    return message;
  }
  final raw = error.toString().replaceFirst('Exception: ', '').trim();
  if (raw.isNotEmpty) return raw;
  return message;
}

String _timeAgo(DateTime? date) {
  if (date == null) return 'Just now';
  final now = DateTime.now();
  final diff = now.difference(date);
  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inHours < 1) return '${diff.inMinutes}m ago';
  if (diff.inDays < 1) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  return DateFormat('MMM d').format(date);
}

String _dateLabel(DateTime? date) {
  if (date == null) return 'Just now';
  return DateFormat('EEE, MMM d • HH:mm').format(date);
}

String _compactCount(int value) {
  if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
  if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}K';
  return '$value';
}
