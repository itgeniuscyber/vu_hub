import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'campus_event.dart';

class EventsRepository {
  EventsRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth;

  final FirebaseFirestore _firestore;
  final FirebaseAuth? _auth;

  Stream<List<CampusEvent>> watchEvents() {
    return _firestore.collection('events').limit(40).snapshots().map((
      snapshot,
    ) {
      final items = snapshot.docs.map(CampusEvent.fromDoc).toList();
      items.sort(
        (a, b) => (a.startTime ?? DateTime.fromMillisecondsSinceEpoch(0))
            .compareTo(b.startTime ?? DateTime.fromMillisecondsSinceEpoch(0)),
      );
      return items;
    });
  }

  Future<void> createLiveEvent({
    required String title,
    required String description,
    required String streamUrl,
    required String location,
    required String category,
    required String hostName,
    String imageUrl = '',
  }) async {
    final user = (_auth ?? FirebaseAuth.instance).currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'not-signed-in',
        message: 'Please sign in before starting a live stream.',
      );
    }

    final now = DateTime.now();
    await _firestore.collection('events').add({
      'title': title.trim(),
      'description': description.trim(),
      'streamUrl': streamUrl.trim(),
      'location': location.trim().isEmpty
          ? 'Victoria University'
          : location.trim(),
      'category': category.trim().isEmpty ? 'Live' : category.trim(),
      'hostName': hostName.trim().isEmpty
          ? user.displayName ?? 'VU Host'
          : hostName.trim(),
      'hostId': user.uid,
      'imageUrl': imageUrl.trim(),
      'startTime': Timestamp.fromDate(now.subtract(const Duration(minutes: 1))),
      'endTime': Timestamp.fromDate(now.add(const Duration(hours: 2))),
      'isFeatured': true,
      'viewerCount': 1,
      'likeCount': 0,
      'giftCount': 0,
      'commentCount': 0,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
