import '../entities/category_tree_node.dart';
import '../entities/product_category.dart';

/// UseCase that transforms a flat list of categories into a tree structure.
/// Supports 2-level hierarchy (parent -> children).
class BuildCategoryTree {
  /// Builds a tree structure from flat categories.
  /// Returns a list of root nodes (categories with no parent).
  List<CategoryTreeNode> call(final List<ProductCategory> categories) {
    final Map<String, List<ProductCategory>> childrenMap = {};
    final List<ProductCategory> roots = [];

    // Separate roots and children
    for (final category in categories) {
      if (category.parentId == null) {
        roots.add(category);
      } else {
        childrenMap.putIfAbsent(category.parentId!, () => []).add(category);
      }
    }

    // Build tree recursively
    List<CategoryTreeNode> buildNodes(final List<ProductCategory> cats) {
      return cats.map((final cat) {
        final children = childrenMap[cat.id] ?? [];
        return CategoryTreeNode(category: cat, children: buildNodes(children));
      }).toList();
    }

    return buildNodes(roots);
  }
}
