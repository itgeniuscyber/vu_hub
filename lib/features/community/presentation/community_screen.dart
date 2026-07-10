import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/feature_hero_banner.dart';
import '../../../core/widgets/firestore_error_state.dart';
import '../../../core/widgets/loading_shimmer.dart';
import '../../../core/widgets/section_header.dart';
import '../data/community_models.dart';
import '../data/community_repository.dart';

class CommunityScreen extends StatelessWidget {
  const CommunityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FeatureHeroBanner(
                          title: 'Community',
                          subtitle:
                              'Join student conversations, follow public posts, and surface helpful campus discussion threads from the live Firebase collections.',
                          icon: Icons.forum_outlined,
                          scheme: scheme,
                          badge: 'Campus voices',
                          height: 188,
                        )
                        .animate()
                        .fadeIn(duration: 300.ms)
                        .slideY(begin: 0.05, end: 0),
                    const SizedBox(height: 18),
                    SizedBox(
                      height: 104,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: const [
                          _CommunityMetricCard(
                            icon: Icons.chat_bubble_outline,
                            label: 'Public chat',
                            value: 'Live',
                            width: 156,
                          ),
                          SizedBox(width: 12),
                          _CommunityMetricCard(
                            icon: Icons.question_answer_outlined,
                            label: 'Discussion threads',
                            value: 'Active',
                            width: 184,
                          ),
                          SizedBox(width: 12),
                          _CommunityMetricCard(
                            icon: Icons.dynamic_feed_outlined,
                            label: 'Campus posts',
                            value: 'Fresh',
                            width: 164,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: scheme.surfaceContainerHighest,
                        border: Border.all(
                          color: scheme.outlineVariant.withValues(alpha: 0.5),
                        ),
                      ),
                      child: TabBar(
                        dividerColor: Colors.transparent,
                        indicator: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: scheme.primary,
                        ),
                        labelColor: Colors.white,
                        unselectedLabelColor: scheme.onSurfaceVariant,
                        tabs: const [
                          Tab(text: 'Chat'),
                          Tab(text: 'Discussions'),
                          Tab(text: 'Posts'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Expanded(
                child: TabBarView(
                  children: [_PublicChatTab(), _DiscussionTab(), _PostsTab()],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PublicChatTab extends StatelessWidget {
  const _PublicChatTab();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<CommunityMessage>>(
      stream: CommunityRepository().watchPublicChat(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return ListView(
            padding: const EdgeInsets.all(20),
            children: const [
              LoadingShimmer(height: 96),
              SizedBox(height: 12),
              LoadingShimmer(height: 96),
              SizedBox(height: 12),
              LoadingShimmer(height: 96),
            ],
          );
        }
        if (snapshot.hasError) {
          return FirestoreErrorState(
            error: snapshot.error!,
            icon: Icons.forum_outlined,
            title: 'Public chat unavailable',
            fallbackMessage:
                'Messages from the public chat could not be loaded.',
          );
        }
        final items = snapshot.data ?? [];
        if (items.isEmpty) {
          return const EmptyState(
            icon: Icons.chat_bubble_outline,
            title: 'No public chat yet',
            message:
                'Messages from `public_chat` will appear here when available.',
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          itemCount: items.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, index) => _ChatCard(
            message: items[index],
          ).animate().fadeIn(duration: 220.ms).slideX(begin: 0.03, end: 0),
        );
      },
    );
  }
}

class _DiscussionTab extends StatelessWidget {
  const _DiscussionTab();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<DiscussionThread>>(
      stream: CommunityRepository().watchDiscussions(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return ListView(
            padding: const EdgeInsets.all(20),
            children: const [
              LoadingShimmer(height: 120),
              SizedBox(height: 12),
              LoadingShimmer(height: 120),
            ],
          );
        }
        if (snapshot.hasError) {
          return FirestoreErrorState(
            error: snapshot.error!,
            icon: Icons.question_answer_outlined,
            title: 'Discussions unavailable',
            fallbackMessage: 'Discussion threads are unavailable right now.',
          );
        }
        final items = snapshot.data ?? [];
        if (items.isEmpty) {
          return const EmptyState(
            icon: Icons.question_answer_outlined,
            title: 'No discussions yet',
            message:
                'Discussion threads from the existing collection will appear here.',
          );
        }
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          children: [
            const SectionHeader(title: 'Academic and community threads'),
            const SizedBox(height: 12),
            ...items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _DiscussionCard(thread: item)
                    .animate()
                    .fadeIn(duration: 240.ms)
                    .slideX(begin: 0.03, end: 0),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _PostsTab extends StatelessWidget {
  const _PostsTab();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<CommunityPost>>(
      stream: CommunityRepository().watchPosts(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return ListView(
            padding: const EdgeInsets.all(20),
            children: const [
              LoadingShimmer(height: 220),
              SizedBox(height: 12),
              LoadingShimmer(height: 220),
            ],
          );
        }
        if (snapshot.hasError) {
          return FirestoreErrorState(
            error: snapshot.error!,
            icon: Icons.dynamic_feed_outlined,
            title: 'Posts unavailable',
            fallbackMessage: 'Community posts could not be loaded.',
          );
        }
        final items = snapshot.data ?? [];
        if (items.isEmpty) {
          return const EmptyState(
            icon: Icons.dynamic_feed_outlined,
            title: 'No community posts yet',
            message:
                'Campus posts from `posts` will appear here once they are available.',
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          itemCount: items.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, index) => _PostCard(
            post: items[index],
          ).animate().fadeIn(duration: 240.ms).slideY(begin: 0.04, end: 0),
        );
      },
    );
  }
}

class _CommunityMetricCard extends StatelessWidget {
  const _CommunityMetricCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.width,
  });

  final IconData icon;
  final String label;
  final String value;
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
              Text(value, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 2),
              Text(label, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChatCard extends StatelessWidget {
  const _ChatCard({required this.message});

  final CommunityMessage message;

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
                  backgroundColor: scheme.primary.withValues(alpha: 0.14),
                  child: Text(
                    message.senderName.characters.first.toUpperCase(),
                    style: TextStyle(
                      color: scheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message.senderName,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        message.createdAt == null
                            ? 'Recently'
                            : DateFormat(
                                'MMM d • HH:mm',
                              ).format(message.createdAt!),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                if (message.isPinned)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      color: scheme.secondary.withValues(alpha: 0.12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.push_pin, size: 14, color: scheme.secondary),
                        const SizedBox(width: 6),
                        Text(
                          'Pinned',
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(color: scheme.secondary),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: scheme.surfaceContainerHighest,
              ),
              child: Text(
                message.text,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DiscussionCard extends StatelessWidget {
  const _DiscussionCard({required this.thread});

  final DiscussionThread thread;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _CommunityTag(
                  label: thread.category,
                  tone: scheme.primary,
                  icon: Icons.sell_outlined,
                ),
                _CommunityTag(
                  label: '${thread.commentCount} replies',
                  tone: scheme.secondary,
                  icon: Icons.mode_comment_outlined,
                ),
                if (thread.isResolved)
                  _CommunityTag(
                    label: 'Resolved',
                    tone: scheme.tertiary,
                    icon: Icons.verified_outlined,
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(thread.title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(thread.body, maxLines: 3, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 10),
            Text(
              '${thread.authorName} • ${thread.createdAt == null ? 'Recently' : DateFormat('MMM d').format(thread.createdAt!)}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  const _PostCard({required this.post});

  final CommunityPost post;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (post.imageUrl != null && post.imageUrl!.isNotEmpty)
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                  child: CachedNetworkImage(
                    imageUrl: post.imageUrl!,
                    height: 188,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorWidget: (_, _, _) => Container(
                      height: 188,
                      color: scheme.surfaceContainerHighest,
                      child: Icon(
                        Icons.image_not_supported_outlined,
                        color: scheme.outline,
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withValues(alpha: 0.06),
                          Colors.black.withValues(alpha: 0.34),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 14,
                  top: 14,
                  child: _CommunityTag(
                    label: post.category,
                    tone: Colors.white,
                    icon: Icons.local_offer_outlined,
                    lightForeground: false,
                  ),
                ),
              ],
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: scheme.primary.withValues(alpha: 0.12),
                      child: Text(
                        post.authorName.characters.first.toUpperCase(),
                        style: TextStyle(
                          color: scheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        post.authorName,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    Text(
                      post.createdAt == null
                          ? 'Recently'
                          : DateFormat('MMM d').format(post.createdAt!),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(post.caption),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  children: [
                    _PostMeta(
                      icon: Icons.favorite_border,
                      label: '${post.likeCount}',
                      tone: scheme.primary,
                    ),
                    _PostMeta(
                      icon: Icons.mode_comment_outlined,
                      label: '${post.commentCount}',
                      tone: scheme.primary,
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

class _CommunityTag extends StatelessWidget {
  const _CommunityTag({
    required this.label,
    required this.tone,
    required this.icon,
    this.lightForeground = true,
  });

  final String label;
  final Color tone;
  final IconData icon;
  final bool lightForeground;

  @override
  Widget build(BuildContext context) {
    final foreground = lightForeground ? tone : Colors.white;
    final background = lightForeground
        ? tone.withValues(alpha: 0.12)
        : Colors.white.withValues(alpha: 0.18);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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

class _PostMeta extends StatelessWidget {
  const _PostMeta({
    required this.icon,
    required this.label,
    required this.tone,
  });

  final IconData icon;
  final String label;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: tone),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.labelLarge),
      ],
    );
  }
}
