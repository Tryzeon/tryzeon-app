import 'package:freezed_annotation/freezed_annotation.dart';
import 'wardrobe_category.dart';

part 'wardrobe_item.freezed.dart';

/// Domain entity representing a wardrobe item
/// Uses WardrobeCategory enum for type safety and business logic
@freezed
sealed class WardrobeItem with _$WardrobeItem {
  const factory WardrobeItem({
    required final String id,
    required final String imagePath,
    required final WardrobeCategory category,
    @Default([]) final List<String> tags,
  }) = _WardrobeItem;
}
