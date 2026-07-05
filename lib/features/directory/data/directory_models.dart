import '../../../core/utils/firestore_parsing.dart';

class DirectoryEntry {
  const DirectoryEntry({
    required this.name,
    required this.department,
    required this.role,
    required this.email,
    required this.phone,
    required this.location,
    required this.keywords,
  });

  final String name;
  final String department;
  final String role;
  final String email;
  final String phone;
  final String location;
  final List<String> keywords;

  factory DirectoryEntry.fromMap(Map<String, dynamic> data) {
    return DirectoryEntry(
      name: firstString(data, [
        'name',
        'title',
      ], fallback: 'Victoria University'),
      department: firstString(data, [
        'department',
        'office',
        'faculty',
      ], fallback: 'Student Support'),
      role: firstString(data, [
        'role',
        'position',
        'type',
      ], fallback: 'Support Desk'),
      email: firstString(data, ['email', 'contactEmail']),
      phone: firstString(data, ['phone', 'phoneNumber', 'contactNumber']),
      location: firstString(data, [
        'location',
        'officeLocation',
        'room',
      ], fallback: 'Main Campus'),
      keywords: asStringList(data['keywords']),
    );
  }
}
