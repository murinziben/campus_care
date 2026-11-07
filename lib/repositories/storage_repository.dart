import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../core/app_exception.dart';
import '../core/cloudinary_config.dart';

class UploadedPhoto {
  const UploadedPhoto({required this.url, required this.path});

  /// Public HTTPS address saved in the incident document.
  final String url;

  /// Provider-side identifier (Cloudinary public_id).
  final String path;
}

/// Photo storage abstraction. The app uses Cloudinary in production and an
/// in-memory fake in tests, so the rest of the code never knows which.
abstract class StorageRepository {
  Future<UploadedPhoto> uploadIncidentPhoto({
    required String uid,
    required String incidentId,
    required File file,
  });

  Future<void> deletePhoto(String? path);
}

/// Uploads photos to Cloudinary with an unsigned upload preset.
class CloudinaryStorageRepository implements StorageRepository {
  CloudinaryStorageRepository({http.Client? client})
      : _client = client ?? http.Client();

  final http.Client _client;

  @override
  Future<UploadedPhoto> uploadIncidentPhoto({
    required String uid,
    required String incidentId,
    required File file,
  }) async {
    if (!CloudinaryConfig.isConfigured) {
      throw const AppException(
          'Photo storage is not set up yet. Add your Cloudinary details in '
          'lib/core/cloudinary_config.dart.');
    }

    // A unique suffix lets a re-upload (edit flow) coexist with the old file
    // until the report document points at the new one.
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final uri = Uri.parse(
        'https://api.cloudinary.com/v1_1/${CloudinaryConfig.cloudName}/image/upload');

    final bytes = await file.length();
    debugPrint('Cloudinary: uploading ${(bytes / 1024).round()} KB');

    // Mobile connections can stall, so allow two attempts of 90 s each.
    Object? lastError;
    for (var attempt = 1; attempt <= 2; attempt++) {
      final watch = Stopwatch()..start();
      try {
        final request = http.MultipartRequest('POST', uri)
          ..fields['upload_preset'] = CloudinaryConfig.uploadPreset
          ..fields['public_id'] = '${uid}_${incidentId}_$stamp'
          ..files.add(await http.MultipartFile.fromPath('file', file.path));

        final response = await http.Response.fromStream(
            await _client.send(request).timeout(const Duration(seconds: 90)));

        if (response.statusCode != 200) {
          // Cloudinary explains the problem, e.g. "Unknown API key" (wrong
          // cloud name) or "Upload preset not found" (wrong preset name).
          var reason = 'HTTP ${response.statusCode}';
          try {
            final body = jsonDecode(response.body) as Map<String, dynamic>;
            reason = (body['error'] as Map<String, dynamic>)['message']
                .toString();
          } catch (_) {}
          debugPrint('Cloudinary rejected the upload: $reason');
          throw AppException('Photo upload was rejected: $reason');
        }
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        debugPrint('Cloudinary: done in ${watch.elapsedMilliseconds} ms');
        return UploadedPhoto(
          url: json['secure_url'] as String,
          path: json['public_id'] as String,
        );
      } on AppException {
        rethrow;
      } catch (e) {
        lastError = e;
        debugPrint('Cloudinary attempt $attempt failed after '
            '${watch.elapsedMilliseconds} ms: $e');
      }
    }
    throw AppException('Photo upload failed (${lastError.runtimeType}). '
        'The connection to the photo service is slow. Try again, or switch '
        'between Wi-Fi and mobile data.');
  }

  /// Unsigned uploads cannot be deleted from the app (that needs the API
  /// secret, which must never ship in a mobile app). Orphaned images are
  /// harmless and can be cleaned from the Cloudinary dashboard.
  @override
  Future<void> deletePhoto(String? path) async {}
}
