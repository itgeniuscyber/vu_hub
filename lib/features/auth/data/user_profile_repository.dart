import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'user_profile.dart';

class UserProfileRepository {
  UserProfileRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  Stream<UserProfile?> watchProfile(String uid) {
    return _firestore.collection('users').doc(uid).snapshots().map((doc) {
      final data = doc.data();
      if (data == null) {
        final user = _auth.currentUser;
        return UserProfile.fallback(
          uid: uid,
          displayName: user?.displayName ?? 'VU User',
          email: user?.email ?? '',
        );
      }
      return UserProfile.fromFirestore(uid, data);
    });
  }

  Future<UserProfile?> fetchProfile(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    final data = doc.data();
    if (data == null) {
      final user = _auth.currentUser;
      return UserProfile.fallback(
        uid: uid,
        displayName: user?.displayName ?? 'VU User',
        email: user?.email ?? '',
      );
    }
    return UserProfile.fromFirestore(uid, data);
  }

  Future<void> updateProfile({
    required String uid,
    required String displayName,
    required String faculty,
    required String regNo,
  }) async {
    final trimmedName = displayName.trim();
    await _firestore.collection('users').doc(uid).set({
      'displayName': trimmedName,
      'name': trimmedName,
      'faculty': faculty.trim(),
      'regNo': regNo.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    final user = _auth.currentUser;
    if (user != null && user.uid == uid && trimmedName.isNotEmpty) {
      await user.updateDisplayName(trimmedName);
    }
  }
}
