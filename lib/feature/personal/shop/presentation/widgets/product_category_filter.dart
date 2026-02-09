import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/presentation/widgets/error_view.dart';
import 'package:tryzeon/feature/common/product_categories/domain/entities/category_tree_node.dart';

class ProductCategoryFilter extends HookConsumerWidget {
  const ProductCategoryFilter({
    super.key,
    required this.categoryTreeAsync,
    required this.selectedRootId,
    required this.selectedSubcategoryIds,
    required this.onRootSelected,
    required this.onSubcategoryToggle,
    required this.onRetry,
  });

  final AsyncValue<List<CategoryTreeNode>> categoryTreeAsync;
  final String? selectedRootId;
  final Set<String> selectedSubcategoryIds;
  final Function(String) onRootSelected;
  final Function(String) onSubcategoryToggle;
  final VoidCallback onRetry;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    // Priority 1: Show data if available (even during loading or error)
    if (categoryTreeAsync.hasValue) {
      final categoryTree = categoryTreeAsync.value!;

      // Auto-select first root category if none selected
      useEffect(() {
        if (selectedRootId == null && categoryTree.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            onRootSelected(categoryTree.first.category.id);
          });
        }
        return null;
      }, [categoryTree, selectedRootId]);

      // Find currently selected root node
      final selectedRootNode = useMemoized(() {
        if (selectedRootId == null) return null;
        try {
          return categoryTree.firstWhere(
            (final node) => node.category.id == selectedRootId,
          );
        } catch (_) {
          return null;
        }
      }, [categoryTree, selectedRootId]);

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
              itemCount: categoryTree.length,
              separatorBuilder: (final context, final index) => const SizedBox(width: 8),
              itemBuilder: (final context, final index) {
                final node = categoryTree[index];
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

    // Priority 2: Show loading indicator when loading without data
    if (categoryTreeAsync.isLoading) {
      return const SizedBox(
        height: 100,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    // Priority 3: Show error when failed without data
    return ErrorView(onRetry: onRetry, isCompact: true);
  }
}
