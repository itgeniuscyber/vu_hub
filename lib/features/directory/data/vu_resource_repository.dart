import 'package:cloud_firestore/cloud_firestore.dart';

import 'vu_resource.dart';

class VuResourceRepository {
  VuResourceRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Stream<List<VuResource>> watchResources() {
    return _firestore.collection('vu_resources').limit(40).snapshots().map((
      snapshot,
    ) {
      final items = snapshot.docs.map(VuResource.fromDoc).toList();
      items.sort(
        (a, b) => (b.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0))
            .compareTo(a.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0)),
      );
      return items;
    });
  }
}
