import 'package:tryzeon/feature/store/product/domain/entities/product.dart';
import 'package:tryzeon/feature/store/product/domain/services/product_size_diff.dart';
import 'package:tryzeon/feature/store/product/domain/value_objects/image_item.dart';
import 'package:tryzeon/feature/store/product/domain/value_objects/size_item.dart';

class ProductUpdatePlan {
  const ProductUpdatePlan({
    required this.target,
    required this.removedImagePaths,
    required this.sizeDiff,
    required this.hasProductChanges,
  });

  final Product target;
  final List<String> removedImagePaths;
  final ProductSizeDiff sizeDiff;
  final bool hasProductChanges;

  bool get isEmpty => !hasProductChanges && sizeDiff.isEmpty;
}

ProductUpdatePlan planProductUpdate({
  required final Product original,
  required final ProductDraft draft,
  required final List<ImageItem> images,
  required final List<String> uploadedPaths,
  required final List<SizeItem> sizes,
}) {
  final newImageCount = images.whereType<NewImageItem>().length;
  if (newImageCount != uploadedPaths.length) {
    throw ArgumentError.value(
      uploadedPaths,
      'uploadedPaths',
      'expected $newImageCount paths, one per new image',
    );
  }

  var uploadIndex = 0;
  final imagePaths = [
    for (final item in images)
      switch (item) {
        ExistingImageItem(:final path) => path,
        NewImageItem() => uploadedPaths[uploadIndex++],
      },
  ];

  final target = original.applyDraft(draft).copyWith(imagePaths: imagePaths);

  return ProductUpdatePlan(
    target: target,
    removedImagePaths: original.imagePaths
        .where((final path) => !imagePaths.contains(path))
        .toList(),
    sizeDiff: computeSizeDiff(original.sizes, sizes),
    hasProductChanges: target != original,
  );
}
