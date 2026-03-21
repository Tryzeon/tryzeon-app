import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:tryzeon/feature/common/product_categories/domain/entities/category_tree_node.dart';
import 'package:tryzeon/feature/common/product_categories/domain/entities/product_category.dart';

class ProductCategorySelector extends HookWidget {
  const ProductCategorySelector({
    super.key,
    required this.categoryTree,
    required this.selectedCategoryIds,
    this.onChanged,
  });

  final List<CategoryTreeNode> categoryTree;
  final ValueNotifier<Set<String>> selectedCategoryIds;
  final ValueChanged<Set<String>>? onChanged;

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final selectedIdsNotifier = useListenable(selectedCategoryIds);
    final selectedIds = selectedIdsNotifier.value;

    // Flatten tree into a map for quick access with parent path
    final categoryMap = useMemoized(() {
      final map = <String, String>{};
      void visit(final List<CategoryTreeNode> nodes, final List<String> parentPath) {
        for (final node in nodes) {
          final currentPath = [...parentPath, node.category.name];
          map[node.category.id] = currentPath.join(' - ');
          visit(node.children, currentPath);
        }
      }

      visit(categoryTree, []);
      return map;
    }, [categoryTree]);

    String getCategoryNameById(final String id) {
      return categoryMap[id] ?? id;
    }

    void showSelectionSheet() {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        useRootNavigator: true,
        builder: (final context) => _HierarchicalSelectionSheet(
          categoryTree: categoryTree,
          selectedIds: selectedIds,
          onSelectionChanged: (final ids) {
            if (onChanged != null) {
              onChanged!(ids);
            } else {
              selectedCategoryIds.value = ids;
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
              child: selectedIds.isEmpty
                  ? Text(
                      '選擇商品分類',
                      style: textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                      ),
                    )
                  : Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: selectedIds.map((final id) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            getCategoryNameById(id),
                            style: textTheme.labelSmall?.copyWith(
                              color: colorScheme.onPrimaryContainer,
                            ),
                          ),
                        );
                      }).toList(),
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
    required this.selectedIds,
    required this.onSelectionChanged,
  });

  final List<CategoryTreeNode> categoryTree;
  final Set<String> selectedIds;
  final ValueChanged<Set<String>> onSelectionChanged;

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final currentSelection = useState<Set<String>>(selectedIds);
    final expandedParents = useState<Set<String>>({});
    final searchController = useTextEditingController();
    useListenable(searchController);

    void toggleSelection(final String id) {
      final newSet = {...currentSelection.value};
      if (newSet.contains(id)) {
        newSet.remove(id);
      } else {
        newSet.add(id);
      }
      currentSelection.value = newSet;
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
      final isSelected = currentSelection.value.contains(category.id);
      final isSelectable = !hasChildren; // Only leaf nodes are selectable

      return InkWell(
        onTap: isSelectable
            ? () => toggleSelection(category.id)
            : (hasChildren ? onExpand : null),
        child: Container(
          padding: EdgeInsets.only(
            left: 24.0 + (level * 36.0),
            right: 12,
            top: 6,
            bottom: 6,
          ),
          child: Row(
            children: [
              if (hasChildren)
                GestureDetector(
                  onTap: onExpand,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
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
                const SizedBox(width: 8, height: 40),
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
                Checkbox(
                  value: isSelected,
                  onChanged: (_) => toggleSelection(category.id),
                  activeColor: colorScheme.primary,
                ),
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
