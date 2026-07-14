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
    required this.imageUrl,
    required this.hostName,
    required this.hostAvatarUrl,
    required this.viewerCount,
    required this.likeCount,
    required this.giftCount,
    required this.commentCount,
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
  final String? imageUrl;
  final String hostName;
  final String? hostAvatarUrl;
  final int viewerCount;
  final int likeCount;
  final int giftCount;
  final int commentCount;

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
      imageUrl: firstString(data, [
        'imageUrl',
        'image',
        'coverImage',
        'thumbnailUrl',
        'photoUrl',
      ]),
      hostName: firstString(data, [
        'hostName',
        'creatorName',
        'organizer',
        'postedBy',
        'authorName',
      ], fallback: 'VU Live'),
      hostAvatarUrl: firstString(data, [
        'hostAvatarUrl',
        'hostPhotoUrl',
        'creatorAvatar',
        'avatarUrl',
        'profileImage',
      ]),
      viewerCount:
          firstInt(data, ['viewerCount', 'viewers', 'watching']) ??
          _fallbackCount(doc.id, 900, 8500),
      likeCount:
          firstInt(data, ['likeCount', 'likes', 'reactions']) ??
          _fallbackCount('${doc.id}_likes', 120, 2400),
      giftCount:
          firstInt(data, ['giftCount', 'gifts']) ??
          _fallbackCount('${doc.id}_gifts', 8, 220),
      commentCount:
          firstInt(data, ['commentCount', 'comments']) ??
          _fallbackCount('${doc.id}_comments', 12, 360),
    );
  }

  static int _fallbackCount(String seed, int min, int max) {
    final spread = max - min;
    if (spread <= 0) return min;
    return min + seed.hashCode.abs() % spread;
  }
}
