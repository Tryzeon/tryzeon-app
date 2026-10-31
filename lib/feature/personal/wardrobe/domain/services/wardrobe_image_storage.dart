import 'dart:io';

import 'package:tryzeon/core/error/failures.dart';
import 'package:typed_result/typed_result.dart';

abstract class WardrobeImageStorage {
  Future<Result<String, Failure>> upload({
    required final String itemId,
    required final File image,
  });

  Future<Result<void, Failure>> delete(final String path);
}
