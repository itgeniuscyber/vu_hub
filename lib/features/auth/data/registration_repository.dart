import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'user_profile.dart';

class RegistrationRepository {
  RegistrationRepository({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  Future<void> register({
    required String fullName,
    required String email,
    required String password,
    required AppUserRole requestedRole,
    required String faculty,
    required String regNo,
    String registrationCode = '',
  }) async {
    UserCredential? credential;
    final normalizedCode = registrationCode.trim().toUpperCase();
    final roleKey = UserProfile.roleKey(requestedRole);

    try {
      credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = credential.user;
      if (user == null) {
        throw FirebaseAuthException(
          code: 'registration-failed',
          message: 'Account could not be created.',
        );
      }

      if (requestedRole != AppUserRole.student) {
        if (normalizedCode.isEmpty) {
          throw FirebaseAuthException(
            code: 'missing-registration-code',
            message: 'A registration code is required for this role.',
          );
        }
        await _verifyRegistrationCode(normalizedCode, roleKey);
      }

      await user.updateDisplayName(fullName.trim());
      await _firestore.collection('users').doc(user.uid).set({
        'displayName': fullName.trim(),
        'name': fullName.trim(),
        'email': email.trim(),
        'role': roleKey,
        'faculty': faculty.trim(),
        'regNo': regNo.trim(),
        'registrationCode': requestedRole == AppUserRole.student
            ? null
            : normalizedCode,
        'createdAt': FieldValue.serverTimestamp(),
        'profileStatus': requestedRole == AppUserRole.student
            ? 'active'
            : 'verified_by_code',
      });
    } catch (_) {
      final user = credential?.user;
      if (user != null) {
        try {
          await user.delete();
        } catch (_) {
          await _auth.signOut();
        }
      }
      rethrow;
    }
  }

  Future<void> _verifyRegistrationCode(String code, String roleKey) async {
    final doc = await _firestore
        .collection('registration_codes')
        .doc(code)
        .get();
    final data = doc.data();
    if (!doc.exists || data == null) {
      throw FirebaseAuthException(
        code: 'invalid-registration-code',
        message: 'This registration code does not exist.',
      );
    }
    if (data['active'] != true || data['role'] != roleKey) {
      throw FirebaseAuthException(
        code: 'invalid-registration-code',
        message: 'This registration code is not valid for the selected role.',
      );
    }
    final expiresAt = data['expiresAt'];
    if (expiresAt is Timestamp && expiresAt.toDate().isBefore(DateTime.now())) {
      throw FirebaseAuthException(
        code: 'expired-registration-code',
        message: 'This registration code has expired.',
      );
    }
  }
}
