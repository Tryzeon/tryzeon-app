import 'package:tryzeon/feature/store/product/domain/entities/product.dart';
import 'package:tryzeon/feature/store/product/domain/services/product_color_diff.dart';
import 'package:tryzeon/feature/store/product/domain/services/product_size_diff.dart';
import 'package:tryzeon/feature/store/product/domain/value_objects/color_item.dart';
import 'package:tryzeon/feature/store/product/domain/value_objects/image_item.dart';
import 'package:tryzeon/feature/store/product/domain/value_objects/size_item.dart';

class ProductUpdatePlan {
  const ProductUpdatePlan({
    required this.target,
    required this.removedImagePaths,
    required this.sizeDiff,
    required this.colorDiff,
    required this.hasProductChanges,
  });

  final Product target;
  final List<String> removedImagePaths;
  final ProductSizeDiff sizeDiff;
  final ProductColorDiff colorDiff;
  final bool hasProductChanges;

  bool get isEmpty =>
      !hasProductChanges && sizeDiff.isEmpty && colorDiff.isEmpty;
}

ProductUpdatePlan planProductUpdate({
  required final Product original,
  required final ProductDraft draft,
  required final List<ColorItem> colors,
  required final List<String> uploadedPaths,
  required final List<SizeItem> sizes,
}) {
  final newImageCount = colors.newImageFiles.length;
  if (newImageCount != uploadedPaths.length) {
    throw ArgumentError.value(
      uploadedPaths,
      'uploadedPaths',
      'expected $newImageCount paths, one per new image',
    );
  }

  final colorDiff = computeColorDiff(
    original.colors,
    _resolveUploads(colors, uploadedPaths),
  );
  final target = original.applyDraft(draft);

  return ProductUpdatePlan(
    target: target,
    removedImagePaths: _releasedPaths(original, colorDiff, uploadedPaths),
    sizeDiff: computeSizeDiff(original.sizes, sizes),
    colorDiff: colorDiff,
    hasProductChanges: target != original,
  );
}

List<ColorTarget> _resolveUploads(
  final List<ColorItem> colors,
  final List<String> uploadedPaths,
) {
  var uploadIndex = 0;
  return [
    for (final item in colors)
      switch (item) {
        NewColorItem(:final name, :final images) => NewColorTarget(
          name: name,
          imagePaths: [for (final _ in images) uploadedPaths[uploadIndex++]],
        ),
        ExistingColorItem(:final id, :final name, :final images) =>
          ExistingColorTarget(
            id: id,
            name: name,
            imagePaths: [
              for (final image in images)
                switch (image) {
                  ExistingImageItem(:final path) => path,
                  NewImageItem() => uploadedPaths[uploadIndex++],
                },
            ],
          ),
      },
  ];
}

/// Every stored path the saved colours no longer reference: whole deleted
/// colours, images dropped from a kept colour, and uploads that landed in no
/// colour (a stale colour the diff skipped).
List<String> _releasedPaths(
  final Product original,
  final ProductColorDiff diff,
  final List<String> uploadedPaths,
) {
  final deleted = diff.idsToDelete.toSet();
  final referenced = {
    for (final color in diff.toAdd) ...color.imagePaths,
    for (final update in diff.toUpdate) ...update.target.imagePaths,
  };
  return [
    for (final color in original.colors)
      if (deleted.contains(color.id)) ...color.imagePaths,
    for (final update in diff.toUpdate)
      for (final path in update.original.imagePaths)
        if (!update.target.imagePaths.contains(path)) path,
    for (final path in uploadedPaths)
      if (!referenced.contains(path)) path,
  ];
}
