import 'package:cloud_firestore/cloud_firestore.dart';

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
      title: _string(data['title']) ?? 'Untitled announcement',
      content: _string(data['content']) ?? _string(data['body']) ?? '',
      category: _string(data['category']) ?? 'General',
      publishedBy:
          _string(data['publishedBy']) ?? _string(data['author']) ?? 'VU',
      createdAt: _date(
        data['timestamp'] ?? data['createdAt'] ?? data['publishedAt'],
      ),
      isPinned: data['isPinned'] == true || data['pinned'] == true,
    );
  }

  static String? _string(Object? value) => value is String ? value : null;

  static DateTime? _date(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}
