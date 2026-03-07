import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:tryzeon/feature/common/product_categories/domain/entities/category_tree_node.dart';
import 'package:tryzeon/feature/common/product_categories/domain/entities/product_category.dart';

class ProductCategorySelector extends HookWidget {
  const ProductCategorySelector({
    super.key,
    required this.categoryTree,
    required this.selectedCategoryId,
    this.onChanged,
  });

  final List<CategoryTreeNode> categoryTree;
  final ValueNotifier<String?> selectedCategoryId;
  final ValueChanged<String?>? onChanged;

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final selectedIdNotifier = useListenable(selectedCategoryId);
    final selectedId = selectedIdNotifier.value;

    // Flatten tree into a map for quick access
    final categoryMap = useMemoized(() {
      final map = <String, String>{};
      void visit(final List<CategoryTreeNode> nodes) {
        for (final node in nodes) {
          map[node.category.id] = node.category.name;
          visit(node.children);
        }
      }

      visit(categoryTree);
      return map;
    }, [categoryTree]);

    final allCategories = useMemoized(() {
      final list = <ProductCategory>[];
      void visit(final List<CategoryTreeNode> nodes) {
        for (final node in nodes) {
          list.add(node.category);
          visit(node.children);
        }
      }

      visit(categoryTree);
      return list;
    }, [categoryTree]);

    String getCategoryNameById(final String id) {
      return categoryMap[id] ?? id;
    }

