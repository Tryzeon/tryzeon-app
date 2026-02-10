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
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
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
                  child: SizedBox(
                    key: ValueKey(selectedRootNode.category.id),
                    height: 120,
                    child: selectedRootNode.children.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.search_off_rounded,
                                  size: 32,
                                  color: colorScheme.outline,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '此分類無子分類',
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: colorScheme.outline,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.separated(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: selectedRootNode.children.length,
                            separatorBuilder: (final context, final index) =>
                                const SizedBox(width: 16),
                            itemBuilder: (final context, final index) {
                              final subNode = selectedRootNode.children[index];
                              final isSelected = selectedSubcategoryIds.contains(
                                subNode.category.id,
                              );
                              final imageUrl = subNode.category.imageUrl;

                              return GestureDetector(
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  onSubcategoryToggle(subNode.category.id);
                                },
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Squircle Image Container
                                    AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      width: 80,
                                      height: 80,
                                      decoration: BoxDecoration(
                                        color: colorScheme.surfaceContainerHighest,
                                        borderRadius: BorderRadius.circular(28),
                                        border: isSelected
                                            ? Border.all(
                                                color: colorScheme.primary,
                                                width: 3,
                                              )
                                            : null,
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(25),
                                        child: (imageUrl != null && imageUrl.isNotEmpty)
                                            ? CachedNetworkImage(
                                                imageUrl: imageUrl,
                                                fit: BoxFit.cover,
                                                placeholder: (final context, final url) =>
                                                    Center(
                                                      child: SizedBox(
                                                        width: 24,
                                                        height: 24,
                                                        child: CircularProgressIndicator(
                                                          strokeWidth: 2.5,
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
                                                      color: colorScheme.onSurfaceVariant,
                                                    ),
                                              )
                                            : Icon(
                                                Icons.image_not_supported_outlined,
                                                color: colorScheme.onSurfaceVariant,
                                              ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    // Label
                                    Text(
                                      subNode.category.name,
                                      style: textTheme.labelLarge,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
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
