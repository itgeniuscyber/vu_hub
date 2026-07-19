import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/utils/firestore_parsing.dart';

enum CampusNotificationType { announcement, live, event, chat, system }

class CampusNotification {
  const CampusNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.category,
    required this.sourceCollection,
    required this.sourceId,
    required this.imageUrl,
    required this.priority,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String body;
  final CampusNotificationType type;
  final String category;
  final String sourceCollection;
  final String sourceId;
  final String imageUrl;
  final String priority;
  final DateTime? createdAt;

  bool get isUrgent =>
      priority.toLowerCase() == 'high' ||
      category.toLowerCase().contains('urgent');

  factory CampusNotification.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    return CampusNotification(
      id: doc.id,
      title: firstString(data, [
        'title',
        'headline',
      ], fallback: 'Campus update'),
      body: firstString(data, ['body', 'message', 'content', 'description']),
      type: _typeFromKey(firstString(data, ['type'], fallback: 'system')),
      category: firstString(data, ['category', 'tag'], fallback: 'Campus'),
      sourceCollection: firstString(data, ['sourceCollection']),
      sourceId: firstString(data, ['sourceId']),
      imageUrl: firstString(data, ['imageUrl', 'coverUrl']),
      priority: firstString(data, ['priority'], fallback: 'normal'),
      createdAt: firstDate(data, ['createdAt', 'timestamp']),
    );
  }
}

CampusNotificationType _typeFromKey(String key) {
  switch (key.trim().toLowerCase()) {
    case 'announcement':
    case 'feed':
      return CampusNotificationType.announcement;
    case 'live':
    case 'live_post':
    case 'short_video':
      return CampusNotificationType.live;
    case 'event':
      return CampusNotificationType.event;
    case 'chat':
    case 'public_chat':
    case 'private_chat':
      return CampusNotificationType.chat;
    default:
      return CampusNotificationType.system;
  }
}