    void showSelectionSheet() {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (final context) => _HierarchicalSelectionSheet(
          categoryTree: categoryTree,
          allCategories: allCategories,
          selectedId: selectedId,
          onSelectionChanged: (final id) {
            if (onChanged != null) {
              onChanged!(id);
            } else {
              selectedCategoryId.value = id;
            }
          },
        ),
      );
    }

    return GestureDetector(
      onTap: showSelectionSheet,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colorScheme.outline.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Expanded(
              child: selectedId == null || selectedId.isEmpty
                  ? Text(
                      '選擇商品分類',
                      style: textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                      ),
                    )
                  : Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      child: Text(
                        getCategoryNameById(selectedId),
                        style: textTheme.labelMedium?.copyWith(
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.keyboard_arrow_down_rounded, color: colorScheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

class _HierarchicalSelectionSheet extends HookWidget {
  const _HierarchicalSelectionSheet({
    required this.categoryTree,
    required this.allCategories,
    required this.selectedId,
    required this.onSelectionChanged,
  });

  final List<CategoryTreeNode> categoryTree;
  final List<ProductCategory> allCategories;
  final String? selectedId;
  final ValueChanged<String?> onSelectionChanged;

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final currentSelection = useState<String?>(selectedId);
    final expandedParents = useState<Set<String>>({});
    final searchController = useTextEditingController();
    useListenable(searchController);

    void toggleSelection(final String id) {
      if (currentSelection.value == id) {
        currentSelection.value = null;
      } else {
        currentSelection.value = id;
      }
    }

    void toggleExpand(final String parentId) {
      final newSet = {...expandedParents.value};
      if (newSet.contains(parentId)) {
        newSet.remove(parentId);
      } else {
        newSet.add(parentId);
      }
      expandedParents.value = newSet;
    }

    void saveAndClose() {
      onSelectionChanged(currentSelection.value);
      Navigator.pop(context);
    }

    final searchQuery = searchController.text.trim().toLowerCase();
    final isSearching = searchQuery.isNotEmpty;

    List<CategoryTreeNode> filterTree(
      final List<CategoryTreeNode> nodes,
      final String query,
    ) {
      if (query.isEmpty) return nodes;

      final filtered = <CategoryTreeNode>[];
      for (final node in nodes) {
        final matchesNode = node.category.name.toLowerCase().contains(query);
        final matchingChildren = filterTree(node.children, query);

        if (matchesNode || matchingChildren.isNotEmpty) {
          filtered.add(node.copyWith(children: matchingChildren));
        }
      }
      return filtered;
    }

    final displayTree = useMemoized(() => filterTree(categoryTree, searchQuery), [
      categoryTree,
      searchQuery,
    ]);

    // Auto-expand all parents when searching
    useEffect(() {
      if (isSearching) {
        final allParentIds = <String>{};
        void collectIds(final List<CategoryTreeNode> nodes) {
          for (final node in nodes) {
            if (node.children.isNotEmpty) {
              allParentIds.add(node.category.id);
              collectIds(node.children);
            }
          }
        }

        collectIds(displayTree);
        expandedParents.value = {...expandedParents.value, ...allParentIds};
      }
      return null;
    }, [displayTree, isSearching]);

    Widget buildCategoryTile(
      final ProductCategory category, {
      final int level = 0,
      final bool hasChildren = false,
      final bool isExpanded = false,
      final VoidCallback? onExpand,
    }) {
      final isSelected = currentSelection.value == category.id;
      final isSelectable = !hasChildren; // Only leaf nodes are selectable

      return InkWell(
        onTap: isSelectable
            ? () => toggleSelection(category.id)
            : (hasChildren ? onExpand : null),
        child: Container(
          padding: EdgeInsets.only(
            left: 24.0 + (level * 36.0),
            right: 24,
            top: 14,
            bottom: 14,
          ),
          child: Row(
            children: [
              if (hasChildren)
                GestureDetector(
                  onTap: onExpand,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Icon(
                      isExpanded
                          ? Icons.keyboard_arrow_down_rounded
                          : Icons.keyboard_arrow_right_rounded,
                      color: colorScheme.onSurfaceVariant,
                      size: 24,
                    ),
                  ),
                )
              else if (level > 0)
                const SizedBox(width: 8),
              Expanded(
                child: Text(
                  category.name,
                  style: textTheme.bodyLarge?.copyWith(
                    color: isSelected
                        ? colorScheme.primary
                        : (isSelectable
                              ? colorScheme.onSurface
                              : colorScheme.onSurfaceVariant),
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
              if (isSelectable)
                if (isSelected)
                  Icon(Icons.check_circle_rounded, color: colorScheme.primary, size: 24)
                else
                  Icon(Icons.circle_outlined, color: colorScheme.outline, size: 24),
            ],
          ),
        ),
      );
    }

    Widget buildTreeView(final List<CategoryTreeNode> tree) {
      if (tree.isEmpty) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Text('沒有符合的分類', style: textTheme.bodyMedium),
          ),
        );
      }

      final widgets = <Widget>[];

      void collectNodes(final List<CategoryTreeNode> nodes, final int level) {
        for (final node in nodes) {
          final hasChildren = node.children.isNotEmpty;
          final isExpanded = expandedParents.value.contains(node.category.id);

          widgets.add(
            buildCategoryTile(
              node.category,
              level: level,
              hasChildren: hasChildren,
              isExpanded: isExpanded,
              onExpand: () => toggleExpand(node.category.id),
            ),
          );

          if (hasChildren && isExpanded) {
            collectNodes(node.children, level + 1);
          }
        }
      }

      collectNodes(tree, 0);

      return ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: widgets,
      );
    }

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.outline.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('選擇分類', style: textTheme.titleLarge),
                  TextButton(
                    onPressed: saveAndClose,
                    style: TextButton.styleFrom(
                      foregroundColor: colorScheme.primary,
                      textStyle: textTheme.titleMedium,
                    ),
                    child: const Text('完成'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: TextField(
                  controller: searchController,
                  style: textTheme.bodyLarge,
                  decoration: InputDecoration(
                    hintText: '搜尋分類...',
                    hintStyle: textTheme.bodyMedium,
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: colorScheme.onSurfaceVariant,
                      size: 20,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    isDense: true,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Flexible(child: buildTreeView(displayTree)),
            SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
