import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/utils/firestore_parsing.dart';

class Announcement {
  const Announcement({
    required this.id,
    required this.title,
    required this.content,
    required this.category,
    required this.publishedBy,
    required this.createdAt,
    required this.isPinned,
  });

  final String id;
  final String title;
  final String content;
  final String category;
  final String publishedBy;
  final DateTime? createdAt;
  final bool isPinned;

  factory Announcement.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return Announcement(
      id: doc.id,
      title: firstString(data, [
        'title',
        'headline',
        'subject',
      ], fallback: 'Untitled announcement'),
      content: firstString(data, [
        'content',
        'body',
        'description',
      ], fallback: ''),
      category: firstString(data, ['category', 'type'], fallback: 'General'),
      publishedBy: firstString(data, [
        'publishedBy',
        'author',
        'authorName',
        'createdByName',
      ], fallback: 'VU'),
      createdAt: firstDate(data, ['timestamp', 'createdAt', 'publishedAt']),
      isPinned: firstBool(data, ['isPinned', 'pinned']),
    );
  }
}
