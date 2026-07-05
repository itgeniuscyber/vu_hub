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
