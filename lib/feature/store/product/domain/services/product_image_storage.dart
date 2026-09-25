import 'dart:io';

import 'package:tryzeon/core/error/failures.dart';
import 'package:typed_result/typed_result.dart';

abstract class ProductImageStorage {
  Future<Result<List<String>, Failure>> upload({
    required final String storeId,
    required final String productId,
    required final List<File> images,
  });

  Future<Result<void, Failure>> delete({
    required final String storeId,
    required final List<String> paths,
  });
}
