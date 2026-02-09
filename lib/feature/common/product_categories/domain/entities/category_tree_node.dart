import 'package:freezed_annotation/freezed_annotation.dart';
import 'product_category.dart';

part 'category_tree_node.freezed.dart';

/// Represents a node in the category tree structure.
/// Used for hierarchical display of categories (parent -> children).
@freezed
sealed class CategoryTreeNode with _$CategoryTreeNode {
  const factory CategoryTreeNode({
    required final ProductCategory category,
    @Default([]) final List<CategoryTreeNode> children,
  }) = _CategoryTreeNode;
}
