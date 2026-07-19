import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../notifications/data/notification_service.dart';
import 'user_profile.dart';
import 'user_profile_repository.dart';

class AppSession extends ChangeNotifier {
  AppSession({FirebaseAuth? auth, UserProfileRepository? userProfileRepository})
    : _auth = auth ?? FirebaseAuth.instance,
      _userProfileRepository =
          userProfileRepository ?? UserProfileRepository() {
    _authSubscription = _auth.authStateChanges().listen(_handleAuthChanged);
    _handleAuthChanged(_auth.currentUser);
  }

  final FirebaseAuth _auth;
  final UserProfileRepository _userProfileRepository;

  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<UserProfile?>? _profileSubscription;

  User? _firebaseUser;
  UserProfile? _profile;
  bool _isInitializing = true;
  bool _isProfileLoading = false;

  User? get firebaseUser => _firebaseUser;
  UserProfile? get profile => _profile;
  bool get isInitializing => _isInitializing;
  bool get isProfileLoading => _isProfileLoading;
  bool get isSignedIn => _firebaseUser != null;
  AppUserRole get role => _profile?.role ?? AppUserRole.student;
  bool get canPublishAnnouncements =>
      _profile?.canPublishAnnouncements ?? false;
  bool get canUploadResources => _profile?.canUploadResources ?? false;
  bool get canViewAdminInsights => _profile?.canViewAdminInsights ?? false;

  Future<void> _handleAuthChanged(User? user) async {
    final previousUser = _firebaseUser;
    _firebaseUser = user;
    await _profileSubscription?.cancel();
    _profileSubscription = null;

    if (user == null) {
      await NotificationService.instance.detachUser(previousUser);
      _profile = null;
      _isInitializing = false;
      _isProfileLoading = false;
      notifyListeners();
      return;
    }

    _isInitializing = false;
    _isProfileLoading = true;
    notifyListeners();

    _profileSubscription = _userProfileRepository.watchProfile(user.uid).listen(
      (profile) {
        _profile =
            profile ??
            UserProfile.fallback(
              uid: user.uid,
              displayName: user.displayName ?? 'VU User',
              email: user.email ?? '',
            );
        unawaited(NotificationService.instance.syncUser(user, _profile));
        _isProfileLoading = false;
        notifyListeners();
      },
    );
  }

  Future<void> signOut() => _auth.signOut();

  @override
  void dispose() {
    _authSubscription?.cancel();
    _profileSubscription?.cancel();
    NotificationService.instance.dispose();
    super.dispose();
  }
}
