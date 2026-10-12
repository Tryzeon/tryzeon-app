import 'dart:io';
import 'dart:typed_data';

import 'package:tryzeon/core/error/failures.dart';
import 'package:typed_result/typed_result.dart';

abstract class WardrobeImageStorage {
  /// Stores the image under [itemId], uploading [backgroundRemovedPng] in
  /// place of [image]'s bytes when given.
  Future<Result<String, Failure>> upload({
    required final String itemId,
    required final File image,
    final Uint8List? backgroundRemovedPng,
  });

  Future<Result<void, Failure>> delete(final String path);
}
