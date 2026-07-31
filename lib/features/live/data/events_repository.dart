import 'package:cloud_firestore/cloud_firestore.dart';

import 'campus_event.dart';

class EventsRepository {
  EventsRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

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
}
