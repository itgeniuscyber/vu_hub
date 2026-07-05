import 'package:cloud_firestore/cloud_firestore.dart';

import 'community_models.dart';

class CommunityRepository {
  CommunityRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Stream<List<CommunityMessage>> watchPublicChat() {
    return _firestore.collection('public_chat').limit(80).snapshots().map((
      snapshot,
    ) {
      final items = snapshot.docs.map(CommunityMessage.fromDoc).toList();
      items.sort(
        (a, b) => (b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0))
            .compareTo(a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0)),
      );
      return items;
    });
  }

  Stream<List<DiscussionThread>> watchDiscussions() {
    return _firestore.collection('discussions').limit(40).snapshots().map((
      snapshot,
    ) {
      final items = snapshot.docs.map(DiscussionThread.fromDoc).toList();
      items.sort(
        (a, b) => (b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0))
            .compareTo(a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0)),
      );
      return items;
    });
  }

  Stream<List<CommunityPost>> watchPosts() {
    return _firestore.collection('posts').limit(40).snapshots().map((snapshot) {
      final items = snapshot.docs.map(CommunityPost.fromDoc).toList();
      items.sort(
        (a, b) => (b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0))
            .compareTo(a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0)),
      );
      return items;
    });
  }
}
