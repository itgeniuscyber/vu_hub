import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/utils/firestore_parsing.dart';

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
      title: firstString(data, [
        'subject',
        'title',
        'name',
      ], fallback: 'Past paper'),
      faculty: firstString(data, [
        'faculty',
        'department',
        'school',
      ], fallback: 'Victoria University'),
      fileType: firstString(data, [
        'fileType',
        'type',
        'extension',
      ], fallback: 'pdf'),
      fileUrl: firstString(data, ['fileUrl', 'url', 'downloadUrl']),
      thumbnailUrl:
          asString(data['thumbnailUrl']) ?? asString(data['previewImageUrl']),
      uploadedBy: firstString(data, [
        'uploadedBy',
        'authorName',
        'lecturerName',
        'createdByName',
      ], fallback: 'VU Hub'),
      uploadedAt: firstDate(data, ['uploadedAt', 'timestamp', 'createdAt']),
    );
  }
}
