import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:tryzeon/core/config/app_constants.dart';
import 'package:tryzeon/feature/store/products/domain/value_objects/image_item.dart';

class ProductImageEditor extends StatelessWidget {
  const ProductImageEditor({
    super.key,
    required this.images,
    required this.onImagesChanged,
    required this.onPickImage,
    this.maxImages = AppConstants.maxProductImages,
  });

  final List<ImageItem> images;
  final ValueChanged<List<ImageItem>> onImagesChanged;
  final VoidCallback onPickImage;
  final int maxImages;

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final canAddMore = images.length < maxImages;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('商品圖片', style: textTheme.titleSmall),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (canAddMore) ...[
                    GestureDetector(
                      onTap: onPickImage,
                      child: Icon(Icons.add, color: colorScheme.primary, size: 28),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    '${images.length}/$maxImages',
                    style: textTheme.bodySmall?.copyWith(
                      color: images.length >= maxImages
                          ? colorScheme.error
                          : colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '長按拖曳可調整順序',
            style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          if (images.isEmpty)
            GestureDetector(
              onTap: onPickImage,
              child: _buildAddImagePlaceholder(context, colorScheme, textTheme),
            )
          else
            SizedBox(
              height: 120,
              child: ReorderableListView.builder(
                scrollDirection: Axis.horizontal,
                buildDefaultDragHandles: false,
                proxyDecorator: (final child, final index, final animation) {
                  return Material(
                    color: Colors.transparent,
                    shadowColor: Colors.transparent,
                    child: child,
                  );
                },
                itemCount: images.length,
                onReorder: (final oldIndex, final newIndex) {
                  final updated = List<ImageItem>.from(images);
                  final item = updated.removeAt(oldIndex);
                  final insertIndex = newIndex > oldIndex ? newIndex - 1 : newIndex;
                  updated.insert(insertIndex, item);
                  onImagesChanged(updated);
                },
                itemBuilder: (final context, final index) {
                  final item = images[index];
                  return ReorderableDragStartListener(
                    key: ValueKey(item),
                    index: index,
                    child: _buildImageCard(
                      context,
                      colorScheme,
                      item: item,
                      onRemove: () {
                        final updated = List<ImageItem>.from(images)..removeAt(index);
                        onImagesChanged(updated);
                      },
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildImageCard(
    final BuildContext context,
    final ColorScheme colorScheme, {
    required final ImageItem item,
    required final VoidCallback onRemove,
  }) {
    return Container(
      width: 120,
      margin: const EdgeInsets.only(right: 12),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: switch (item) {
              ExistingImageItem(:final url, :final path) => CachedNetworkImage(
                imageUrl: url,
                cacheKey: path,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                placeholder: (final context, final url) => Center(
                  child: CircularProgressIndicator(
                    color: colorScheme.outline,
                    strokeWidth: 2,
                  ),
                ),
                errorWidget: (final context, final url, final error) =>
                    Center(child: Icon(Icons.error_outline, color: colorScheme.error)),
              ),
              NewImageItem(:final file) => Image.file(
                file,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              ),
            },
          ),
          // Remove button
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, size: 16, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddImagePlaceholder(
    final BuildContext context,
    final ColorScheme colorScheme,
    final TextTheme textTheme,
  ) {
    return Container(
      height: 180,
      width: double.infinity,
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.3), width: 2),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_photo_alternate_rounded, size: 40, color: colorScheme.primary),
            const SizedBox(height: 6),
            Text('點擊選擇圖片', style: textTheme.labelLarge),
          ],
        ),
      ),
    );
  }
}
