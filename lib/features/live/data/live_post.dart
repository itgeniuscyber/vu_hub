import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/utils/firestore_parsing.dart';
import 'campus_event.dart';

enum LivePostType { live, shortVideo, recordedLive }

enum LivePostStatus { scheduled, live, ended, processing, published }

class LivePost {
  const LivePost({
    required this.id,
    required this.type,
    required this.status,
    required this.title,
    required this.description,
    required this.hostId,
    required this.hostName,
    required this.hostAvatarUrl,
    required this.category,
    required this.coverUrl,
    required this.videoUrl,
    required this.playbackUrl,
    required this.provider,
    required this.providerRoomId,
    required this.viewerCount,
    required this.playCount,
    required this.likeCount,
    required this.giftCount,
    required this.commentCount,
    required this.createdAt,
    required this.startedAt,
    required this.endedAt,
    required this.location,
    required this.source,
  });

  final String id;
  final LivePostType type;
  final LivePostStatus status;
  final String title;
  final String description;
  final String hostId;
  final String hostName;
  final String? hostAvatarUrl;
  final String category;
  final String? coverUrl;
  final String? videoUrl;
  final String? playbackUrl;
  final String provider;
  final String providerRoomId;
  final int viewerCount;
  final int playCount;
  final int likeCount;
  final int giftCount;
  final int commentCount;
  final DateTime? createdAt;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final String location;
  final String source;

  bool get isLive => status == LivePostStatus.live;

  bool get isRealtimeRoom =>
      provider == 'zego_uikit' && providerRoomId.trim().isNotEmpty;

  bool get hasPlayableVideo => (videoUrl ?? playbackUrl ?? '').isNotEmpty;

  bool get canOpenLiveExperience => hasPlayableVideo || isRealtimeRoom;

  String? get primaryVideoUrl => videoUrl?.isNotEmpty == true
      ? videoUrl
      : playbackUrl?.isNotEmpty == true
      ? playbackUrl
      : null;

  factory LivePost.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return LivePost(
      id: doc.id,
      type: _parseType(firstString(data, ['type'], fallback: 'live')),
      status: _parseStatus(
        firstString(data, ['status'], fallback: 'published'),
      ),
      title: firstString(data, [
        'title',
        'caption',
        'name',
      ], fallback: 'VU Live'),
      description: firstString(data, [
        'description',
        'body',
        'summary',
      ], fallback: 'Campus live moment'),
      hostId: firstString(data, ['hostId', 'creatorId', 'userId']),
      hostName: firstString(data, [
        'hostName',
        'creatorName',
        'displayName',
        'postedBy',
      ], fallback: 'VU Creator'),
      hostAvatarUrl: firstString(data, [
        'hostAvatarUrl',
        'hostPhotoUrl',
        'avatarUrl',
        'profileImage',
      ]),
      category: firstString(data, [
        'category',
        'typeLabel',
      ], fallback: 'Campus'),
      coverUrl: firstString(data, [
        'coverUrl',
        'thumbnailUrl',
        'imageUrl',
        'posterUrl',
      ]),
      videoUrl: firstString(data, ['videoUrl', 'fileUrl', 'mediaUrl']),
      playbackUrl: firstString(data, ['playbackUrl', 'streamUrl', 'liveUrl']),
      provider: firstString(data, ['provider'], fallback: 'firebase'),
      providerRoomId: firstString(data, [
        'providerRoomId',
        'roomId',
        'streamId',
      ]),
      viewerCount: firstInt(data, ['viewerCount', 'viewers', 'watching']) ?? 0,
      playCount: firstInt(data, ['playCount', 'plays']) ?? 0,
      likeCount: firstInt(data, ['likeCount', 'likes', 'reactions']) ?? 0,
      giftCount: firstInt(data, ['giftCount', 'gifts']) ?? 0,
      commentCount: firstInt(data, ['commentCount', 'comments']) ?? 0,
      createdAt: firstDate(data, ['createdAt', 'uploadedAt', 'publishedAt']),
      startedAt: firstDate(data, ['startedAt', 'startTime']),
      endedAt: firstDate(data, ['endedAt', 'endTime']),
      location: firstString(data, [
        'location',
        'venue',
      ], fallback: 'Victoria University'),
      source: 'live_posts',
    );
  }

  factory LivePost.fromEvent(CampusEvent event) {
    return LivePost(
      id: 'event_${event.id}',
      type: event.status == CampusEventStatus.completed
          ? LivePostType.recordedLive
          : LivePostType.live,
      status: switch (event.status) {
        CampusEventStatus.live => LivePostStatus.live,
        CampusEventStatus.completed => LivePostStatus.ended,
        CampusEventStatus.upcoming => LivePostStatus.scheduled,
      },
      title: event.title,
      description: event.description,
      hostId: '',
      hostName: event.hostName,
      hostAvatarUrl: event.hostAvatarUrl,
      category: event.category,
      coverUrl: event.imageUrl,
      videoUrl: null,
      playbackUrl: event.streamUrl,
      provider: 'events',
      providerRoomId: event.id,
      viewerCount: event.viewerCount,
      playCount: event.viewerCount,
      likeCount: event.likeCount,
      giftCount: event.giftCount,
      commentCount: event.commentCount,
      createdAt: event.startTime,
      startedAt: event.startTime,
      endedAt: event.endTime,
      location: event.location,
      source: 'events',
    );
  }

  static LivePostType _parseType(String value) {
    switch (value.trim().toLowerCase()) {
      case 'short_video':
      case 'shortvideo':
      case 'video':
        return LivePostType.shortVideo;
      case 'recorded_live':
      case 'recordedlive':
      case 'replay':
        return LivePostType.recordedLive;
      case 'live':
      default:
        return LivePostType.live;
    }
  }

  static LivePostStatus _parseStatus(String value) {
    switch (value.trim().toLowerCase()) {
      case 'scheduled':
        return LivePostStatus.scheduled;
      case 'live':
        return LivePostStatus.live;
      case 'ended':
        return LivePostStatus.ended;
      case 'processing':
        return LivePostStatus.processing;
      case 'published':
      default:
        return LivePostStatus.published;
    }
  }
}
