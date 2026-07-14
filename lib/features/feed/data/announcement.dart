import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/utils/firestore_parsing.dart';

class Announcement {
  const Announcement({
    required this.id,
    required this.title,
    required this.content,
    required this.category,
    required this.publishedBy,
    required this.authorRole,
    required this.authorAvatarUrl,
    required this.imageUrl,
    required this.linkUrl,
    required this.likeCount,
    required this.commentCount,
    required this.viewCount,
    required this.createdAt,
    required this.isPinned,
  });

  final String id;
  final String title;
  final String content;
  final String category;
  final String publishedBy;
  final String authorRole;
  final String authorAvatarUrl;
  final String imageUrl;
  final String linkUrl;
  final int likeCount;
  final int commentCount;
  final int viewCount;
  final DateTime? createdAt;
  final bool isPinned;

  factory Announcement.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return Announcement(
      id: doc.id,
      title: firstString(data, [
        'title',
        'headline',
        'subject',
      ], fallback: 'Untitled announcement'),
      content: firstString(data, [
        'content',
        'body',
        'description',
      ], fallback: ''),
      category: firstString(data, ['category', 'type'], fallback: 'General'),
      publishedBy: firstString(data, [
        'publishedBy',
        'author',
        'authorName',
        'createdByName',
      ], fallback: 'VU'),
      authorRole: firstString(data, [
        'authorRole',
        'role',
        'publishedByRole',
      ], fallback: ''),
      authorAvatarUrl: firstString(data, [
        'authorAvatarUrl',
        'avatarUrl',
        'profileImage',
        'photoUrl',
      ]),
      imageUrl: firstString(data, [
        'imageUrl',
        'coverUrl',
        'mediaUrl',
        'thumbnailUrl',
      ]),
      linkUrl: firstString(data, ['linkUrl', 'url', 'resourceUrl']),
      likeCount: firstInt(data, ['likeCount', 'likes', 'reactions']) ?? 0,
      commentCount:
          firstInt(data, ['commentCount', 'comments', 'replies']) ?? 0,
      viewCount: firstInt(data, ['viewCount', 'views', 'seenCount']) ?? 0,
      createdAt: firstDate(data, ['timestamp', 'createdAt', 'publishedAt']),
      isPinned: firstBool(data, ['isPinned', 'pinned']),
    );
  }
}

class AnnouncementComment {
  const AnnouncementComment({
    required this.id,
    required this.text,
    required this.userId,
    required this.displayName,
    required this.createdAt,
  });

  final String id;
  final String text;
  final String userId;
  final String displayName;
  final DateTime? createdAt;

  factory AnnouncementComment.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    return AnnouncementComment(
      id: doc.id,
      text: firstString(data, ['text', 'comment', 'message']),
      userId: firstString(data, ['userId', 'authorId']),
      displayName: firstString(data, [
        'displayName',
        'authorName',
        'userName',
      ], fallback: 'VU Student'),
      createdAt: firstDate(data, ['createdAt', 'timestamp']),
    );
  }
}
