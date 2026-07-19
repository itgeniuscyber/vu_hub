import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';

import '../../../core/utils/firestore_parsing.dart';
import 'community_models.dart';

class CommunityRepository {
  CommunityRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    FirebaseStorage? storage,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth,
       _storage = storage;

  final FirebaseFirestore _firestore;
  final FirebaseAuth? _auth;
  final FirebaseStorage? _storage;

  Stream<List<CommunityMessage>> watchPublicChat() {
    return _firestore
        .collection('public_chat')
        .orderBy('timestamp', descending: true)
        .limit(80)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map(CommunityMessage.fromDoc).toList(),
        );
  }

  Stream<List<DiscussionThread>> watchDiscussions() {
    return _firestore.collection('discussions').limit(40).snapshots().map((
      snapshot,
    ) {
      final items = snapshot.docs.map(DiscussionThread.fromDoc).toList();
      items.sort(
        (a, b) => (b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0))
            .compareTo(a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0)),
      );
      return items;
    });
  }

  Stream<List<CommunityPost>> watchPosts() {
    return _firestore.collection('posts').limit(40).snapshots().map((snapshot) {
      final items = snapshot.docs.map(CommunityPost.fromDoc).toList();
      items.sort(
        (a, b) => (b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0))
            .compareTo(a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0)),
      );
      return items;
    });
  }

  Future<void> sendPublicMessage({
    required String text,
    CommunityMessage? replyTo,
    PlatformFile? image,
  }) async {
    final user = (_auth ?? FirebaseAuth.instance).currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'not-signed-in',
        message: 'Please sign in before sending a community message.',
      );
    }

    final trimmedText = text.trim();
    if (trimmedText.isEmpty && image == null) {
      return;
    }

    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    final profile = userDoc.data() ?? const <String, dynamic>{};
    final imageUrl = image == null
        ? null
        : await _uploadChatImage(userId: user.uid, image: image);

    final profilePhoto = firstString(profile, [
      'senderPic',
      'profileImage',
      'profileImageUrl',
      'avatarUrl',
      'photoURL',
      'photoUrl',
    ]);

    final payload = <String, dynamic>{
      'text': trimmedText.isEmpty ? 'Shared an image' : trimmedText,
      'senderId': user.uid,
      'senderName': firstString(profile, [
        'displayName',
        'fullName',
        'name',
        'username',
      ], fallback: user.displayName ?? user.email ?? 'VU Student'),
      'senderPic': profilePhoto.isNotEmpty ? profilePhoto : user.photoURL ?? '',
      'faculty': firstString(profile, [
        'faculty',
        'school',
        'department',
      ], fallback: ''),
      'createdAt': Timestamp.fromDate(DateTime.now()),
      'timestamp': FieldValue.serverTimestamp(),
      'sentAt': FieldValue.serverTimestamp(),
    };

    if (replyTo != null) {
      payload['replyToSender'] = replyTo.senderName;
      payload['replyToMessage'] = replyTo.text;
      payload['replyToMessageId'] = replyTo.id;
      payload['replyToSenderId'] = replyTo.senderId;
    }
    if (imageUrl != null) {
      payload['mediaUrl'] = imageUrl;
      payload['imageUrl'] = imageUrl;
    }

    await _firestore.collection('public_chat').add(payload);
  }

  Future<String> _uploadChatImage({
    required String userId,
    required PlatformFile image,
  }) async {
    final bytes = image.bytes;
    if (bytes == null) {
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
        'chat_media/$userId/${DateTime.now().millisecondsSinceEpoch}_$safeName';
    final ref = (_storage ?? FirebaseStorage.instance).ref(path);

    await ref.putData(
      bytes,
      SettableMetadata(
        contentType: contentType,
        customMetadata: {'uploadedBy': userId},
      ),
    );
    return ref.getDownloadURL();
  }
}
