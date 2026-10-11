import 'dart:io';
import 'dart:typed_data';

abstract class ImageFileCache {
  Future<File> saveImage(final Uint8List bytes, final String filePath);

  Future<File?> getImage(final String filePath, {final String? downloadUrl});

  Future<void> deleteImage(final String filePath);

  Future<void> clear();
}
