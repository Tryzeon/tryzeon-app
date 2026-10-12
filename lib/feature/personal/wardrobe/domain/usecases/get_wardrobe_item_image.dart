import 'dart:io';

import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/feature/personal/wardrobe/domain/repositories/wardrobe_repository.dart';
import 'package:typed_result/typed_result.dart';

class GetWardrobeItemImage {
  GetWardrobeItemImage(this._repository);
  final WardrobeRepository _repository;

  Future<Result<File, Failure>> call(final String imagePath) =>
      _repository.getWardrobeItemImage(imagePath);
}
