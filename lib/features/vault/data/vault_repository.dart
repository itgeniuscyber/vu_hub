import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'vault_resource.dart';

class VaultRepository {
  VaultRepository({FirebaseFirestore? firestore, FirebaseStorage? storage})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _storage = storage;

  final FirebaseFirestore _firestore;
  final FirebaseStorage? _storage;

  Stream<List<VaultResource>> watchPastPapers() {
    return _firestore.collection('past_papers').limit(60).snapshots().map((
      snapshot,
    ) {
      final resources = snapshot.docs.map(VaultResource.fromPastPaper).toList();
      resources.sort((a, b) {
        final left = a.uploadedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final right = b.uploadedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return right.compareTo(left);
      });
      return resources;
    });
  }

  Future<void> uploadPastPaper({
    required String title,
    required String faculty,
    required String uploadedBy,
    required String uploaderId,
    required String fileType,
    required String fileName,
    Uint8List? fileBytes,
    String? externalFileUrl,
    String? thumbnailUrl,
    Uint8List? thumbnailBytes,
    String? thumbnailFileName,
  }) async {
    var resolvedFileUrl = externalFileUrl?.trim() ?? '';
    if (resolvedFileUrl.isEmpty) {
      if (fileBytes == null) {
        throw ArgumentError(
          'Select a file or provide an external resource URL.',
        );
      }
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final safeName = fileName.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
      final ref = (_storage ?? FirebaseStorage.instance).ref(
        'past_papers/$uploaderId/$timestamp-$safeName',
      );
      final metadata = SettableMetadata(
        contentType: 'application/${fileType.toLowerCase()}',
      );
      final task = await ref.putData(fileBytes, metadata);
      resolvedFileUrl = await task.ref.getDownloadURL();
    }

    var resolvedThumbnailUrl = thumbnailUrl?.trim();
    if ((resolvedThumbnailUrl == null || resolvedThumbnailUrl.isEmpty) &&
        thumbnailBytes != null &&
        thumbnailBytes.isNotEmpty) {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final safeName = (thumbnailFileName ?? 'thumbnail.png').replaceAll(
        RegExp(r'[^A-Za-z0-9._-]'),
        '_',
      );
      final ref = (_storage ?? FirebaseStorage.instance).ref(
        'resources/$uploaderId/thumbnails/$timestamp-$safeName',
      );
      final task = await ref.putData(
        thumbnailBytes,
        SettableMetadata(contentType: 'image/*'),
      );
      resolvedThumbnailUrl = await task.ref.getDownloadURL();
    }

    await _firestore.collection('past_papers').add({
      'subject': title.trim(),
      'title': title.trim(),
      'faculty': faculty.trim(),
      'fileType': fileType.trim().toLowerCase(),
      'fileUrl': resolvedFileUrl,
      'thumbnailUrl': resolvedThumbnailUrl,
      'uploadedBy': uploadedBy.trim().isEmpty ? 'VU Staff' : uploadedBy.trim(),
      'uploadedById': uploaderId,
      'uploadedAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
      'timestamp': FieldValue.serverTimestamp(),
    });
  }
}
