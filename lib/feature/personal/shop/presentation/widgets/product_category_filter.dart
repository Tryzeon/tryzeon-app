import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:tryzeon/core/presentation/widgets/error_view.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/feature/common/garment_type/domain/entities/garment_type.dart';
import 'package:tryzeon/feature/common/product_attributes/domain/entities/product_attributes.dart';
import 'package:tryzeon/feature/common/product_category/domain/entities/product_category.dart';

class ProductCategoryFilter extends StatelessWidget {
  const ProductCategoryFilter({
    super.key,
    required this.categoriesAsync,
    required this.selectedCategoryIds,
    required this.gender,
    required this.onCategoryToggle,
    required this.onRetry,
  });

  final AsyncValue<List<ProductCategory>> categoriesAsync;
  final Set<String> selectedCategoryIds;
  final ProductGender? gender;
  final void Function(String) onCategoryToggle;
  final VoidCallback onRetry;

  static final _skeletonCategories = List<ProductCategory>.generate(
    12,
    (final index) => ProductCategory(
      id: 'skeleton_$index',
      code: 'skeleton',
      name: 'Loading',
      defaultGarmentType: GarmentType.top,
    ),
  );

  @override
  Widget build(final BuildContext context) {
    // Priority 1: show data if available (even during loading or error).
    if (categoriesAsync.hasValue) {
      final categories = categoriesAsync.value!;
      if (categories.isEmpty) return const SizedBox.shrink();

      return _CategoryGrid(
        categories: categories,
        gender: gender,
        selectedCategoryIds: selectedCategoryIds,
        onCategoryTap: (final category) {
          HapticFeedback.selectionClick();
          onCategoryToggle(category.id);
        },
      );
    }

    // Priority 2: skeleton with the loaded grid's exact height, so data arriving
    // does not shift the page.
    if (categoriesAsync.isLoading) {
      return Skeletonizer(
        enabled: true,
        child: _CategoryGrid(
          categories: _skeletonCategories,
          gender: gender,
          selectedCategoryIds: const {},
          onCategoryTap: (final _) {},
        ),
      );
    }

    // Priority 3: error without data.
    return ErrorView(onRetry: onRetry, isCompact: true);
  }
}

class _CategoryGrid extends StatelessWidget {
  const _CategoryGrid({
    required this.categories,
    required this.gender,
    required this.selectedCategoryIds,
    required this.onCategoryTap,
  });

  static const _rowCount = 3;
  static const _height = 280.0;
  static const _minColumnWidth = 82.0;
  static const _columnSpacing = AppSpacing.xxs;

  final List<ProductCategory> categories;
  final ProductGender? gender;
  final Set<String> selectedCategoryIds;
  final ValueChanged<ProductCategory> onCategoryTap;

  @override
  Widget build(final BuildContext context) {
    return LayoutBuilder(
      builder: (final context, final constraints) {
        // Columns stretch to fill the width when they all fit, so a short list
        // never leaves a blank strip on the right; otherwise they keep their
        // minimum width and the grid scrolls.
        final availableWidth = constraints.maxWidth - AppSpacing.md * 2;
        final columnCount = (categories.length / _rowCount).ceil();
        final stretchedWidth =
            (availableWidth - _columnSpacing * (columnCount - 1)) / columnCount;
        final fitsWithoutScrolling = stretchedWidth >= _minColumnWidth;

        return SizedBox(
          height: _height,
          child: GridView.builder(
            scrollDirection: Axis.horizontal,
            physics: fitsWithoutScrolling
                ? const NeverScrollableScrollPhysics()
                : null,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: _rowCount,
              mainAxisExtent: fitsWithoutScrolling
                  ? stretchedWidth
                  : _minColumnWidth,
              mainAxisSpacing: _columnSpacing,
              crossAxisSpacing: AppSpacing.sm,
            ),
            itemCount: categories.length,
            itemBuilder: (final context, final index) {
              final category = categories[index];
              return _CategoryCard(
                category: category,
                gender: gender,
                isSelected: selectedCategoryIds.contains(category.id),
                onTap: () => onCategoryTap(category),
              );
            },
          ),
        );
      },
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.category,
    required this.gender,
    required this.isSelected,
    required this.onTap,
  });

  final ProductCategory category;
  final ProductGender? gender;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final imageUrl = gender == null ? null : category.imageUrlFor(gender!);

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Card(
            color: isSelected
                ? colorScheme.primaryContainer
                : colorScheme.surfaceContainerHighest,
            shape: RoundedRectangleBorder(
              borderRadius: AppRadius.dialogAll,
              side: isSelected
                  ? BorderSide(
                      color: colorScheme.onPrimaryContainer,
                      width: AppStroke.regular,
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
                        fadeInDuration: Duration.zero,
                        fadeOutDuration: Duration.zero,
                        placeholder: (final context, final url) => Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: AppStroke.regular,
                              color: colorScheme.outline,
                            ),
                          ),
                        ),
                        errorWidget: (final context, final url, final error) =>
                            Icon(
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
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            category.name,
            style: textTheme.labelSmall,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
