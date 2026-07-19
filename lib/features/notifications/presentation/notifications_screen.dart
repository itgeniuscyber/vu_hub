import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:vu_hub/core/widgets/app_fui_icon.dart';

import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/firestore_error_state.dart';
import '../../../core/widgets/loading_shimmer.dart';
import '../data/app_notification.dart';
import '../data/notification_repository.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: scheme.primary.withValues(alpha: 0.12),
              child: FUI(
                BoldRounded.bellRing,
                width: 18,
                height: 18,
                color: scheme.primary,
              ),
            ),
          ),
        ],
      ),
      body: StreamBuilder<List<CampusNotification>>(
        stream: NotificationRepository().watchLatest(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Padding(
              padding: EdgeInsets.all(20),
              child: LoadingShimmer(height: 180),
            );
          }
          if (snapshot.hasError) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: FirestoreErrorState(
                error: snapshot.error!,
                title: 'Could not load notifications',
                fallbackMessage:
                    'Campus alerts are unavailable right now. Please try again.',
              ),
            );
          }
          final items = snapshot.data ?? [];
          if (items.isEmpty) {
            return const EmptyState(
              icon: BoldRounded.bell,
              title: 'No notifications yet',
              message:
                  'Feed posts, live streams, events, and urgent campus alerts will appear here.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              return _NotificationCard(item: items[index])
                  .animate()
                  .fadeIn(duration: 260.ms, delay: (30 * index).ms)
                  .slideY(begin: 0.04, end: 0);
            },
          );
        },
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.item});

  final CampusNotification item;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tone = _toneFor(item.type, scheme, item.isUrgent);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  colors: [
                    tone.withValues(alpha: 0.24),
                    tone.withValues(alpha: 0.08),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: FUI(
                _iconFor(item.type, item.isUrgent),
                width: 21,
                height: 21,
                color: tone,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          item.category,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(
                            context,
                          ).textTheme.labelLarge?.copyWith(color: tone),
                        ),
                      ),
                      if (item.isUrgent) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Text(
                            'Urgent',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Colors.redAccent,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  if (item.body.trim().isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      item.body,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurface.withValues(
                          alpha: isDark ? 0.76 : 0.68,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      FUI(
                        RegularRounded.clock,
                        width: 14,
                        height: 14,
                        color: scheme.onSurface.withValues(alpha: 0.55),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _timeLabel(item.createdAt),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurface.withValues(alpha: 0.56),
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

Color _toneFor(CampusNotificationType type, ColorScheme scheme, bool urgent) {
  if (urgent) return Colors.redAccent;
  switch (type) {
    case CampusNotificationType.announcement:
      return scheme.primary;
    case CampusNotificationType.live:
      return const Color(0xFFFF006E);
    case CampusNotificationType.event:
      return const Color(0xFFFFB703);
    case CampusNotificationType.chat:
      return const Color(0xFF22C55E);
    case CampusNotificationType.system:
      return scheme.secondary;
  }
}

String _iconFor(CampusNotificationType type, bool urgent) {
  if (urgent) return BoldRounded.exclamation;
  switch (type) {
    case CampusNotificationType.announcement:
      return BoldRounded.megaphone;
    case CampusNotificationType.live:
      return BoldRounded.videoCamera;
    case CampusNotificationType.event:
      return BoldRounded.calendar;
    case CampusNotificationType.chat:
      return BoldRounded.comments;
    case CampusNotificationType.system:
      return BoldRounded.bellRing;
  }
}

String _timeLabel(DateTime? value) {
  if (value == null) return 'Just now';
  final diff = DateTime.now().difference(value);
  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  return DateFormat('MMM d').format(value);
}
