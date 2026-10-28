import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:tryzeon/core/config/app_constants.dart';
import 'package:tryzeon/core/presentation/coach_mark/coach_mark_anchor.dart';
import 'package:tryzeon/core/presentation/coach_mark/coach_mark_target.dart';
import 'package:tryzeon/core/presentation/widgets/lifted_reorder_proxy.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/feature/store/product/domain/value_objects/image_item.dart';

class ProductImageEditor extends StatelessWidget {
  const ProductImageEditor({
    super.key,
    required this.images,
    required this.onImagesChanged,
    required this.onPickImage,
    required this.hasError,
    required this.hostsCoachMark,
    required this.horizontalPadding,
    required this.showsCount,
  });

  final List<ImageItem> images;
  final ValueChanged<List<ImageItem>> onImagesChanged;
  final VoidCallback onPickImage;
  final bool hasError;
  final bool hostsCoachMark;
  final double horizontalPadding;
  final bool showsCount;

  @override
  Widget build(final BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final canAddMore = images.length < AppConstants.maxProductImages;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showsCount) ...[
          Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: Text(
              photoCountLabel(images.length),
              style: textTheme.labelMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.smMd),
        ],
        if (images.isEmpty)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: GestureDetector(
              onTap: onPickImage,
              child: hostsCoachMark
                  ? CoachMarkAnchor(
                      target: CoachMarkTarget.productImages,
                      child: _AddPlaceholder(hasError: hasError),
                    )
                  : _AddPlaceholder(hasError: hasError),
            ),
          )
        else
          SizedBox(
            height: _thumbnailSize,
            child: ReorderableListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              buildDefaultDragHandles: false,
              proxyDecorator: liftedReorderProxy,
              itemCount: images.length + (canAddMore ? 1 : 0),
              onReorderItem: (final oldIndex, final newIndex) {
                if (oldIndex >= images.length) return;
                final updated = List<ImageItem>.from(images);
                final item = updated.removeAt(oldIndex);
                updated.insert(newIndex.clamp(0, updated.length), item);
                onImagesChanged(updated);
              },
              itemBuilder: (final context, final index) {
                if (index == images.length) {
                  return Padding(
                    key: const ValueKey('add-tile'),
                    padding: const EdgeInsets.only(right: AppSpacing.sm),
                    child: GestureDetector(
                      onTap: onPickImage,
                      child: const _AddTile(),
                    ),
                  );
                }
                final item = images[index];
                return Padding(
                  key: ValueKey(item),
                  padding: const EdgeInsets.only(right: AppSpacing.sm),
                  child: ReorderableDelayedDragStartListener(
                    index: index,
                    child: _ImageCard(
                      item: item,
                      isMain: index == 0,
                      onRemove: () {
                        final updated = List<ImageItem>.from(images)
                          ..removeAt(index);
                        onImagesChanged(updated);
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        if (images.length > 1) ...[
          const SizedBox(height: AppSpacing.sm),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: Text(
              '長按照片拖曳調整順序',
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

String photoCountLabel(final int count) =>
    '照片 $count/${AppConstants.maxProductImages}';

const _thumbnailSize = 96.0;
const _removeHitSize = 40.0;

class _ImageCard extends StatelessWidget {
  const _ImageCard({
    required this.item,
    required this.isMain,
    required this.onRemove,
  });

  final ImageItem item;
  final bool isMain;
  final VoidCallback onRemove;

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox.square(
      dimension: _thumbnailSize,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: AppRadius.buttonAll,
            child: ProductImageView(item: item, size: _thumbnailSize),
          ),
          if (isMain)
            Positioned(
              left: AppSpacing.xs,
              bottom: AppSpacing.xs,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xs,
                  vertical: AppSpacing.xxs,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.scrim.withValues(
                    alpha: AppOpacity.overlay,
                  ),
                  borderRadius: AppRadius.pillAll,
                ),
                child: Text(
                  '試穿主圖',
                  style: Theme.of(
                    context,
                  ).textTheme.labelSmall?.copyWith(color: Colors.white),
                ),
              ),
            ),
          Positioned(
            top: 0,
            right: 0,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onRemove,
              child: SizedBox.square(
                dimension: _removeHitSize,
                child: Align(
                  alignment: Alignment.topRight,
                  child: Container(
                    margin: const EdgeInsets.all(AppSpacing.xs),
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: colorScheme.scrim,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ProductImageView extends StatelessWidget {
  const ProductImageView({super.key, required this.item, required this.size});

  final ImageItem item;
  final double size;

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    // Product photos are portrait garment shots, so decoding at the tile's
    // width still leaves the cover crop's height sharp.
    final decodeWidth = (size * MediaQuery.devicePixelRatioOf(context)).round();

    return switch (item) {
      ExistingImageItem(:final url) => CachedNetworkImage(
        imageUrl: url,
        fit: BoxFit.cover,
        width: size,
        height: size,
        memCacheWidth: decodeWidth,
        placeholder: (final context, final url) =>
            Container(color: colorScheme.surfaceContainerLow),
        errorWidget: (final context, final url, final error) =>
            const Center(child: Icon(Icons.broken_image_outlined)),
      ),
      NewImageItem(:final file) => Image.file(
        file,
        fit: BoxFit.cover,
        width: size,
        height: size,
        cacheWidth: decodeWidth,
      ),
    };
  }
}

class _AddTile extends StatelessWidget {
  const _AddTile();

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: _thumbnailSize,
      height: _thumbnailSize,
      decoration: BoxDecoration(
        borderRadius: AppRadius.buttonAll,
        border: Border.all(
          color: colorScheme.outline,
          width: AppStroke.regular,
          strokeAlign: BorderSide.strokeAlignInside,
        ),
      ),
      child: Center(
        child: Icon(
          Icons.add_rounded,
          color: colorScheme.onSurfaceVariant,
          size: 24,
        ),
      ),
    );
  }
}

class _AddPlaceholder extends StatelessWidget {
  const _AddPlaceholder({this.hasError = false});

  final bool hasError;

  @override
  Widget build(final BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Container(
      height: 160,
      width: double.infinity,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: AppRadius.buttonAll,
        border: Border.all(
          color: hasError ? colorScheme.error : colorScheme.outline,
          width: AppStroke.regular,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_photo_alternate_outlined,
              size: 32,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '點擊新增',
              style: textTheme.labelMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
