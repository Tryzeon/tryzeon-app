import 'dart:typed_data';

import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_mode.dart';
import 'package:typed_result/typed_result.dart';

abstract class TryonMediaRepository {
  Future<Result<Uint8List, Failure>> loadLocalImageBytes(final String path);

  Future<Result<void, Failure>> share({
    required final String url,
    required final TryonMode mode,
  });
}
