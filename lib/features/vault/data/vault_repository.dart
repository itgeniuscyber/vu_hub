import 'package:cloud_firestore/cloud_firestore.dart';

import 'vault_resource.dart';

class VaultRepository {
  VaultRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Stream<List<VaultResource>> watchPastPapers() {
    return _firestore.collection('past_papers').limit(60).snapshots().map((
      snapshot,
    ) {
      final resources = snapshot.docs.map(VaultResource.fromPastPaper).toList();
      resources.sort((a, b) {
        final left = a.uploadedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final right = b.uploadedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return right.compareTo(left);
      });
      return resources;
    });
  }
}
