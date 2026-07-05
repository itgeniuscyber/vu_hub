import 'package:cloud_firestore/cloud_firestore.dart';

import 'announcement.dart';

class AnnouncementRepository {
  AnnouncementRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Stream<List<Announcement>> watchLatest() {
    return _firestore.collection('announcements').limit(60).snapshots().map((
      snapshot,
    ) {
      final items = snapshot.docs.map(Announcement.fromDoc).toList();
      items.sort((a, b) {
        final left = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final right = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return right.compareTo(left);
      });
      return items;
    });
  }

  Future<void> publishAnnouncement({
    required String title,
    required String content,
    required String category,
    required String publishedBy,
    required String authorId,
    bool isPinned = false,
  }) async {
    await _firestore.collection('announcements').add({
      'title': title.trim(),
      'content': content.trim(),
      'body': content.trim(),
      'category': category,
      'publishedBy': publishedBy.trim().isEmpty
          ? 'VU Admin'
          : publishedBy.trim(),
      'authorId': authorId,
      'isPinned': isPinned,
      'pinned': isPinned,
      'timestamp': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
      'publishedAt': FieldValue.serverTimestamp(),
    });
  }
}
