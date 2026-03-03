import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
          // Root Categories (Bold, Minimalist)
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

                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onRootSelected(node.category.id);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutCubic,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? colorScheme.primary
                          : colorScheme.surfaceContainer,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      node.category.name,
                      style: textTheme.labelLarge?.copyWith(
                        color: isSelected ? colorScheme.onPrimary : colorScheme.onSurface,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          // Subcategories (Squircle Cards)
          selectedRootNode == null
              ? const SizedBox(height: 120)
              : AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (final child, final animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0.0, 0.1),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    );
                  },
                  child: Column(
                    key: ValueKey(selectedRootNode.category.id),
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: selectedRootNode.children.map((final level2Node) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(
                              left: 30,
                              right: 0,
                              top: 0,
                              bottom: 5,
                            ),
                            child: Text(
                              level2Node.category.name,
                              style: textTheme.titleSmall,
                            ),
                          ),
                          SizedBox(
                            height: 96,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: level2Node.children.length,
                              separatorBuilder: (final context, final index) =>
                                  const SizedBox(width: 16),
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
                                      AnimatedContainer(
                                        duration: const Duration(milliseconds: 200),
                                        width: 60,
                                        height: 60,
                                        decoration: BoxDecoration(
                                          color: colorScheme.surfaceContainerHighest,
                                          borderRadius: BorderRadius.circular(20),
                                          border: isSelected
                                              ? Border.all(
                                                  color: colorScheme.primary,
                                                  width: 2.5,
                                                )
                                              : null,
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(18),
                                          child: (imageUrl != null && imageUrl.isNotEmpty)
                                              ? CachedNetworkImage(
                                                  imageUrl: imageUrl,
                                                  fit: BoxFit.cover,
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
                                      const SizedBox(height: 6),
                                      // Label
                                      SizedBox(
                                        width: 72,
                                        child: Text(
                                          level3Node.category.name,
                                          style: textTheme.labelMedium,
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
