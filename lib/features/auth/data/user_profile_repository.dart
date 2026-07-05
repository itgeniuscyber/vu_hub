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
}
