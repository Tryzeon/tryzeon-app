import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/presentation/widgets/error_view.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
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

      // Find currently selected root node, fallback to first node
      final selectedRootNode = useMemoized(() {
        if (categoryTree.isEmpty) return null;
        final effectiveId = selectedRootId ?? categoryTree.first.category.id;
        try {
          return categoryTree.firstWhere((final node) => node.category.id == effectiveId);
        } catch (_) {
          return categoryTree.first;
        }
      }, [categoryTree, selectedRootId]);

      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Root Categories (Bold, Minimalist)
          SizedBox(
            height: 48,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              itemCount: categoryTree.length,
              separatorBuilder: (final context, final index) =>
                  const SizedBox(width: AppSpacing.sm),
              itemBuilder: (final context, final index) {
                final node = categoryTree[index];
                final isSelected = node.category.id == selectedRootId;

                return ChoiceChip(
                  label: Text(node.category.name),
                  selected: isSelected,
                  onSelected: (final selected) {
                    if (selected) {
                      HapticFeedback.selectionClick();
                      onRootSelected(node.category.id);
                    }
                  },
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          // Subcategories (Squircle Cards)
          selectedRootNode == null
              ? const SizedBox(height: 120)
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: selectedRootNode.children.map((final level2Node) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(
                            left: AppSpacing.lg,
                            bottom: AppSpacing.xs,
                          ),
                          child: Text(
                            level2Node.category.name.toUpperCase(),
                            style: textTheme.labelLarge?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        SizedBox(
                          height: 96,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                            ),
                            itemCount: level2Node.children.length,
                            separatorBuilder: (final context, final index) =>
                                const SizedBox(width: AppSpacing.xxs),
                            itemBuilder: (final context, final index) {
                              final level3Node = level2Node.children[index];
                              final isSelected = selectedSubcategoryIds.contains(
                                level3Node.category.id,
                              );
                              final imageUrl = level3Node.category.imageUrl;

                              return GestureDetector(
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  onSubcategoryToggle(level3Node.category.id);
                                },
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Squircle Image Container
                                    Card(
                                      color: isSelected
                                          ? colorScheme.primaryContainer
                                          : colorScheme.surfaceContainerHighest,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: AppRadius.dialogAll,
                                        side: isSelected
                                            ? BorderSide(
                                                color: colorScheme.primary,
                                                width: 1.5,
                                              )
                                            : BorderSide.none,
                                      ),
                                      child: SizedBox(
                                        width: 56,
                                        height: 56,
                                        child: ClipRRect(
                                          borderRadius: AppRadius.dialogAll,
                                          child: (imageUrl != null && imageUrl.isNotEmpty)
                                              ? CachedNetworkImage(
                                                  imageUrl: imageUrl,
                                                  fit: BoxFit.cover,
                                                  memCacheWidth: 180,
                                                  memCacheHeight: 180,
                                                  placeholder:
                                                      (
                                                        final context,
                                                        final url,
                                                      ) => Center(
                                                        child: SizedBox(
                                                          width: 20,
                                                          height: 20,
                                                          child:
                                                              CircularProgressIndicator(
                                                                strokeWidth: 2.5,
                                                                color:
                                                                    colorScheme.outline,
                                                              ),
                                                        ),
                                                      ),
                                                  errorWidget:
                                                      (
                                                        final context,
                                                        final url,
                                                        final error,
                                                      ) => Icon(
                                                        Icons
                                                            .image_not_supported_outlined,
                                                        color:
                                                            colorScheme.onSurfaceVariant,
                                                      ),
                                                )
                                              : Icon(
                                                  Icons.image_not_supported_outlined,
                                                  color: colorScheme.onSurfaceVariant,
                                                ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: AppSpacing.xs),
                                    // Label
                                    SizedBox(
                                      width: 82,
                                      child: Text(
                                        level3Node.category.name,
                                        style: textTheme.labelSmall,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
        ],
      );
    }

    // Priority 2: Show loading indicator when loading without data
    if (categoryTreeAsync.isLoading) {
      return const SizedBox(
        height: 180,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    // Priority 3: Show error when failed without data
    return ErrorView(onRetry: onRetry, isCompact: true);
  }
}
