import 'dart:io';
import 'dart:typed_data';

import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/feature/common/garment_type/domain/entities/garment_type.dart';
import 'package:typed_result/typed_result.dart';

abstract class WardrobeImageStorage {
  /// Uploads [backgroundRemovedPng] in place of [image]'s bytes when given.
  Future<Result<String, Failure>> upload({
    required final File image,
    required final GarmentType garmentType,
    final Uint8List? backgroundRemovedPng,
  });

  Future<Result<void, Failure>> delete(final String path);
}
