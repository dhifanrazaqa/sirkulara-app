import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String> uploadFile(File file, String path) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      throw FirebaseException(
        plugin: 'firebase_storage',
        code: 'unauthenticated',
        message: 'User must be signed in before uploading files.',
      );
    }
    final ref = _storage.ref().child(path);
    final task = await ref.putFile(file);
    return task.ref.getDownloadURL();
  }

  Future<String> uploadImage(File imageFile, String path) async {
    final bytes = await imageFile.readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      return uploadFile(imageFile, path);
    }

    final shouldResize = decoded.width > 1024 || decoded.height > 1024;
    final resized = shouldResize
        ? img.copyResize(
            decoded,
            width: decoded.width >= decoded.height ? 1024 : null,
            height: decoded.height > decoded.width ? 1024 : null,
          )
        : decoded;
    final compressedBytes = img.encodeJpg(resized, quality: 85);
    final tempDir = await getTemporaryDirectory();
    final tempFile = File('${tempDir.path}/${DateTime.now().microsecondsSinceEpoch}.jpg');
    await tempFile.writeAsBytes(compressedBytes, flush: true);
    try {
      return await uploadFile(tempFile, path);
    } finally {
      if (await tempFile.exists()) {
        await tempFile.delete();
      }
    }
  }

  Future<void> deleteFile(String downloadUrl) async {
    final ref = _storage.refFromURL(downloadUrl);
    await ref.delete();
  }
}
