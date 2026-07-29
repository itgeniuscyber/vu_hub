import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:vu_hub/core/widgets/app_fui_icon.dart';

import '../../../core/utils/firestore_error_message.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/firestore_error_state.dart';
import '../../../core/widgets/loading_shimmer.dart';
import '../../../core/widgets/section_header.dart';
import '../../auth/data/app_session.dart';
import '../../auth/data/user_profile.dart';
import '../../feed/data/announcement.dart';
import '../../guild/data/guild_repository.dart';
import '../../live/data/live_post.dart';
import '../data/admin_repository.dart';

enum _AdminSection { feed, guild, live, users }

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final _repository = AdminRepository();
  _AdminSection _section = _AdminSection.feed;

  @override
  Widget build(BuildContext context) {
    final session = context.watch<AppSession>();
    final scheme = Theme.of(context).colorScheme;
    final isAdmin = session.role == AppUserRole.admin;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          children: [
            Row(
              children: [
                IconButton.filledTonal(
                  tooltip: 'Back',
                  onPressed: () => Navigator.maybePop(context),
                  icon: const FUI(BoldRounded.arrowLeft, width: 20, height: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Admin Center',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            _AdminHero(isAdmin: isAdmin),
            const SizedBox(height: 18),
            if (!isAdmin)
              const EmptyState(
                icon: BoldRounded.lock,
                title: 'Admin access required',
                message:
                    'Only verified administrators can manage campus-wide activity.',
              )
            else ...[
              StreamBuilder<AdminOverview>(
                stream: _repository.watchOverview(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return FirestoreErrorState(
                      error: snapshot.error!,
                      icon: BoldRounded.chartPie,
                      title: 'Overview unavailable',
                      fallbackMessage: 'Admin activity counts could not load.',
                    );
                  }
                  final overview = snapshot.data;
                  if (overview == null) {
                    return const SizedBox(
                      height: 112,
                      child: LoadingShimmer(height: 112),
                    );
                  }
                  return _OverviewStrip(overview: overview);
                },
              ),
              const SizedBox(height: 22),
              const SectionHeader(title: 'Manage activity'),
              const SizedBox(height: 12),
              _AdminSectionSelector(
                selected: _section,
                onChanged: (value) => setState(() => _section = value),
              ),
              const SizedBox(height: 16),
              AnimatedSwitcher(
                duration: 220.ms,
                child: KeyedSubtree(
                  key: ValueKey(_section),
                  child: _buildSection(context, session),
                ),
              ),
              const SizedBox(height: 20),
              Card(
                color: scheme.primaryContainer.withValues(alpha: 0.45),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      FUI(
                        BoldRounded.shieldCheck,
                        color: scheme.primary,
                        width: 24,
                        height: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Admin actions update Firebase directly. Use delete carefully, especially for live posts and public notices.',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: scheme.onSurface),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, AppSession session) {
    switch (_section) {
      case _AdminSection.feed:
        return _FeedAdminList(repository: _repository);
      case _AdminSection.guild:
        return _GuildAdminList(repository: _repository);
      case _AdminSection.live:
        return _LiveAdminList(repository: _repository);
      case _AdminSection.users:
        return _UsersAdminList(repository: _repository, session: session);
    }
  }
}

class _AdminHero extends StatelessWidget {
  const _AdminHero({required this.isAdmin});

  final bool isAdmin;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: LinearGradient(
          colors: [
            const Color(0xFF0EA5E9),
            scheme.primary,
            const Color(0xFF8B5CF6),
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
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const FUI(
                  BoldRounded.shieldCheck,
                  width: 28,
                  height: 28,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              _AdminStatusPill(active: isAdmin),
            ],
          ),
          const SizedBox(height: 28),
          Text(
            'Campus control room',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Review posts, guild notices, live sessions, and user roles from one secure dashboard.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.86),
              height: 1.35,
              fontSize: 15,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 280.ms).slideY(begin: 0.04, end: 0);
  }
}

class _AdminStatusPill extends StatelessWidget {
  const _AdminStatusPill({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FUI(
            active ? BoldRounded.check : BoldRounded.lock,
            width: 14,
            height: 14,
            color: Colors.white,
          ),
          const SizedBox(width: 7),
          Text(
            active ? 'Admin verified' : 'Locked',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _OverviewStrip extends StatelessWidget {
  const _OverviewStrip({required this.overview});

  final AdminOverview overview;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final stats = [
      _AdminStat(
        'Feed',
        '${overview.feedPosts}',
        BoldRounded.megaphone,
        scheme.primary,
      ),
      _AdminStat(
        'Guild',
        '${overview.guildNotices}',
        BoldRounded.badge,
        scheme.secondary,
      ),
      _AdminStat(
        'Live now',
        '${overview.liveNow}',
        BoldRounded.videoCamera,
        const Color(0xFFFF006E),
      ),
      _AdminStat(
        'Users',
        '${overview.users}',
        BoldRounded.user,
        const Color(0xFF22C55E),
      ),
    ];
    return SizedBox(
      height: 116,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: stats.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) =>
            SizedBox(width: 146, child: _AdminStatCard(stat: stats[index])),
      ),
    );
  }
}

class _AdminStat {
  const _AdminStat(this.label, this.value, this.icon, this.tone);

  final String label;
  final String value;
  final String icon;
  final Color tone;
}

class _AdminStatCard extends StatelessWidget {
  const _AdminStatCard({required this.stat});

  final _AdminStat stat;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 19,
              backgroundColor: stat.tone.withValues(alpha: 0.13),
              child: FUI(stat.icon, color: stat.tone, width: 19, height: 19),
            ),
            const Spacer(),
            Text(
              stat.value,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            Text(stat.label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _AdminSectionSelector extends StatelessWidget {
  const _AdminSectionSelector({
    required this.selected,
    required this.onChanged,
  });

  final _AdminSection selected;
  final ValueChanged<_AdminSection> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SegmentedButton<_AdminSection>(
        segments: const [
          ButtonSegment(
            value: _AdminSection.feed,
            icon: FUI(BoldRounded.megaphone, width: 17, height: 17),
            label: Text('Feed'),
          ),
          ButtonSegment(
            value: _AdminSection.guild,
            icon: FUI(BoldRounded.badge, width: 17, height: 17),
            label: Text('Guild'),
          ),
          ButtonSegment(
            value: _AdminSection.live,
            icon: FUI(BoldRounded.videoCamera, width: 17, height: 17),
            label: Text('Live'),
          ),
          ButtonSegment(
            value: _AdminSection.users,
            icon: FUI(BoldRounded.user, width: 17, height: 17),
            label: Text('Users'),
          ),
        ],
        selected: {selected},
        onSelectionChanged: (value) => onChanged(value.first),
      ),
    );
  }
}

class _FeedAdminList extends StatelessWidget {
  const _FeedAdminList({required this.repository});

  final AdminRepository repository;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Announcement>>(
      stream: repository.watchAnnouncements(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return FirestoreErrorState(
            error: snapshot.error!,
            title: 'Feed controls unavailable',
          );
        }
        final items = snapshot.data;
        if (items == null) return const _AdminListLoading();
        if (items.isEmpty) {
          return const EmptyState(
            icon: BoldRounded.megaphone,
            title: 'No feed posts',
            message: 'Published announcements will appear here.',
          );
        }
        return Column(
          children: items
              .map(
                (item) => _AdminActivityCard(
                  icon: BoldRounded.megaphone,
                  title: item.title,
                  subtitle: '${item.category} • ${item.publishedBy}',
                  body: item.content,
                  meta:
                      '${item.likeCount} likes • ${item.commentCount} comments',
                  pinned: item.isPinned,
                  onEdit: () => _editAnnouncement(context, repository, item),
                  onDelete: () => _deleteItem(
                    context,
                    title: item.title,
                    action: () => repository.deleteAnnouncement(item.id),
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _GuildAdminList extends StatelessWidget {
  const _GuildAdminList({required this.repository});

  final AdminRepository repository;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<GuildNotice>>(
      stream: repository.watchGuildNotices(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return FirestoreErrorState(
            error: snapshot.error!,
            title: 'Guild controls unavailable',
          );
        }
        final items = snapshot.data;
        if (items == null) return const _AdminListLoading();
        if (items.isEmpty) {
          return const EmptyState(
            icon: BoldRounded.badge,
            title: 'No guild notices',
            message: 'Guild Hub notices will appear here.',
          );
        }
        return Column(
          children: items
              .map(
                (item) => _AdminActivityCard(
                  icon: item.isHighPriority
                      ? BoldRounded.exclamation
                      : BoldRounded.badge,
                  title: item.title,
                  subtitle: '${item.category} • ${item.authorName}',
                  body: item.body,
                  meta: item.priority == 'high'
                      ? 'High priority'
                      : 'Normal priority',
                  pinned: item.isPinned,
                  onEdit: () => _editGuildNotice(context, repository, item),
                  onDelete: () => _deleteItem(
                    context,
                    title: item.title,
                    action: () => repository.deleteGuildNotice(item.id),
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _LiveAdminList extends StatelessWidget {
  const _LiveAdminList({required this.repository});

  final AdminRepository repository;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<LivePost>>(
      stream: repository.watchLivePosts(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return FirestoreErrorState(
            error: snapshot.error!,
            title: 'Live controls unavailable',
          );
        }
        final items = snapshot.data;
        if (items == null) return const _AdminListLoading();
        if (items.isEmpty) {
          return const EmptyState(
            icon: BoldRounded.videoCamera,
            title: 'No live activity',
            message: 'Short videos and live rooms will appear here.',
          );
        }
        return Column(
          children: items
              .map(
                (item) => _AdminActivityCard(
                  icon: item.status == LivePostStatus.live
                      ? SolidRounded.circle
                      : BoldRounded.videoCamera,
                  title: item.title,
                  subtitle:
                      '${_liveStatusLabel(item.status)} • ${item.hostName}',
                  body: item.description,
                  meta:
                      '${item.viewerCount} viewers • ${item.likeCount} likes • ${item.commentCount} comments',
                  live: item.status == LivePostStatus.live,
                  onEdit: () => _editLivePost(context, repository, item),
                  onDelete: () => _deleteItem(
                    context,
                    title: item.title,
                    action: () => repository.deleteLivePost(item.id),
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _UsersAdminList extends StatelessWidget {
  const _UsersAdminList({required this.repository, required this.session});

  final AdminRepository repository;
  final AppSession session;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<AdminUserAccount>>(
      stream: repository.watchUsers(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return FirestoreErrorState(
            error: snapshot.error!,
            title: 'User controls unavailable',
          );
        }
        final items = snapshot.data;
        if (items == null) return const _AdminListLoading();
        if (items.isEmpty) {
          return const EmptyState(
            icon: BoldRounded.user,
            title: 'No users found',
            message: 'Registered accounts will appear here.',
          );
        }
        return Column(
          children: items
              .map(
                (user) => _AdminUserCard(
                  user: user,
                  isCurrentUser: session.firebaseUser?.uid == user.uid,
                  onEditRole: () => _editUserRole(
                    context,
                    repository,
                    user,
                    protectAdmin: session.firebaseUser?.uid == user.uid,
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _AdminActivityCard extends StatelessWidget {
  const _AdminActivityCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.body,
    required this.meta,
    required this.onEdit,
    required this.onDelete,
    this.pinned = false,
    this.live = false,
  });

  final String icon;
  final String title;
  final String subtitle;
  final String body;
  final String meta;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool pinned;
  final bool live;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tone = live
        ? const Color(0xFFFF006E)
        : pinned
        ? scheme.primary
        : scheme.secondary;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: tone.withValues(alpha: 0.13),
                child: FUI(icon, color: tone, width: 20, height: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                        ),
                        if (pinned)
                          FUI(
                            BoldRounded.bookmark,
                            color: scheme.primary,
                            width: 16,
                            height: 16,
                          ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    if (body.trim().isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        body,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            meta,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.labelMedium
                                ?.copyWith(color: scheme.onSurfaceVariant),
                          ),
                        ),
                        IconButton.filledTonal(
                          tooltip: 'Edit',
                          onPressed: onEdit,
                          icon: const FUI(
                            BoldRounded.pencil,
                            width: 17,
                            height: 17,
                          ),
                        ),
                        const SizedBox(width: 6),
                        IconButton.filledTonal(
                          tooltip: 'Delete',
                          onPressed: onDelete,
                          icon: const FUI(
                            BoldRounded.cross,
                            width: 17,
                            height: 17,
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
      ),
    ).animate().fadeIn(duration: 220.ms).slideY(begin: 0.02, end: 0);
  }
}

class _AdminUserCard extends StatelessWidget {
  const _AdminUserCard({
    required this.user,
    required this.isCurrentUser,
    required this.onEditRole,
  });

  final AdminUserAccount user;
  final bool isCurrentUser;
  final VoidCallback onEditRole;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tone = user.role == AppUserRole.admin
        ? scheme.primary
        : user.role == AppUserRole.guildOfficial
        ? scheme.secondary
        : scheme.tertiary;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        child: ListTile(
          contentPadding: const EdgeInsets.all(14),
          leading: CircleAvatar(
            backgroundColor: tone.withValues(alpha: 0.13),
            child: Text(
              _initials(user.displayName),
              style: TextStyle(color: tone, fontWeight: FontWeight.w900),
            ),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  user.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
              if (isCurrentUser) _MiniPill(label: 'You', tone: scheme.primary),
            ],
          ),
          subtitle: Text(
            [
              _roleLabel(user.role),
              if (user.email.trim().isNotEmpty) user.email,
              if (user.faculty.trim().isNotEmpty) user.faculty,
            ].join(' • '),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: IconButton.filledTonal(
            tooltip: 'Manage role',
            onPressed: onEditRole,
            icon: const FUI(BoldRounded.key, width: 18, height: 18),
          ),
        ),
      ),
    );
  }
}

class _MiniPill extends StatelessWidget {
  const _MiniPill({required this.label, required this.tone});

  final String label;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: tone.withValues(alpha: 0.12),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: tone,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _AdminListLoading extends StatelessWidget {
  const _AdminListLoading();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        LoadingShimmer(height: 132),
        SizedBox(height: 12),
        LoadingShimmer(height: 132),
        SizedBox(height: 12),
        LoadingShimmer(height: 132),
      ],
    );
  }
}

Future<void> _editAnnouncement(
  BuildContext context,
  AdminRepository repository,
  Announcement item,
) async {
  final result = await _showActivityEditor(
    context,
    title: 'Edit feed post',
    initialTitle: item.title,
    initialBody: item.content,
    initialCategory: item.category,
    initialPinned: item.isPinned,
    categories: const ['General', 'Academic', 'Events', 'Guild', 'Urgent'],
  );
  if (result == null) return;
  if (!context.mounted) return;
  await _runAdminAction(
    context,
    success: 'Feed post updated.',
    action: () => repository.updateAnnouncement(
      id: item.id,
      title: result.title,
      content: result.body,
      category: result.category,
      isPinned: result.pinned,
    ),
  );
}

Future<void> _editGuildNotice(
  BuildContext context,
  AdminRepository repository,
  GuildNotice item,
) async {
  final result = await _showActivityEditor(
    context,
    title: 'Edit guild notice',
    initialTitle: item.title,
    initialBody: item.body,
    initialCategory: item.category,
    initialPinned: item.isPinned,
    initialPriority: item.priority,
    categories: const ['Guild', 'Academic', 'Events', 'Welfare', 'Urgent'],
    includePriority: true,
  );
  if (result == null) return;
  if (!context.mounted) return;
  await _runAdminAction(
    context,
    success: 'Guild notice updated.',
    action: () => repository.updateGuildNotice(
      id: item.id,
      title: result.title,
      body: result.body,
      category: result.category,
      priority: result.priority,
      isPinned: result.pinned,
    ),
  );
}

Future<void> _editLivePost(
  BuildContext context,
  AdminRepository repository,
  LivePost item,
) async {
  final result = await _showLiveEditor(context, item);
  if (result == null) return;
  if (!context.mounted) return;
  await _runAdminAction(
    context,
    success: 'Live activity updated.',
    action: () => repository.updateLivePost(
      id: item.id,
      title: result.title,
      description: result.body,
      status: result.status,
    ),
  );
}

Future<void> _editUserRole(
  BuildContext context,
  AdminRepository repository,
  AdminUserAccount user, {
  required bool protectAdmin,
}) async {
  final role = await showModalBottomSheet<AppUserRole>(
    context: context,
    showDragHandle: true,
    builder: (context) {
      var selected = user.role;
      return StatefulBuilder(
        builder: (context, setSheetState) {
          return SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Manage role',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(user.displayName),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<AppUserRole>(
                    initialValue: selected,
                    decoration: const InputDecoration(
                      prefixIcon: FUI(BoldRounded.badge),
                      labelText: 'Account role',
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: AppUserRole.student,
                        child: Text('Student'),
                      ),
                      DropdownMenuItem(
                        value: AppUserRole.lecturer,
                        child: Text('Lecturer'),
                      ),
                      DropdownMenuItem(
                        value: AppUserRole.guildOfficial,
                        child: Text('Guild official'),
                      ),
                      DropdownMenuItem(
                        value: AppUserRole.admin,
                        child: Text('Administrator'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setSheetState(() => selected = value);
                    },
                  ),
                  if (protectAdmin && selected != AppUserRole.admin) ...[
                    const SizedBox(height: 12),
                    Text(
                      'You cannot remove your own administrator access from this screen.',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),
                  FilledButton.icon(
                    onPressed: protectAdmin && selected != AppUserRole.admin
                        ? null
                        : () => Navigator.pop(context, selected),
                    icon: const FUI(BoldRounded.check, width: 18, height: 18),
                    label: const Text('Save role'),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
  if (role == null || role == user.role) return;
  if (!context.mounted) return;
  await _runAdminAction(
    context,
    success: 'User role updated.',
    action: () => repository.updateUserRole(uid: user.uid, role: role),
  );
}

Future<_ActivityEditResult?> _showActivityEditor(
  BuildContext context, {
  required String title,
  required String initialTitle,
  required String initialBody,
  required String initialCategory,
  required bool initialPinned,
  required List<String> categories,
  String initialPriority = 'normal',
  bool includePriority = false,
}) async {
  final titleController = TextEditingController(text: initialTitle);
  final bodyController = TextEditingController(text: initialBody);
  var category = categories.contains(initialCategory)
      ? initialCategory
      : categories.first;
  var priority = initialPriority == 'high' ? 'high' : 'normal';
  var pinned = initialPinned;

  final result = await showModalBottomSheet<_ActivityEditResult>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setSheetState) {
          return SafeArea(
            top: false,
            child: ListView(
              shrinkWrap: true,
              padding: EdgeInsets.fromLTRB(
                20,
                8,
                20,
                MediaQuery.viewInsetsOf(context).bottom + 20,
              ),
              children: [
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: titleController,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    prefixIcon: FUI(BoldRounded.bookmark),
                    labelText: 'Title',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: bodyController,
                  minLines: 4,
                  maxLines: 8,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    prefixIcon: FUI(BoldRounded.comments),
                    labelText: 'Message',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: category,
                  decoration: const InputDecoration(
                    prefixIcon: FUI(BoldRounded.grid),
                    labelText: 'Category',
                  ),
                  items: categories
                      .map(
                        (item) =>
                            DropdownMenuItem(value: item, child: Text(item)),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setSheetState(() => category = value);
                  },
                ),
                if (includePriority) ...[
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: priority,
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
                      setSheetState(() => priority = value);
                    },
                  ),
                ],
                const SizedBox(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: pinned,
                  onChanged: (value) => setSheetState(() => pinned = value),
                  title: const Text('Pin this activity'),
                  subtitle: const Text('Keep it highlighted for students.'),
                ),
                const SizedBox(height: 14),
                FilledButton.icon(
                  onPressed: () {
                    final cleanTitle = titleController.text.trim();
                    if (cleanTitle.isEmpty) return;
                    Navigator.pop(
                      context,
                      _ActivityEditResult(
                        title: cleanTitle,
                        body: bodyController.text.trim(),
                        category: category,
                        priority: priority,
                        pinned: pinned,
                      ),
                    );
                  },
                  icon: const FUI(BoldRounded.check, width: 18, height: 18),
                  label: const Text('Save changes'),
                ),
              ],
            ),
          );
        },
      );
    },
  );

  titleController.dispose();
  bodyController.dispose();
  return result;
}

Future<_LiveEditResult?> _showLiveEditor(
  BuildContext context,
  LivePost item,
) async {
  final titleController = TextEditingController(text: item.title);
  final bodyController = TextEditingController(text: item.description);
  var status = _liveStatusKey(item.status);

  final result = await showModalBottomSheet<_LiveEditResult>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setSheetState) {
          return SafeArea(
            top: false,
            child: ListView(
              shrinkWrap: true,
              padding: EdgeInsets.fromLTRB(
                20,
                8,
                20,
                MediaQuery.viewInsetsOf(context).bottom + 20,
              ),
              children: [
                Text(
                  'Manage live activity',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: titleController,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    prefixIcon: FUI(BoldRounded.videoCamera),
                    labelText: 'Title',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: bodyController,
                  minLines: 3,
                  maxLines: 6,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    prefixIcon: FUI(BoldRounded.comments),
                    labelText: 'Description',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: status,
                  decoration: const InputDecoration(
                    prefixIcon: FUI(BoldRounded.clock),
                    labelText: 'Status',
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'scheduled',
                      child: Text('Scheduled'),
                    ),
                    DropdownMenuItem(value: 'live', child: Text('Live')),
                    DropdownMenuItem(
                      value: 'published',
                      child: Text('Published'),
                    ),
                    DropdownMenuItem(
                      value: 'processing',
                      child: Text('Processing'),
                    ),
                    DropdownMenuItem(value: 'ended', child: Text('Ended')),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setSheetState(() => status = value);
                  },
                ),
                const SizedBox(height: 14),
                FilledButton.icon(
                  onPressed: () {
                    final cleanTitle = titleController.text.trim();
                    if (cleanTitle.isEmpty) return;
                    Navigator.pop(
                      context,
                      _LiveEditResult(
                        title: cleanTitle,
                        body: bodyController.text.trim(),
                        status: status,
                      ),
                    );
                  },
                  icon: const FUI(BoldRounded.check, width: 18, height: 18),
                  label: const Text('Save live activity'),
                ),
              ],
            ),
          );
        },
      );
    },
  );

  titleController.dispose();
  bodyController.dispose();
  return result;
}

Future<void> _deleteItem(
  BuildContext context, {
  required String title,
  required Future<void> Function() action,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Delete activity?'),
      content: Text('This will remove "$title" from VU Hub.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
  if (confirmed != true) return;
  if (!context.mounted) return;
  await _runAdminAction(context, success: 'Activity deleted.', action: action);
}

Future<void> _runAdminAction(
  BuildContext context, {
  required String success,
  required Future<void> Function() action,
}) async {
  try {
    await action();
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(success)));
  } catch (error) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          describeFirestoreError(
            error,
            fallback: 'This admin action could not be completed.',
          ),
        ),
      ),
    );
  }
}

class _ActivityEditResult {
  const _ActivityEditResult({
    required this.title,
    required this.body,
    required this.category,
    required this.priority,
    required this.pinned,
  });

  final String title;
  final String body;
  final String category;
  final String priority;
  final bool pinned;
}

class _LiveEditResult {
  const _LiveEditResult({
    required this.title,
    required this.body,
    required this.status,
  });

  final String title;
  final String body;
  final String status;
}

String _liveStatusKey(LivePostStatus status) {
  switch (status) {
    case LivePostStatus.scheduled:
      return 'scheduled';
    case LivePostStatus.live:
      return 'live';
    case LivePostStatus.ended:
      return 'ended';
    case LivePostStatus.processing:
      return 'processing';
    case LivePostStatus.published:
      return 'published';
  }
}

String _liveStatusLabel(LivePostStatus status) {
  switch (status) {
    case LivePostStatus.scheduled:
      return 'Scheduled';
    case LivePostStatus.live:
      return 'Live now';
    case LivePostStatus.ended:
      return 'Ended';
    case LivePostStatus.processing:
      return 'Processing';
    case LivePostStatus.published:
      return 'Published';
  }
}

String _roleLabel(AppUserRole role) {
  switch (role) {
    case AppUserRole.admin:
      return 'Administrator';
    case AppUserRole.lecturer:
      return 'Lecturer';
    case AppUserRole.guildOfficial:
      return 'Guild official';
    case AppUserRole.unknown:
      return 'Unknown';
    case AppUserRole.student:
      return 'Student';
  }
}

String _initials(String value) {
  final parts = value
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .take(2)
      .toList();
  if (parts.isEmpty) return 'VU';
  return parts.map((part) => part.characters.first.toUpperCase()).join();
}
