import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:supabase_flutter/supabase_flutter.dart';

class PhotoStorageService {
  static const String bucket = 'lecture-photos';
  static const String _prefix = 'sb://$bucket/';

  SupabaseClient get _client => Supabase.instance.client;

  bool isStorageReference(String value) => value.startsWith(_prefix);

  String? objectPathFromReference(String reference) {
    if (!isStorageReference(reference)) return null;
    return reference.substring(_prefix.length);
  }

  String toReference(String objectPath) => '$_prefix$objectPath';

  String toDisplayUrl(String value) {
    final objectPath = objectPathFromReference(value);
    if (objectPath == null) return value;
    return _client.storage.from(bucket).getPublicUrl(objectPath);
  }

  Future<String> uploadLecturePhoto({
    required String lectureId,
    required String localPath,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('You must be logged in to upload photos.');
    }

    final file = File(localPath);
    if (!file.existsSync()) {
      throw Exception('Selected image file was not found on device.');
    }

    final ext = p.extension(localPath).toLowerCase();
    final safeExt = ext.isEmpty ? '.jpg' : ext;
    final fileName = '${DateTime.now().millisecondsSinceEpoch}$safeExt';
    final objectPath = '$userId/$lectureId/$fileName';

    await _client.storage.from(bucket).upload(
          objectPath,
          file,
          fileOptions: const FileOptions(
            upsert: false,
          ),
        );

    return toReference(objectPath);
  }

  Future<void> deleteByReference(String reference) async {
    final objectPath = objectPathFromReference(reference);
    if (objectPath == null) return;

    await _client.storage.from(bucket).remove([objectPath]);
  }
}
