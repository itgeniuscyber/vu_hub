import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/utils/firestore_parsing.dart';

class CommunityMessage {
  const CommunityMessage({
    required this.id,
    required this.text,
    required this.senderName,
    required this.senderId,
    required this.createdAt,
    required this.isPinned,
  });

  final String id;
  final String text;
  final String senderName;
  final String senderId;
  final DateTime? createdAt;
  final bool isPinned;

  factory CommunityMessage.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return CommunityMessage(
      id: doc.id,
      text: firstString(data, [
        'text',
        'message',
        'content',
        'body',
      ], fallback: 'No message'),
      senderName: firstString(data, [
        'senderName',
        'username',
        'displayName',
        'authorName',
        'name',
      ], fallback: 'VU Student'),
      senderId: firstString(data, ['senderId', 'userId', 'uid', 'authorId']),
      createdAt: firstDate(data, ['createdAt', 'timestamp', 'sentAt', 'time']),
      isPinned: firstBool(data, ['isPinned', 'pinned']),
    );
  }
}

class DiscussionThread {
  const DiscussionThread({
    required this.id,
    required this.title,
    required this.body,
    required this.authorName,
    required this.category,
    required this.commentCount,
    required this.createdAt,
    required this.isResolved,
  });

  final String id;
  final String title;
  final String body;
  final String authorName;
  final String category;
  final int commentCount;
  final DateTime? createdAt;
  final bool isResolved;

  factory DiscussionThread.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return DiscussionThread(
      id: doc.id,
      title: firstString(data, [
        'title',
        'topic',
        'subject',
      ], fallback: 'Discussion topic'),
      body: firstString(data, [
        'body',
        'content',
        'text',
        'description',
      ], fallback: 'Open the thread to see details.'),
      authorName: firstString(data, [
        'authorName',
        'createdByName',
        'username',
        'displayName',
        'author',
      ], fallback: 'VU Student'),
      category: firstString(data, [
        'category',
        'tag',
        'topicType',
      ], fallback: 'General'),
      commentCount:
          firstInt(data, [
            'commentCount',
            'replies',
            'replyCount',
            'answers',
          ]) ??
          0,
      createdAt: firstDate(data, ['createdAt', 'timestamp', 'postedAt']),
      isResolved: firstBool(data, ['isResolved', 'resolved', 'closed']),
    );
  }
}

class CommunityPost {
  const CommunityPost({
    required this.id,
    required this.caption,
    required this.authorName,
    required this.imageUrl,
    required this.createdAt,
    required this.likeCount,
    required this.commentCount,
    required this.category,
  });

  final String id;
  final String caption;
  final String authorName;
  final String? imageUrl;
  final DateTime? createdAt;
  final int likeCount;
  final int commentCount;
  final String category;

  factory CommunityPost.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return CommunityPost(
      id: doc.id,
      caption: firstString(data, [
        'caption',
        'content',
        'body',
        'text',
        'description',
      ], fallback: 'Campus update'),
      authorName: firstString(data, [
        'authorName',
        'username',
        'displayName',
        'postedBy',
        'author',
      ], fallback: 'VU Community'),
      imageUrl:
          asString(data['imageUrl']) ??
          asString(data['photoUrl']) ??
          asString(data['mediaUrl']),
      createdAt: firstDate(data, ['createdAt', 'timestamp', 'postedAt']),
      likeCount: firstInt(data, ['likeCount', 'likes', 'reactions']) ?? 0,
      commentCount:
          firstInt(data, ['commentCount', 'comments', 'replyCount']) ?? 0,
      category: firstString(data, [
        'category',
        'type',
        'audience',
      ], fallback: 'Community'),
    );
  }
}
