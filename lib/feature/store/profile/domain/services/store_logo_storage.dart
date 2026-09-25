import 'dart:io';

import 'package:tryzeon/core/error/failures.dart';
import 'package:typed_result/typed_result.dart';

abstract class StoreLogoStorage {
  Future<Result<String, Failure>> upload({
    required final String storeId,
    required final File logo,
  });

  Future<Result<void, Failure>> delete({
    required final String storeId,
    required final String path,
  });
}
