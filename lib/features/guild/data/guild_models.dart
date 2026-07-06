import '../../../core/utils/firestore_parsing.dart';

class GuildUpdate {
  const GuildUpdate({
    required this.title,
    required this.body,
    required this.category,
    required this.isVerified,
  });

  final String title;
  final String body;
  final String category;
  final bool isVerified;

  factory GuildUpdate.fromResourceMap(Map<String, dynamic> data) {
    return GuildUpdate(
      title: firstString(data, ['title', 'name'], fallback: 'Guild update'),
      body: firstString(data, [
        'description',
        'summary',
        'body',
        'content',
      ], fallback: 'Student guild information.'),
      category: firstString(data, ['category', 'type'], fallback: 'Guild'),
      isVerified: true,
    );
  }
}

class FeedbackInsight {
  const FeedbackInsight({
    required this.label,
    required this.count,
    required this.description,
  });

  final String label;
  final int count;
  final String description;
}

class GuildCabinetMember {
  const GuildCabinetMember({
    required this.role,
    required this.office,
    required this.scope,
    required this.contactHint,
    required this.iconCodePoint,
    this.name,
    this.isExecutive = false,
  });

  final String role;
  final String office;
  final String scope;
  final String contactHint;
  final int iconCodePoint;
  final String? name;
  final bool isExecutive;
}
