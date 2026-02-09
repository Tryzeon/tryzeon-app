import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:tryzeon/feature/common/product_categories/domain/entities/category_tree_node.dart';
import 'package:tryzeon/feature/common/product_categories/domain/entities/product_category.dart';

class ProductCategoryFilter extends HookWidget {
  const ProductCategoryFilter({
    super.key,
    required this.categoryTree,
    required this.selectedRootId,
    required this.selectedSubcategoryIds,
    required this.onRootSelected,
    required this.onSubcategoryToggle,
  });

  final List<CategoryTreeNode>? categoryTree;
  final String? selectedRootId;
  final Set<String> selectedSubcategoryIds;
  final Function(String) onRootSelected;
  final Function(String) onSubcategoryToggle;

  @override
  Widget build(final BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    // Provide skeleton data when categoryTree is null
    final effectiveCategoryTree =
        categoryTree ??
        List.generate(
          4,
          (final index) => CategoryTreeNode(
            category: ProductCategory(id: 'skeleton-root-$index', name: '載入中'),
            children: List.generate(
              5,
              (final childIndex) => CategoryTreeNode(
                category: ProductCategory(
                  id: 'skeleton-child-$index-$childIndex',
                  name: '載入中',
                  parentId: 'skeleton-root-$index',
                ),
              ),
            ),
          ),
        );

    // Auto-select first root category if none selected
    useEffect(() {
      if (selectedRootId == null && effectiveCategoryTree.isNotEmpty) {
        // Use addPostFrameCallback to avoid build-time state updates
        WidgetsBinding.instance.addPostFrameCallback((_) {
          onRootSelected(effectiveCategoryTree.first.category.id);
        });
      }
      return null;
    }, [effectiveCategoryTree, selectedRootId]);

    // Find currently selected root node
    final selectedRootNode = useMemoized(() {
      if (selectedRootId == null) return null;
      try {
        return effectiveCategoryTree.firstWhere(
          (final node) => node.category.id == selectedRootId,
        );
      } catch (_) {
        return null;
      }
    }, [effectiveCategoryTree, selectedRootId]);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Root Categories (Tabs)
        SizedBox(
          height: 48,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: effectiveCategoryTree.length,
            separatorBuilder: (final context, final index) => const SizedBox(width: 8),
            itemBuilder: (final context, final index) {
              final node = effectiveCategoryTree[index];
              final isSelected = node.category.id == selectedRootId;

              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => onRootSelected(node.category.id),
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? colorScheme.primary
                          : colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      node.category.name,
                      style: textTheme.labelLarge?.copyWith(
                        color: isSelected
                            ? colorScheme.onPrimary
                            : colorScheme.onSurfaceVariant,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        // Subcategories (Chips)
        selectedRootNode == null
            ? const SizedBox(height: 40)
            : SizedBox(
                key: ValueKey(selectedRootNode.category.id),
                height: 40,
                child: selectedRootNode.children.isEmpty
                    ? Center(
                        child: Text(
                          '此分類無子分類',
                          style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.outline,
                          ),
                        ),
                      )
                    : ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: selectedRootNode.children.length,
                        separatorBuilder: (final context, final index) =>
                            const SizedBox(width: 8),
                        itemBuilder: (final context, final index) {
                          final subNode = selectedRootNode.children[index];
                          final isSelected = selectedSubcategoryIds.contains(
                            subNode.category.id,
                          );

                          return FilterChip(
                            label: Text(subNode.category.name),
                            selected: isSelected,
                            onSelected: (_) => onSubcategoryToggle(subNode.category.id),
                            showCheckmark: true,
                            checkmarkColor: colorScheme.onSecondaryContainer,
                            selectedColor: colorScheme.secondaryContainer,
                            labelStyle: textTheme.labelMedium?.copyWith(
                              color: isSelected
                                  ? colorScheme.onSecondaryContainer
                                  : colorScheme.onSurface,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                            backgroundColor: colorScheme.surface,
                            side: isSelected
                                ? BorderSide.none
                                : BorderSide(color: colorScheme.outlineVariant),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                          );
                        },
                      ),
              ),
      ],
    );
  }
}
