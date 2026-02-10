import 'package:cached_network_image/cached_network_image.dart';
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
          // Root Categories (Minimal Tabs)
          SizedBox(
            height: 36,
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
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? colorScheme.primary
                            : Colors.transparent, // Minimal look
                        border: isSelected
                            ? null
                            : Border.all(color: colorScheme.outlineVariant),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        node.category.name,
                        style: textTheme.labelMedium?.copyWith(
                          color: isSelected
                              ? colorScheme.onPrimary
                              : colorScheme.onSurface,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          // Subcategories (Horizontal List with Images)
          selectedRootNode == null
              ? const SizedBox(height: 100)
              : SizedBox(
                  key: ValueKey(selectedRootNode.category.id),
                  height: 100, // Fixed height for image + text
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
                              const SizedBox(width: 12),
                          itemBuilder: (final context, final index) {
                            final subNode = selectedRootNode.children[index];
                            final isSelected = selectedSubcategoryIds.contains(
                              subNode.category.id,
                            );
                            final imageUrl = subNode.category.imageUrl;

                            return GestureDetector(
                              onTap: () => onSubcategoryToggle(subNode.category.id),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Image Circle with Selection Indicator
                                  Container(
                                    padding: EdgeInsets.all(isSelected ? 3.0 : 0.0),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: isSelected
                                          ? Border.all(
                                              color: colorScheme.primary,
                                              width: 2,
                                            )
                                          : null,
                                    ),
                                    child: ClipOval(
                                      child: Container(
                                        width: 60,
                                        height: 60,
                                        color: colorScheme.surfaceContainerHighest,
                                        child: (imageUrl != null && imageUrl.isNotEmpty)
                                            ? CachedNetworkImage(
                                                imageUrl: imageUrl,
                                                fit: BoxFit.cover,
                                                placeholder: (final context, final url) =>
                                                    Center(
                                                      child: SizedBox(
                                                        width: 20,
                                                        height: 20,
                                                        child: CircularProgressIndicator(
                                                          strokeWidth: 2,
                                                          color: colorScheme.outline,
                                                        ),
                                                      ),
                                                    ),
                                                errorWidget:
                                                    (
                                                      final context,
                                                      final url,
                                                      final error,
                                                    ) => Icon(
                                                      Icons.image_not_supported_outlined,
                                                      size: 24,
                                                      color: colorScheme.onSurfaceVariant,
                                                    ),
                                              )
                                            : Icon(
                                                Icons.image_not_supported_outlined,
                                                size: 24,
                                                color: colorScheme.onSurfaceVariant,
                                              ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  // Label
                                  Text(
                                    subNode.category.name,
                                    style: textTheme.labelMedium?.copyWith(
                                      color: isSelected
                                          ? colorScheme.primary
                                          : colorScheme.onSurface,
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
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
        height: 160,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    // Priority 3: Show error when failed without data
    return ErrorView(onRetry: onRetry, isCompact: true);
  }
}
