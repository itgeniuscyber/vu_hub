import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/utils/firestore_parsing.dart';

enum CampusEventStatus { upcoming, live, completed }

class CampusEvent {
  const CampusEvent({
    required this.id,
    required this.title,
    required this.description,
    required this.location,
    required this.streamUrl,
    required this.startTime,
    required this.endTime,
    required this.category,
    required this.isFeatured,
  });

  final String id;
  final String title;
  final String description;
  final String location;
  final String? streamUrl;
  final DateTime? startTime;
  final DateTime? endTime;
  final String category;
  final bool isFeatured;

  CampusEventStatus get status {
    final now = DateTime.now();
    if (startTime == null) return CampusEventStatus.upcoming;
    if (endTime != null && endTime!.isBefore(now)) {
      return CampusEventStatus.completed;
    }
    if (startTime!.isBefore(now) &&
        (endTime == null || endTime!.isAfter(now))) {
      return CampusEventStatus.live;
    }
    return CampusEventStatus.upcoming;
  }

  factory CampusEvent.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return CampusEvent(
      id: doc.id,
      title: firstString(data, [
        'title',
        'name',
        'eventTitle',
      ], fallback: 'Campus event'),
      description: firstString(data, [
        'description',
        'details',
        'body',
        'summary',
      ], fallback: 'Event details will appear here.'),
      location: firstString(data, [
        'location',
        'venue',
        'place',
      ], fallback: 'Victoria University'),
      streamUrl:
          asString(data['streamUrl']) ??
          asString(data['liveUrl']) ??
          asString(data['meetingUrl']),
      startTime: firstDate(data, [
        'startTime',
        'date',
        'eventDate',
        'timestamp',
        'startsAt',
      ]),
      endTime: firstDate(data, ['endTime', 'endsAt', 'finishTime']),
      category: firstString(data, ['category', 'type'], fallback: 'General'),
      isFeatured: firstBool(data, ['isFeatured', 'featured', 'highlighted']),
    );
  }
}
