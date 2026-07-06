import '../../../core/utils/firestore_parsing.dart';

enum AppUserRole { student, lecturer, admin, guildOfficial, unknown }

class UserProfile {
  const UserProfile({
    required this.uid,
    required this.role,
    required this.displayName,
    required this.email,
    this.faculty = '',
    this.regNo = '',
  });

  final String uid;
  final AppUserRole role;
  final String displayName;
  final String email;
  final String faculty;
  final String regNo;

  bool get canPublishAnnouncements => role == AppUserRole.admin;

  bool get canUploadResources =>
      role == AppUserRole.admin || role == AppUserRole.lecturer;

  bool get canViewAdminInsights =>
      role == AppUserRole.admin || role == AppUserRole.guildOfficial;

  factory UserProfile.fromFirestore(String uid, Map<String, dynamic> data) {
    return UserProfile(
      uid: uid,
      role: _parseRole(
        firstString(data, [
          'role',
          'userRole',
          'accountType',
        ], fallback: 'student'),
      ),
      displayName: firstString(data, [
        'displayName',
        'fullName',
        'name',
        'username',
      ], fallback: 'VU User'),
      email: firstString(data, ['email'], fallback: ''),
      faculty: firstString(data, ['faculty', 'school'], fallback: ''),
      regNo: firstString(data, [
        'regNo',
        'registrationNumber',
        'studentNo',
      ], fallback: ''),
    );
  }

  factory UserProfile.fallback({
    required String uid,
    String displayName = 'VU User',
    String email = '',
  }) {
    return UserProfile(
      uid: uid,
      role: AppUserRole.student,
      displayName: displayName,
      email: email,
    );
  }

  static String roleKey(AppUserRole role) {
    switch (role) {
      case AppUserRole.admin:
        return 'admin';
      case AppUserRole.lecturer:
        return 'lecturer';
      case AppUserRole.guildOfficial:
        return 'guild';
      case AppUserRole.unknown:
      case AppUserRole.student:
        return 'student';
    }
  }

  static AppUserRole _parseRole(String raw) {
    switch (raw.trim().toLowerCase()) {
      case 'admin':
      case 'administrator':
        return AppUserRole.admin;
      case 'lecturer':
      case 'teacher':
        return AppUserRole.lecturer;
      case 'guild':
      case 'guild_official':
      case 'guildofficial':
      case 'guild official':
        return AppUserRole.guildOfficial;
      case 'student':
        return AppUserRole.student;
      default:
        return AppUserRole.unknown;
    }
  }
}
