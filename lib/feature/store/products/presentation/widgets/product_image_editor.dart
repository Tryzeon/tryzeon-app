import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class ProductImageEditor extends StatelessWidget {
  const ProductImageEditor({
    super.key,
    required this.selectedImages,
    required this.onPickImage,
    required this.onRemoveImage,
    this.existingImageUrls,
    this.existingImagePaths,
  });

  final List<File> selectedImages;
  final List<String>? existingImageUrls;
  final List<String>? existingImagePaths;
  final VoidCallback onPickImage;
  final void Function(int index, bool isExisting) onRemoveImage;

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final totalCount = selectedImages.length + (existingImageUrls?.length ?? 0);

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
              Text(
                '$totalCount/3',
                style: textTheme.bodySmall?.copyWith(
                  color: totalCount >= 3
                      ? colorScheme.error
                      : colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (totalCount == 0)
            GestureDetector(
              onTap: onPickImage,
              child: _buildAddImagePlaceholder(context, colorScheme, textTheme),
            )
          else
            Column(
              children: [
                SizedBox(
                  height: 120,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      if (existingImageUrls != null)
                        ...existingImageUrls!.asMap().entries.map((final e) {
                          final idx = e.key;
                          final url = e.value;
                          final cacheKey =
                              existingImagePaths != null &&
                                  existingImagePaths!.length > idx
                              ? existingImagePaths![idx]
                              : null;
                          return _buildImageCard(
                            context,
                            colorScheme,
                            child: CachedNetworkImage(
                              imageUrl: url,
                              cacheKey: cacheKey,
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
                                  Center(
                                    child: Icon(
                                      Icons.error_outline,
                                      color: colorScheme.error,
                                    ),
                                  ),
                            ),
                            onRemove: () => onRemoveImage(idx, true),
                          );
                        }),
                      ...selectedImages.asMap().entries.map((final e) {
                        final idx = e.key;
                        final file = e.value;
                        return _buildImageCard(
                          context,
                          colorScheme,
                          child: Image.file(
                            file,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                          ),
                          onRemove: () => onRemoveImage(idx, false),
                        );
                      }),
                      if (totalCount < 3)
                        GestureDetector(
                          onTap: onPickImage,
                          child: Container(
                            width: 120,
                            margin: const EdgeInsets.only(right: 12),
                            decoration: BoxDecoration(
                              color: colorScheme.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: colorScheme.primary.withValues(alpha: 0.3),
                                width: 2,
                              ),
                            ),
                            child: Center(
                              child: Icon(
                                Icons.add_photo_alternate_rounded,
                                size: 32,
                                color: colorScheme.primary,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildImageCard(
    final BuildContext context,
    final ColorScheme colorScheme, {
    required final Widget child,
    required final VoidCallback onRemove,
  }) {
    return Container(
      width: 120,
      margin: const EdgeInsets.only(right: 12),
      child: Stack(
        children: [
          ClipRRect(borderRadius: BorderRadius.circular(12), child: child),
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
