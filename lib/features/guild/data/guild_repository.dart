import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/utils/firestore_parsing.dart';

class GuildRepository {
  GuildRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Stream<List<GuildNotice>> watchNotices() {
    return _firestore.collection('guild_posts').limit(40).snapshots().map((
      snapshot,
    ) {
      final items = snapshot.docs.map(GuildNotice.fromDoc).toList();
      items.sort((a, b) {
        final left = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final right = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return right.compareTo(left);
      });
      return items;
    });
  }

  Future<void> publishNotice({
    required String title,
    required String body,
    required String category,
    required String authorId,
    required String authorName,
    String priority = 'normal',
    bool isPinned = false,
  }) async {
    await _firestore.collection('guild_posts').add({
      'title': title.trim(),
      'body': body.trim(),
      'content': body.trim(),
      'category': category.trim().isEmpty ? 'Guild' : category.trim(),
      'priority': priority,
      'isPinned': isPinned,
      'pinned': isPinned,
      'authorId': authorId,
      'authorName': authorName.trim().isEmpty ? 'VU Guild' : authorName.trim(),
      'publishedBy': authorName.trim().isEmpty ? 'VU Guild' : authorName.trim(),
      'createdAt': FieldValue.serverTimestamp(),
      'timestamp': FieldValue.serverTimestamp(),
    });
  }
}

class GuildNotice {
  const GuildNotice({
    required this.id,
    required this.title,
    required this.body,
    required this.category,
    required this.authorName,
    required this.priority,
    required this.isPinned,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String body;
  final String category;
  final String authorName;
  final String priority;
  final bool isPinned;
  final DateTime? createdAt;

  bool get isHighPriority =>
      priority.toLowerCase() == 'high' ||
      category.toLowerCase().contains('urgent');

  factory GuildNotice.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return GuildNotice(
      id: doc.id,
      title: firstString(data, ['title', 'headline'], fallback: 'Guild notice'),
      body: firstString(data, [
        'body',
        'content',
        'description',
        'message',
      ], fallback: ''),
      category: firstString(data, ['category', 'type'], fallback: 'Guild'),
      authorName: firstString(data, [
        'authorName',
        'publishedBy',
        'displayName',
        'postedBy',
      ], fallback: 'VU Guild'),
      priority: firstString(data, ['priority'], fallback: 'normal'),
      isPinned: firstBool(data, ['isPinned', 'pinned']),
      createdAt: firstDate(data, ['createdAt', 'timestamp', 'publishedAt']),
    );
  }
}
