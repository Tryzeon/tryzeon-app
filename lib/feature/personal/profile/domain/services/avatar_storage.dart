import 'dart:io';

import 'package:tryzeon/core/error/failures.dart';
import 'package:typed_result/typed_result.dart';

abstract class AvatarStorage {
  Future<Result<String, Failure>> upload(final File image);

  Future<Result<void, Failure>> delete(final String path);
}
