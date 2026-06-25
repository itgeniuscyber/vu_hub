import 'package:cloud_firestore/cloud_firestore.dart';

class VaultResource {
  const VaultResource({
    required this.id,
    required this.title,
    required this.faculty,
    required this.fileType,
    required this.fileUrl,
    required this.thumbnailUrl,
    required this.uploadedBy,
    required this.uploadedAt,
  });

  final String id;
  final String title;
  final String faculty;
  final String fileType;
  final String fileUrl;
  final String? thumbnailUrl;
  final String uploadedBy;
  final DateTime? uploadedAt;

  factory VaultResource.fromPastPaper(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    return VaultResource(
      id: doc.id,
      title: _string(data['subject']) ?? _string(data['title']) ?? 'Past paper',
      faculty: _string(data['faculty']) ?? 'Victoria University',
      fileType: _string(data['fileType']) ?? 'pdf',
      fileUrl: _string(data['fileUrl']) ?? _string(data['url']) ?? '',
      thumbnailUrl: _string(data['thumbnailUrl']),
      uploadedBy: _string(data['uploadedBy']) ?? 'VU Hub',
      uploadedAt: _date(
        data['uploadedAt'] ?? data['timestamp'] ?? data['createdAt'],
      ),
    );
  }

  static String? _string(Object? value) => value is String ? value : null;

  static DateTime? _date(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}
