import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';

import 'announcement.dart';

class AnnouncementRepository {
  AnnouncementRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    FirebaseStorage? storage,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth,
       _storage = storage;

  final FirebaseFirestore _firestore;
  final FirebaseAuth? _auth;
  final FirebaseStorage? _storage;

  Stream<List<Announcement>> watchLatest() {
    return _firestore.collection('announcements').limit(60).snapshots().map((
      snapshot,
    ) {
      final items = snapshot.docs.map(Announcement.fromDoc).toList();
      items.sort((a, b) {
        final left = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final right = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return right.compareTo(left);
      });
      return items;
    });
  }

  Future<void> publishAnnouncement({
    required String title,
    required String content,
    required String category,
    required String publishedBy,
    required String authorId,
    String authorRole = '',
    String imageUrl = '',
    PlatformFile? imageFile,
    String linkUrl = '',
    bool isPinned = false,
  }) async {
    var resolvedImageUrl = imageUrl.trim();
    if (imageFile != null) {
      try {
        resolvedImageUrl = await _uploadPulseImage(
          userId: authorId,
          image: imageFile,
        );
      } catch (error) {
        throw Exception('Image upload failed: ${_friendlyUploadError(error)}');
      }
    }
    await _firestore.collection('announcements').add({
      'title': title.trim(),
      'content': content.trim(),
      'body': content.trim(),
      'category': category,
      'publishedBy': publishedBy.trim().isEmpty
          ? 'VU Admin'
          : publishedBy.trim(),
      'authorId': authorId,
      'authorRole': authorRole.trim(),
      'imageUrl': resolvedImageUrl,
      'linkUrl': linkUrl.trim(),
      'likeCount': 0,
      'commentCount': 0,
      'viewCount': 0,
      'isPinned': isPinned,
      'pinned': isPinned,
      'timestamp': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
      'publishedAt': FieldValue.serverTimestamp(),
    });
  }

  String _friendlyUploadError(Object error) {
    if (error is FirebaseException) {
      final message = error.message?.trim();
      if (message != null && message.isNotEmpty) return message;
      return error.code;
    }
    final message = error.toString().trim();
    return message.isEmpty ? 'Please try another image.' : message;
  }

  Future<String> _uploadPulseImage({
    required String userId,
    required PlatformFile image,
  }) async {
    final bytes = image.bytes;
    final filePath = image.path;
    if ((bytes == null || bytes.isEmpty) && filePath == null) {
      throw StateError('The selected image could not be read.');
    }

    final extension = image.extension?.toLowerCase();
    final contentType = switch (extension) {
      'jpg' || 'jpeg' => 'image/jpeg',
      'webp' => 'image/webp',
      'gif' => 'image/gif',
      _ => 'image/png',
    };
    final safeName = image.name
        .replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_')
        .toLowerCase();
    final path =
        'pulse_images/$userId/${DateTime.now().millisecondsSinceEpoch}_$safeName';
    final ref = (_storage ?? FirebaseStorage.instance).ref(path);

    final metadata = SettableMetadata(
      contentType: contentType,
      customMetadata: {'uploadedBy': userId},
    );
    if (bytes != null && bytes.isNotEmpty) {
      await ref.putData(bytes, metadata);
    } else {
      await ref.putFile(File(filePath!), metadata);
    }
    return ref.getDownloadURL();
  }

  Stream<List<AnnouncementComment>> watchComments(String announcementId) {
    return _firestore
        .collection('announcements')
        .doc(announcementId)
        .collection('comments')
        .limit(80)
        .snapshots()
        .map((snapshot) {
          final items = snapshot.docs.map(AnnouncementComment.fromDoc).toList();
          items.sort((a, b) {
            final left = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            final right = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            return right.compareTo(left);
          });
          return items;
        });
  }

  Future<void> like(String announcementId) async {
    await _firestore.collection('announcements').doc(announcementId).update({
      'likeCount': FieldValue.increment(1),
    });
  }

  Future<void> sendComment({
    required String announcementId,
    required String text,
    required String displayName,
  }) async {
    final user = (_auth ?? FirebaseAuth.instance).currentUser;
    if (user == null || text.trim().isEmpty) return;
    final postRef = _firestore.collection('announcements').doc(announcementId);
    final commentRef = postRef.collection('comments').doc();
    final batch = _firestore.batch()
      ..set(commentRef, {
        'text': text.trim(),
        'userId': user.uid,
        'displayName': displayName.trim().isEmpty
            ? user.email ?? 'VU Student'
            : displayName.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      })
      ..update(postRef, {'commentCount': FieldValue.increment(1)});
    await batch.commit();
  }
}
