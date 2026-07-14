import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';

import 'campus_event.dart';
import 'live_post.dart';

class LiveUploadCancelToken {
  bool _isCancelled = false;

  bool get isCancelled => _isCancelled;

  void cancel() => _isCancelled = true;
}

class CameraLiveRoom {
  const CameraLiveRoom({required this.postId, required this.roomId});

  final String postId;
  final String roomId;
}

class LivePostsRepository {
  LivePostsRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    FirebaseStorage? storage,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth,
       _storage = storage;

  final FirebaseFirestore _firestore;
  final FirebaseAuth? _auth;
  final FirebaseStorage? _storage;

  Stream<List<LivePost>> watchFeed() {
    return _firestore
        .collection('live_posts')
        .orderBy('createdAt', descending: true)
        .limit(80)
        .snapshots()
        .asyncMap((snapshot) async {
          final livePosts = snapshot.docs.map(LivePost.fromDoc).toList();

          final events = await _firestore.collection('events').limit(40).get();
          final fallback = events.docs
              .map((doc) => LivePost.fromEvent(CampusEvent.fromDoc(doc)))
              .toList();
          final feed = [...livePosts, ...fallback];
          feed.sort(
            (a, b) => (b.startedAt ?? b.createdAt ?? DateTime(1970)).compareTo(
              a.startedAt ?? a.createdAt ?? DateTime(1970),
            ),
          );
          return feed;
        });
  }

