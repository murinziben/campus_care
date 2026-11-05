import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';

import '../core/app_exception.dart';

class UploadedPhoto {
  const UploadedPhoto({required this.url, required this.path});
  final String url;

  /// Storage path, kept so the file can be deleted with the report.
  final String path;
}

abstract class StorageRepository {
  Future<UploadedPhoto> uploadIncidentPhoto({
    required String uid,
    required String incidentId,
    required File file,
  });

  Future<void> deletePhoto(String? path);
}

class FirebaseStorageRepository implements StorageRepository {
  FirebaseStorageRepository({FirebaseStorage? storage})
      : _storage = storage ?? FirebaseStorage.instance;

  final FirebaseStorage _storage;

  @override
  Future<UploadedPhoto> uploadIncidentPhoto({
    required String uid,
    required String incidentId,
    required File file,
  }) async {
    // A unique suffix lets a re-upload (edit flow) coexist with the old file
    // until the report document points at the new one.
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final path = 'incident_photos/$uid/${incidentId}_$stamp.jpg';
    try {
      final ref = _storage.ref(path);
      await ref.putFile(file, SettableMetadata(contentType: 'image/jpeg'));
      final url = await ref.getDownloadURL();
      return UploadedPhoto(url: url, path: path);
    } on FirebaseException catch (e) {
      throw AppException(e.code == 'unauthorized'
          ? 'Photo upload was blocked (file too large or not an image).'
          : 'Photo upload failed. Check your connection and try again.');
    }
  }

  @override
  Future<void> deletePhoto(String? path) async {
    if (path == null || path.isEmpty) return;
    try {
      await _storage.ref(path).delete();
    } on FirebaseException {
      // Best effort: an orphaned image must not block deleting the report.
    }
  }
}
