import 'package:flutter/material.dart';
import 'package:tryzeon/feature/common/product_color/domain/entities/product_color.dart';
import 'package:tryzeon/feature/store/product/domain/value_objects/color_item.dart';
import 'package:tryzeon/feature/store/product/domain/value_objects/image_item.dart';

enum ColorNameSuggestion { none, pending, unavailable }

class ProductColorEntryController {
  ProductColorEntryController({
    this.id,
    final String? name,
    final List<ImageItem> images = const [],
  }) : nameController = TextEditingController(text: name),
       images = ValueNotifier<List<ImageItem>>(images),
       _photoSet = images.isEmpty ? null : Object() {
    analysedPhotoSet = _photoSet;
    this.images.addListener(_trackPhotoSet);
  }

  factory ProductColorEntryController.fromProductColor(
    final ProductColor color,
  ) {
    return ProductColorEntryController(
      id: color.id,
      name: color.name,
      images: [
        for (var i = 0; i < color.imagePaths.length; i++)
          ImageItem.existing(
            path: color.imagePaths[i],
            url: color.imageUrls[i],
          ),
      ],
    );
  }

  final String? id;
  final GlobalKey key = GlobalKey();
  final TextEditingController nameController;
  final ValueNotifier<List<ImageItem>> images;
  final ValueNotifier<ColorNameSuggestion> nameSuggestion = ValueNotifier(
    ColorNameSuggestion.none,
  );
  String? _suggestedName;

  /// Lasts from a colour's first photo until its last one is removed, so it
  /// is analysed once per set of photos, not on every reorder. Photos the
  /// colour starts with were never picked on this page and count as analysed.
  Object? _photoSet;
  Object? analysedPhotoSet;

  Object? get photoSet => _photoSet;

  bool _isDisposed = false;
  bool get isDisposed => _isDisposed;

  void _trackPhotoSet() {
    if (images.value.isEmpty) {
      _photoSet = null;
      nameSuggestion.value = ColorNameSuggestion.none;
    } else {
      _photoSet ??= Object();
    }
  }

  bool get acceptsSuggestedName {
    final name = nameController.text.trim();
    return name.isEmpty || name == _suggestedName;
  }

  bool get showsSuggestedName =>
      images.value.isNotEmpty &&
      _suggestedName != null &&
      nameController.text.trim() == _suggestedName;

  void suggestName(final String name) {
    if (!acceptsSuggestedName) return;
    _suggestedName = name;
    nameController.text = name;
  }

  ColorItem toColorItem() {
    final colorId = id;
    if (colorId == null) {
      return ColorItem.newColor(
        name: nameController.text,
        images: [
          for (final image in images.value)
            if (image is NewImageItem) image.file,
        ],
      );
    }
    return ColorItem.existing(
      id: colorId,
      name: nameController.text,
      images: images.value,
    );
  }

  void dispose() {
    _isDisposed = true;
    nameController.dispose();
    images.dispose();
    nameSuggestion.dispose();
  }
}
