import 'package:cloud_firestore/cloud_firestore.dart';

import 'app_update.dart';

class AppUpdateRepository {
  AppUpdateRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Stream<AppUpdate?> watchLatestActiveUpdate() {
    return _firestore
        .collection('app_updates')
        .where('isActive', isEqualTo: true)
        .limit(20)
        .snapshots()
        .map((snapshot) {
          final updates = snapshot.docs.map(AppUpdate.fromDoc).toList()
            ..sort((a, b) {
              final versionCompare = b.versionCode.compareTo(a.versionCode);
              if (versionCompare != 0) return versionCompare;
              final left = b.createdAt ?? DateTime(1970);
              final right = a.createdAt ?? DateTime(1970);
              return left.compareTo(right);
            });
          return updates.isEmpty ? null : updates.first;
        });
  }

  Stream<List<AppUpdate>> watchUpdates() {
    return _firestore.collection('app_updates').limit(80).snapshots().map((
      snapshot,
    ) {
      final updates = snapshot.docs.map(AppUpdate.fromDoc).toList()
        ..sort((a, b) {
          final versionCompare = b.versionCode.compareTo(a.versionCode);
          if (versionCompare != 0) return versionCompare;
          final left = b.createdAt ?? DateTime(1970);
          final right = a.createdAt ?? DateTime(1970);
          return left.compareTo(right);
        });
      return updates;
    });
  }

  Future<void> publishUpdate({
    required String versionName,
    required int versionCode,
    required String title,
    required String summary,
    required List<String> changes,
    required String updateUrl,
    required bool isRequired,
    required bool isActive,
  }) async {
    await _firestore.collection('app_updates').add({
      'versionName': versionName.trim(),
      'versionCode': versionCode,
      'title': title.trim(),
      'summary': summary.trim(),
      'body': summary.trim(),
      'changes': changes
          .map((change) => change.trim())
          .where((change) => change.isNotEmpty)
          .toList(),
      'updateUrl': updateUrl.trim(),
      'isRequired': isRequired,
      'forceUpdate': isRequired,
      'isActive': isActive,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateStatus({
    required String id,
    required bool isActive,
  }) async {
    await _firestore.collection('app_updates').doc(id).update({
      'isActive': isActive,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteUpdate(String id) {
    return _firestore.collection('app_updates').doc(id).delete();
  }
}