  Future<void> createExternalLive({
    required String title,
    required String description,
    required String playbackUrl,
    required String category,
    required String location,
    required String hostName,
    String coverUrl = '',
  }) async {
    final user = _requireUser();
    await _firestore.collection('live_posts').add({
      'type': 'live',
      'status': 'live',
      'title': title.trim(),
      'description': description.trim(),
      'playbackUrl': playbackUrl.trim(),
      'category': category.trim().isEmpty ? 'Campus Live' : category.trim(),
      'location': location.trim().isEmpty
          ? 'Victoria University'
          : location.trim(),
      'hostId': user.uid,
      'hostName': hostName.trim().isEmpty
          ? user.displayName ?? 'VU Host'
          : hostName.trim(),
      'coverUrl': coverUrl.trim(),
      'provider': 'external_link',
      'viewerCount': 1,
      'playCount': 0,
      'likeCount': 0,
      'giftCount': 0,
      'commentCount': 0,
      'startedAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<String> createCameraLiveDraft({
    required String title,
    required String description,
    required String category,
    required String location,
    required String hostName,
  }) async {
    final user = _requireUser();
    final doc = await _firestore.collection('live_posts').add({
      'type': 'live',
      'status': 'scheduled',
      'title': title.trim(),
      'description': description.trim(),
      'category': category.trim().isEmpty ? 'Campus Live' : category.trim(),
      'location': location.trim().isEmpty
          ? 'Victoria University'
          : location.trim(),
      'hostId': user.uid,
      'hostName': hostName.trim().isEmpty
          ? user.displayName ?? 'VU Host'
          : hostName.trim(),
      'provider': 'camera_provider_pending',
      'providerRoomId': '',
      'viewerCount': 0,
      'playCount': 0,
      'likeCount': 0,
      'giftCount': 0,
      'commentCount': 0,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  Future<CameraLiveRoom> createZegoCameraLive({
    required String title,
    required String description,
    required String category,
    required String location,
    required String hostName,
  }) async {
    final user = _requireUser();
    final doc = _firestore.collection('live_posts').doc();
    final roomId = _safeRoomId('vu_live_${doc.id}');
    await doc.set({
      'type': 'live',
      'status': 'live',
      'title': title.trim(),
      'description': description.trim(),
      'category': category.trim().isEmpty ? 'Campus Live' : category.trim(),
      'location': location.trim().isEmpty
          ? 'Victoria University'
          : location.trim(),
      'hostId': user.uid,
      'hostName': hostName.trim().isEmpty
          ? user.displayName ?? 'VU Host'
          : hostName.trim(),
      'provider': 'zego_uikit',
      'providerRoomId': roomId,
      'viewerCount': 0,
      'playCount': 0,
      'likeCount': 0,
      'giftCount': 0,
      'commentCount': 0,
      'startedAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    });
    return CameraLiveRoom(postId: doc.id, roomId: roomId);
  }

  Future<void> endLiveRoom(String postId) async {
    if (postId.startsWith('event_')) return;
    final user = _requireUser();
    final postRef = _firestore.collection('live_posts').doc(postId);
    final snapshot = await postRef.get();
    if (!snapshot.exists) return;
    final data = snapshot.data() ?? {};
    if (data['hostId'] != user.uid) return;
    await postRef.update({
      'status': 'ended',
      'endedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> createShortVideo({
    required String title,
    required String description,
    required String category,
    required String location,
    required String hostName,
    required PlatformFile video,
    PlatformFile? cover,
    void Function(double progress)? onProgress,
    void Function(String status)? onStatus,
    LiveUploadCancelToken? cancelToken,
  }) async {
    final user = _requireUser();
    onStatus?.call('Uploading video...');
    final videoUrl = await _uploadMedia(
      userId: user.uid,
      file: video,
      folder: 'videos',
      contentTypeFallback: 'video/mp4',
      onProgress: (progress) => onProgress?.call(progress * 0.9),
      onStatus: onStatus,
      cancelToken: cancelToken,
    );
    _throwIfCancelled(cancelToken);
    onStatus?.call(cover == null ? 'Saving post...' : 'Uploading cover...');
    final coverUrl = cover == null
        ? ''
        : await _uploadMedia(
            userId: user.uid,
            file: cover,
            folder: 'covers',
            contentTypeFallback: 'image/jpeg',
            onProgress: (progress) => onProgress?.call(0.9 + progress * 0.1),
            onStatus: onStatus,
            cancelToken: cancelToken,
          );
    _throwIfCancelled(cancelToken);
    onProgress?.call(1);
    onStatus?.call('Publishing post...');

    await _firestore
        .collection('live_posts')
        .add({
          'type': 'short_video',
          'status': 'published',
          'title': title.trim(),
          'description': description.trim(),
          'category': category.trim().isEmpty ? 'Campus' : category.trim(),
          'location': location.trim().isEmpty
              ? 'Victoria University'
              : location.trim(),
          'hostId': user.uid,
          'hostName': hostName.trim().isEmpty
              ? user.displayName ?? 'VU Creator'
              : hostName.trim(),
          'videoUrl': videoUrl,
          'coverUrl': coverUrl,
          'provider': 'firebase_storage',
          'viewerCount': 0,
          'playCount': 0,
          'likeCount': 0,
          'giftCount': 0,
          'commentCount': 0,
          'createdAt': FieldValue.serverTimestamp(),
        })
        .timeout(
          const Duration(seconds: 30),
          onTimeout: () => throw TimeoutException(
            'The video uploaded, but saving the post took too long. Please check your connection and try again.',
          ),
        );
  }

  Future<void> recordView(String postId) async {
    if (postId.startsWith('event_')) return;
    final user = (_auth ?? FirebaseAuth.instance).currentUser;
    if (user == null) return;

    final postRef = _firestore.collection('live_posts').doc(postId);
    final viewRef = postRef.collection('views').doc(user.uid);
    await _firestore.runTransaction((transaction) async {
      final viewSnapshot = await transaction.get(viewRef);
      if (viewSnapshot.exists) {
        transaction.update(viewRef, {
          'lastViewedAt': FieldValue.serverTimestamp(),
          'playCount': FieldValue.increment(1),
        });
        transaction.update(postRef, {'playCount': FieldValue.increment(1)});
        return;
      }

      transaction.set(viewRef, {
        'userId': user.uid,
        'displayName': user.displayName ?? '',
        'firstViewedAt': FieldValue.serverTimestamp(),
        'lastViewedAt': FieldValue.serverTimestamp(),
        'playCount': 1,
      });
      transaction.update(postRef, {
        'viewerCount': FieldValue.increment(1),
        'playCount': FieldValue.increment(1),
      });
    });
  }

  Future<void> like(String postId) async {
    if (postId.startsWith('event_')) return;
    await _firestore.collection('live_posts').doc(postId).update({
      'likeCount': FieldValue.increment(1),
    });
  }

  Future<void> sendComment({
    required String postId,
    required String text,
    required String displayName,
  }) async {
    if (text.trim().isEmpty || postId.startsWith('event_')) return;
    final user = _requireUser();
    final postRef = _firestore.collection('live_posts').doc(postId);
    await postRef.collection('comments').add({
      'text': text.trim(),
      'userId': user.uid,
      'displayName': displayName,
      'createdAt': FieldValue.serverTimestamp(),
    });
    await postRef.update({'commentCount': FieldValue.increment(1)});
  }

  Future<void> sendGift({
    required String postId,
    required String gift,
    required int value,
    required String displayName,
  }) async {
    if (postId.startsWith('event_')) return;
    final user = _requireUser();
    final postRef = _firestore.collection('live_posts').doc(postId);
    await postRef.collection('gifts').add({
      'gift': gift,
      'value': value,
      'userId': user.uid,
      'displayName': displayName,
      'createdAt': FieldValue.serverTimestamp(),
    });
    await postRef.update({'giftCount': FieldValue.increment(value)});
  }

  User _requireUser() {
    final user = (_auth ?? FirebaseAuth.instance).currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'not-signed-in',
        message: 'Please sign in before using VU Live.',
      );
    }
    return user;
  }

  Future<String> _uploadMedia({
    required String userId,
    required PlatformFile file,
    required String folder,
    required String contentTypeFallback,
    void Function(double progress)? onProgress,
    void Function(String status)? onStatus,
    LiveUploadCancelToken? cancelToken,
  }) async {
    if (file.path == null && file.bytes == null) {
      throw StateError('The selected file could not be read.');
    }
    _throwIfCancelled(cancelToken);
    final safeName = file.name
        .replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_')
        .toLowerCase();
    final path =
        'live_posts/$userId/$folder/${DateTime.now().millisecondsSinceEpoch}_$safeName';
    final contentType = _contentTypeFor(file, contentTypeFallback);
    final ref = (_storage ?? FirebaseStorage.instance).ref(path);
    final metadata = SettableMetadata(contentType: contentType);
    final task = file.path == null
        ? ref.putData(file.bytes!, metadata)
        : ref.putFile(File(file.path!), metadata);
    var lastBytesTransferred = 0;
    var cancelledByStall = false;
    Timer? stallTimer;

    void resetStallTimer() {
      stallTimer?.cancel();
      stallTimer = Timer(const Duration(seconds: 90), () async {
        cancelledByStall = true;
        onStatus?.call('Upload stalled. Cancelling...');
        await task.cancel();
      });
    }

    resetStallTimer();
    final subscription = task.snapshotEvents.listen((snapshot) {
      if (cancelToken?.isCancelled ?? false) {
        task.cancel();
        return;
      }
      final total = snapshot.totalBytes;
      if (snapshot.bytesTransferred > lastBytesTransferred) {
        lastBytesTransferred = snapshot.bytesTransferred;
        resetStallTimer();
      }
      if (total <= 0) {
        onStatus?.call('Uploading...');
        return;
      }
      final progress = snapshot.bytesTransferred / total;
      onProgress?.call(progress);
      onStatus?.call(
        'Uploading ${_formatBytes(snapshot.bytesTransferred)} of ${_formatBytes(total)}',
      );
    });
    try {
      await task
          .whenComplete(() {})
          .timeout(
            const Duration(minutes: 15),
            onTimeout: () async {
              await task.cancel();
              throw TimeoutException(
                'The upload took too long. Try a shorter MP4 video or a stronger network.',
              );
            },
          );
      _throwIfCancelled(cancelToken);
      onStatus?.call('Preparing playback link...');
      return await ref.getDownloadURL().timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw TimeoutException(
          'The upload finished, but Firebase did not return the playback link in time.',
        ),
      );
    } on FirebaseException catch (error) {
      if (cancelToken?.isCancelled ?? false) {
        throw StateError('Upload cancelled.');
      }
      if (cancelledByStall || error.code == 'canceled') {
        throw TimeoutException(
          'The upload stalled. Please try a smaller MP4 video or check the network.',
        );
      }
      rethrow;
    } finally {
      stallTimer?.cancel();
      await subscription.cancel();
    }
  }

  void _throwIfCancelled(LiveUploadCancelToken? token) {
    if (token?.isCancelled ?? false) {
      throw StateError('Upload cancelled.');
    }
  }

  String _formatBytes(int bytes) {
    if (bytes >= 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    if (bytes >= 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '$bytes B';
  }

  String _safeRoomId(String value) {
    final safe = value
        .replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_')
        .replaceAll(RegExp(r'_+'), '_');
    return safe.isEmpty
        ? 'vu_live_${DateTime.now().millisecondsSinceEpoch}'
        : safe;
  }

  String _contentTypeFor(PlatformFile file, String fallback) {
    final extension = file.extension?.toLowerCase();
    return switch (extension) {
      'mp4' => 'video/mp4',
      'mov' => 'video/quicktime',
      'webm' => 'video/webm',
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'webp' => 'image/webp',
      _ => fallback,
    };
  }
}
