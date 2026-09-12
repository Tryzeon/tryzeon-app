import 'dart:io';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tryzeon/feature/common/garment_type/domain/entities/garment_type.dart';

part 'wardrobe_item.freezed.dart';

@freezed
sealed class CreateWardrobeItemParams with _$CreateWardrobeItemParams {
  const factory CreateWardrobeItemParams({
    required final File image,
    required final GarmentType garmentType,
    @Default([]) final List<String> tags,
  }) = _CreateWardrobeItemParams;
}

@freezed
sealed class WardrobeItem with _$WardrobeItem {
  const factory WardrobeItem({
    required final String id,
    required final String imagePath,
    required final GarmentType garmentType,
    required final DateTime createdAt,
    required final DateTime updatedAt,
    @Default([]) final List<String> tags,
  }) = _WardrobeItem;
}
