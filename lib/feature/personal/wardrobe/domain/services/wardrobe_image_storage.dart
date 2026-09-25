import 'dart:io';

import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/feature/common/garment_type/domain/entities/garment_type.dart';
import 'package:typed_result/typed_result.dart';

abstract class WardrobeImageStorage {
  Future<Result<String, Failure>> upload({
    required final File image,
    required final GarmentType garmentType,
  });

  Future<Result<void, Failure>> delete(final String path);
}
