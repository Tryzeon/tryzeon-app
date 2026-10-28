import 'package:tryzeon/feature/store/product/domain/entities/product.dart';
import 'package:tryzeon/feature/store/product/domain/services/product_color_rules.dart';

class ProductColorUpdate {
  const ProductColorUpdate({required this.original, required this.target});

  final ProductColor original;
  final ProductColor target;
}

class ProductColorDiff {
  const ProductColorDiff({
    required this.toAdd,
    required this.toUpdate,
    required this.idsToDelete,
  });

  const ProductColorDiff.empty()
    : toAdd = const [],
      toUpdate = const [],
      idsToDelete = const [];

  final List<NewProductColor> toAdd;
  final List<ProductColorUpdate> toUpdate;
  final List<String> idsToDelete;

  bool get isEmpty => toAdd.isEmpty && toUpdate.isEmpty && idsToDelete.isEmpty;
}

/// A form colour with every image resolved to its storage path.
sealed class ColorTarget {
  const ColorTarget({this.name, required this.imagePaths});

  final String? name;
  final List<String> imagePaths;
}

class ExistingColorTarget extends ColorTarget {
  const ExistingColorTarget({
    required this.id,
    super.name,
    required super.imagePaths,
  });

  final String id;
}

class NewColorTarget extends ColorTarget {
  const NewColorTarget({super.name, required super.imagePaths});
}

/// An [ExistingColorTarget] whose row is no longer there is skipped rather
/// than re-inserted, as in `computeSizeDiff`.
ProductColorDiff computeColorDiff(
  final List<ProductColor> original,
  final List<ColorTarget> target,
) {
  final originalById = {for (final color in original) color.id: color};

  final toAdd = <NewProductColor>[];
  final toUpdate = <ProductColorUpdate>[];
  final keptIds = <String>{};

  for (final (index, item) in target.indexed) {
    final name = normalizeColorName(item.name);
    switch (item) {
      case NewColorTarget(:final imagePaths):
        toAdd.add(
          NewProductColor(name: name, imagePaths: imagePaths, position: index),
        );
      case ExistingColorTarget(:final id, :final imagePaths):
        final existing = originalById[id];
        if (existing == null) continue;
        keptIds.add(id);
        final updated = existing.copyWith(
          name: name,
          imagePaths: imagePaths,
          position: index,
        );
        if (updated != existing) {
          toUpdate.add(ProductColorUpdate(original: existing, target: updated));
        }
    }
  }

  return ProductColorDiff(
    toAdd: toAdd,
    toUpdate: toUpdate,
    idsToDelete: [
      for (final color in original)
        if (!keptIds.contains(color.id)) color.id,
    ],
  );
}
