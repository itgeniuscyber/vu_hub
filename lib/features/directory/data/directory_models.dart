import '../../../core/utils/firestore_parsing.dart';

class DirectoryEntry {
  const DirectoryEntry({
    required this.id,
    required this.name,
    required this.department,
    required this.role,
    required this.email,
    required this.phone,
    required this.location,
    required this.keywords,
    this.category = 'Office',
    this.description = '',
    this.officeHours = '',
    this.website = '',
    this.mapUrl = '',
    this.building = '',
    this.services = const [],
  });

  final String id;
  final String name;
  final String department;
  final String role;
  final String email;
  final String phone;
  final String location;
  final List<String> keywords;
  final String category;
  final String description;
  final String officeHours;
  final String website;
  final String mapUrl;
  final String building;
  final List<String> services;

  factory DirectoryEntry.fromMap(String id, Map<String, dynamic> data) {
    return DirectoryEntry(
      id: id,
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
      category: firstString(data, [
        'category',
        'type',
        'group',
      ], fallback: 'Office'),
      description: firstString(data, [
        'description',
        'summary',
        'about',
        'details',
      ]),
      officeHours: firstString(data, ['officeHours', 'hours', 'workingHours']),
      website: firstString(data, ['website', 'url', 'link']),
      mapUrl: firstString(data, ['mapUrl', 'mapsUrl', 'directionsUrl']),
      building: firstString(data, ['building', 'block']),
      keywords: asStringList(data['keywords']),
      services: asStringList(data['services']),
    );
  }

  String get routeLabel {
    final normalized = [
      category,
      department,
      role,
      name,
      ...keywords,
    ].join(' ').toLowerCase();

    if (_hasAny(normalized, ['finance', 'fees', 'tuition', 'payment'])) {
      return 'Finance';
    }
    if (_hasAny(normalized, ['registry', 'academic', 'retake', 'records'])) {
      return 'Academic';
    }
    if (_hasAny(normalized, ['ict', 'it ', 'wifi', 'portal', 'vclass'])) {
      return 'Digital';
    }
    if (_hasAny(normalized, ['support', 'counselling', 'welfare', 'health'])) {
      return 'Support';
    }
    if (_hasAny(normalized, ['faculty', 'school', 'lecturer', 'department'])) {
      return 'Faculty';
    }
    return category.trim().isEmpty ? 'Office' : category.trim();
  }

  bool get hasDirectContact => email.isNotEmpty || phone.isNotEmpty;

  static bool _hasAny(String text, List<String> values) {
    return values.any(text.contains);
  }
}
