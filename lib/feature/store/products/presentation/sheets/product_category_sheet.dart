import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/feature/common/product_categories/domain/entities/category_tree_node.dart';
import 'package:tryzeon/feature/common/product_categories/domain/entities/product_category.dart';

class ProductCategorySheet extends HookWidget {
  const ProductCategorySheet({
    super.key,
    required this.categoryTree,
    required this.initialIds,
  });

  final List<CategoryTreeNode> categoryTree;
  final Set<String> initialIds;

  static Future<Set<String>?> show({
    required final BuildContext context,
    required final List<CategoryTreeNode> categoryTree,
    required final Set<String> initialIds,
  }) {
    return showModalBottomSheet<Set<String>>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (final _) =>
          ProductCategorySheet(categoryTree: categoryTree, initialIds: initialIds),
    );
  }

  @override
  Widget build(final BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final selection = useState<Set<String>>(initialIds);
    final expanded = useState<Set<String>>({});
    final searchController = useTextEditingController();
    useListenable(searchController);

    void toggleSelection(final String id) {
      final next = {...selection.value};
      if (next.contains(id)) {
        next.remove(id);
      } else {
        next.add(id);
      }
      selection.value = next;
    }

    void toggleExpand(final String parentId) {
      final next = {...expanded.value};
      if (next.contains(parentId)) {
        next.remove(parentId);
      } else {
        next.add(parentId);
      }
      expanded.value = next;
    }

    void done() {
      Navigator.of(context).pop(selection.value);
    }

    final query = searchController.text.trim().toLowerCase();
    final isSearching = query.isNotEmpty;

    final searchResults = useMemoized(() {
      if (!isSearching) return const <_LeafResult>[];
      final results = <_LeafResult>[];
      void walk(
        final List<CategoryTreeNode> nodes,
        final List<String> ancestorPath,
        final bool ancestorMatched,
      ) {
        for (final node in nodes) {
          final name = node.category.name;
          final selfMatches = name.toLowerCase().contains(query);
          final path = [...ancestorPath, name];
          if (node.children.isEmpty) {
            if (ancestorMatched || selfMatches) {
              results.add(_LeafResult(category: node.category, path: path));
            }
          } else {
            walk(node.children, path, ancestorMatched || selfMatches);
          }
        }
      }

      walk(categoryTree, const [], false);
      return results;
    }, [categoryTree, query]);

    Widget buildTile(
      final ProductCategory category, {
      final int level = 0,
      final bool hasChildren = false,
      final bool isExpanded = false,
      final VoidCallback? onExpand,
    }) {
      final isSelected = selection.value.contains(category.id);
      final isSelectable = !hasChildren;

      return InkWell(
        onTap: isSelectable
            ? () => toggleSelection(category.id)
            : (hasChildren ? onExpand : null),
        child: Container(
          padding: EdgeInsets.only(
            left: AppSpacing.lg + (level * AppSpacing.xl),
            right: AppSpacing.smMd,
            top: AppSpacing.sm,
            bottom: AppSpacing.sm,
          ),
          child: Row(
            children: [
              if (hasChildren)
                GestureDetector(
                  onTap: onExpand,
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    child: Icon(
                      isExpanded
                          ? Icons.keyboard_arrow_down_rounded
                          : Icons.keyboard_arrow_right_rounded,
                      color: colorScheme.onSurfaceVariant,
                      size: 20,
                    ),
                  ),
                )
              else if (level > 0)
                const SizedBox(width: AppSpacing.smMd, height: AppSpacing.smMd),
              Expanded(child: Text(category.name, style: textTheme.bodyLarge)),
              if (isSelectable)
                Checkbox(
                  value: isSelected,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  onChanged: (final _) => toggleSelection(category.id),
                ),
            ],
          ),
        ),
      );
    }

    Widget buildTree(final List<CategoryTreeNode> tree) {
      final widgets = <Widget>[];
      void collect(final List<CategoryTreeNode> nodes, final int level) {
        for (final node in nodes) {
          final hasChildren = node.children.isNotEmpty;
          final isExpanded = expanded.value.contains(node.category.id);
          widgets.add(
            buildTile(
              node.category,
              level: level,
              hasChildren: hasChildren,
              isExpanded: isExpanded,
              onExpand: () => toggleExpand(node.category.id),
            ),
          );
          if (hasChildren && isExpanded) {
            collect(node.children, level + 1);
          }
        }
      }

      collect(tree, 0);

      return ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        children: widgets,
      );
    }

    Widget buildSearchResults(final List<_LeafResult> results) {
      if (results.isEmpty) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Text(
              '沒有符合的分類',
              style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
            ),
          ),
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        itemCount: results.length,
        itemBuilder: (final context, final index) {
          final result = results[index];
          final isSelected = selection.value.contains(result.category.id);
          return InkWell(
            onTap: () => toggleSelection(result.category.id),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.xs,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          result.category.name,
                          style: textTheme.bodyLarge?.copyWith(
                            color: colorScheme.onSurface,
                          ),
                        ),
                        if (result.path.length > 1) ...[
                          const SizedBox(height: AppSpacing.xxs),
                          Text(
                            result.path.sublist(0, result.path.length - 1).join(' › '),
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Checkbox(
                    value: isSelected,
                    onChanged: (final _) => toggleSelection(result.category.id),
                  ),
                ],
              ),
            ),
          );
        },
      );
    }

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.7,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('選擇分類', style: textTheme.titleMedium),
                TextButton(onPressed: done, child: const Text('完成')),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: '搜尋分類...',
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: colorScheme.onSurfaceVariant,
                  size: 20,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Expanded(
            child: isSearching
                ? buildSearchResults(searchResults)
                : buildTree(categoryTree),
          ),
        ],
      ),
    );
  }
}

class _LeafResult {
  const _LeafResult({required this.category, required this.path});

  final ProductCategory category;
  final List<String> path;
}
