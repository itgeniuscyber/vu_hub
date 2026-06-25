import 'package:cloud_firestore/cloud_firestore.dart';

import 'announcement.dart';

class AnnouncementRepository {
  AnnouncementRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Stream<List<Announcement>> watchLatest() {
    return _firestore
        .collection('announcements')
        .orderBy('timestamp', descending: true)
        .limit(30)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(Announcement.fromDoc).toList());
  }
}
