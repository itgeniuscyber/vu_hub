import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/utils/firestore_parsing.dart';

class AppUpdate {
  const AppUpdate({
    required this.id,
    required this.versionName,
    required this.versionCode,
    required this.title,
    required this.summary,
    required this.changes,
    required this.updateUrl,
    required this.isRequired,
    required this.isActive,
    required this.createdAt,
  });

  final String id;
  final String versionName;
  final int versionCode;
  final String title;
  final String summary;
  final List<String> changes;
  final String updateUrl;
  final bool isRequired;
  final bool isActive;
  final DateTime? createdAt;

  factory AppUpdate.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return AppUpdate(
      id: doc.id,
      versionName: firstString(data, [
        'versionName',
        'version',
        'buildName',
      ], fallback: 'New version'),
      versionCode: firstInt(data, [
        'versionCode',
        'buildNumber',
        'code',
      ]) ?? 0,
      title: firstString(data, [
        'title',
        'headline',
      ], fallback: 'New VU Hub update'),
      summary: firstString(data, [
        'summary',
        'body',
        'description',
      ], fallback: 'A new VU Hub version is available.'),
      changes: asStringList(data['changes']).isNotEmpty
          ? asStringList(data['changes'])
          : asStringList(data['whatsNew']),
      updateUrl: firstString(data, [
        'updateUrl',
        'downloadUrl',
        'link',
        'url',
      ]),
      isRequired: firstBool(data, [
        'isRequired',
        'required',
        'forceUpdate',
      ]),
      isActive: firstBool(data, ['isActive', 'active'], fallback: true),
      createdAt: firstDate(data, ['createdAt', 'publishedAt', 'timestamp']),
    );
  }

  bool isNewerThan(int installedBuildNumber) {
    return isActive && versionCode > installedBuildNumber;
  }
}
