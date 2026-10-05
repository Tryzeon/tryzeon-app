import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/feature/common/garment_type/domain/entities/garment_type.dart';
import 'package:typed_result/typed_result.dart';

import '../entities/wardrobe_item.dart';
import '../repositories/wardrobe_repository.dart';

part 'update_wardrobe_item.freezed.dart';

/// A null field is left unchanged.
@freezed
sealed class UpdateWardrobeItemParams with _$UpdateWardrobeItemParams {
  const factory UpdateWardrobeItemParams({
    required final String id,
    final GarmentType? garmentType,
    final List<String>? tags,
  }) = _UpdateWardrobeItemParams;
}

class UpdateWardrobeItem {
  UpdateWardrobeItem(this._repository);

  final WardrobeRepository _repository;

  Future<Result<WardrobeItem, Failure>> call(
    final UpdateWardrobeItemParams params,
  ) {
    return _repository.updateWardrobeItem(
      id: params.id,
      garmentType: params.garmentType,
      tags: params.tags,
    );
  }
}
