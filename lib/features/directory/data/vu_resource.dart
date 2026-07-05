import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/utils/firestore_parsing.dart';

class VuResource {
  const VuResource({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.url,
    required this.audience,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final String description;
  final String category;
  final String url;
  final String audience;
  final DateTime? updatedAt;

  factory VuResource.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return VuResource(
      id: doc.id,
      title: firstString(data, [
        'title',
        'name',
        'resourceTitle',
      ], fallback: 'VU Resource'),
      description: firstString(data, [
        'description',
        'summary',
        'body',
        'content',
      ], fallback: 'Helpful campus resource'),
      category: firstString(data, [
        'category',
        'type',
        'faculty',
      ], fallback: 'Support'),
      url: firstString(data, ['url', 'link', 'resourceUrl', 'fileUrl']),
      audience: firstString(data, [
        'audience',
        'group',
        'target',
      ], fallback: 'Students'),
      updatedAt: firstDate(data, [
        'updatedAt',
        'timestamp',
        'createdAt',
        'publishedAt',
      ]),
    );
  }
}
