import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../auth/data/user_profile.dart';
import 'app_notification.dart';

class NotificationRepository {
  NotificationRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Stream<List<CampusNotification>> watchLatest() {
    return _firestore
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .limit(80)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map(CampusNotification.fromDoc).toList();
        });
  }

  Stream<int> watchRecentCount() {
    final since = Timestamp.fromDate(
      DateTime.now().subtract(const Duration(days: 2)),
    );
    return _firestore
        .collection('notifications')
        .where('createdAt', isGreaterThan: since)
        .limit(20)
        .snapshots()
        .map((snapshot) => snapshot.size);
  }

  Future<void> saveToken({
    required String uid,
    required String token,
    required UserProfile? profile,
  }) async {
    if (token.trim().isEmpty) return;
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('notificationTokens')
        .doc(_tokenDocumentId(token))
        .set({
          'token': token,
          'userId': uid,
          'platform': _platformLabel(),
          'role': profile == null
              ? 'student'
              : UserProfile.roleKey(profile.role),
          'faculty': profile?.faculty ?? '',
          'updatedAt': FieldValue.serverTimestamp(),
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
  }

  Future<void> deleteToken({required String uid, required String token}) async {
    if (token.trim().isEmpty) return;
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('notificationTokens')
        .doc(_tokenDocumentId(token))
        .delete();
  }

  String _tokenDocumentId(String token) {
    return base64Url.encode(utf8.encode(token)).replaceAll('=', '');
  }

  String _platformLabel() {
    if (kIsWeb) return 'web';
    return defaultTargetPlatform.name;
  }
}
