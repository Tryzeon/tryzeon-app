import '../../domain/entities/wardrobe_category.dart';

/// UI layer extension for displaying WardrobeCategory in Chinese.
/// This is the ONLY place where Chinese translations should exist.
extension CategoryDisplay on WardrobeCategory {
  /// Get the Chinese display name for UI.
  String get displayName => switch (this) {
    WardrobeCategory.top => '上衣',
    WardrobeCategory.pants => '褲子',
    WardrobeCategory.skirt => '裙子',
    WardrobeCategory.jacket => '外套',
    WardrobeCategory.shoes => '鞋子',
    WardrobeCategory.accessories => '配件',
    WardrobeCategory.others => '其他',
  };

  /// Get all categories with their display names
  static List<MapEntry<WardrobeCategory, String>> get allWithDisplayNames {
    return WardrobeCategory.values
        .map((final category) => MapEntry(category, category.displayName))
        .toList();
  }
}
