import 'dart:io';
import 'dart:typed_data';

import 'package:tryzeon/core/error/failures.dart';
import 'package:typed_result/typed_result.dart';

abstract interface class BackgroundRemover {
  Future<Result<Uint8List?, Failure>> remove(final File image);
}
