import 'dart:io';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tryzeon/feature/store/product/domain/value_objects/image_item.dart';

part 'color_item.freezed.dart';

@freezed
sealed class ColorItem with _$ColorItem {
  const factory ColorItem.existing({
    required final String id,
    required final List<ImageItem> images,
    final String? name,
  }) = ExistingColorItem;

  const factory ColorItem.newColor({
    required final List<File> images,
    final String? name,
  }) = NewColorItem;
}

extension ColorItemsUploads on List<ColorItem> {
  List<File> get newImageFiles => [
    for (final color in this)
      ...switch (color) {
        ExistingColorItem(:final images) => [
          for (final image in images)
            if (image is NewImageItem) image.file,
        ],
        NewColorItem(:final images) => images,
      },
  ];
}
