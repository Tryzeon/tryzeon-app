import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tryzeon/feature/common/garment_type/domain/entities/garment_type.dart';

part 'new_wardrobe_item.freezed.dart';

@freezed
sealed class NewWardrobeItem with _$NewWardrobeItem {
  const factory NewWardrobeItem({
    required final String id,
    required final String imagePath,
    required final GarmentType garmentType,
    required final List<String> tags,
  }) = _NewWardrobeItem;
}
