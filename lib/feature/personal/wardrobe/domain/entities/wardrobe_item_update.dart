import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tryzeon/feature/common/garment_type/domain/entities/garment_type.dart';

part 'wardrobe_item_update.freezed.dart';

/// A null field is left unchanged.
@freezed
sealed class WardrobeItemUpdate with _$WardrobeItemUpdate {
  const factory WardrobeItemUpdate({
    final GarmentType? garmentType,
    final List<String>? tags,
  }) = _WardrobeItemUpdate;
}
