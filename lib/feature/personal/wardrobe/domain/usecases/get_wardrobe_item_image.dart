import 'dart:io';
import 'package:tryzeon/core/error/failures.dart';
import 'package:typed_result/typed_result.dart';
import '../repositories/wardrobe_repository.dart';

class GetWardrobeItemImage {
  GetWardrobeItemImage(this._repository);
  final WardrobeRepository _repository;

  Future<Result<File, Failure>> call(final String imagePath) =>
      _repository.getWardrobeItemImage(imagePath);
}
