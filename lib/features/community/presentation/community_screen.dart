import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/firestore_error_state.dart';
import '../../../core/widgets/loading_shimmer.dart';
import '../../../core/widgets/section_header.dart';
import '../data/community_models.dart';
import '../data/community_repository.dart';

class CommunityScreen extends StatelessWidget {
  const CommunityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Community'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Chat'),
              Tab(text: 'Discussions'),
              Tab(text: 'Posts'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [_PublicChatTab(), _DiscussionTab(), _PostsTab()],
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
          padding: const EdgeInsets.all(20),
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
          padding: const EdgeInsets.all(20),
          children: [
            const SectionHeader(title: 'Academic and community threads'),
            const SizedBox(height: 12),
            ...items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _DiscussionCard(thread: item),
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
          padding: const EdgeInsets.all(20),
          itemCount: items.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, index) => _PostCard(post: items[index]),
        );
      },
    );
  }
}

class _ChatCard extends StatelessWidget {
  const _ChatCard({required this.message});

  final CommunityMessage message;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(child: Text(message.senderName.characters.first)),
        title: Text(message.senderName),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(message.text),
            const SizedBox(height: 6),
            Text(
              message.createdAt == null
                  ? 'Recently'
                  : DateFormat('MMM d • HH:mm').format(message.createdAt!),
            ),
          ],
        ),
        trailing: message.isPinned ? const Icon(Icons.push_pin) : null,
      ),
    );
  }
}

class _DiscussionCard extends StatelessWidget {
  const _DiscussionCard({required this.thread});

  final DiscussionThread thread;

  @override
  Widget build(BuildContext context) {
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
                Chip(label: Text(thread.category)),
                Chip(label: Text('${thread.commentCount} replies')),
                if (thread.isResolved) const Chip(label: Text('Resolved')),
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
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              child: CachedNetworkImage(
                imageUrl: post.imageUrl!,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
                errorWidget: (_, _, _) => Container(
                  height: 180,
                  color: scheme.surfaceContainerHighest,
                  child: Icon(
                    Icons.image_not_supported_outlined,
                    color: scheme.outline,
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Chip(label: Text(post.category)),
                    const Spacer(),
                    Text(
                      post.createdAt == null
                          ? 'Recently'
                          : DateFormat('MMM d').format(post.createdAt!),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  post.authorName,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 6),
                Text(post.caption),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.favorite_border,
                      size: 18,
                      color: scheme.primary,
                    ),
                    const SizedBox(width: 6),
                    Text('${post.likeCount}'),
                    const SizedBox(width: 16),
                    Icon(
                      Icons.mode_comment_outlined,
                      size: 18,
                      color: scheme.primary,
                    ),
                    const SizedBox(width: 6),
                    Text('${post.commentCount}'),
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
