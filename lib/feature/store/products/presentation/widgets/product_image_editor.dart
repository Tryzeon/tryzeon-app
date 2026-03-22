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

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

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
          Text('商品圖片', style: textTheme.titleSmall),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: onPickImage,
            child: Container(
              height: 180,
              width: double.infinity,
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: colorScheme.primary.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: Stack(
                children: [
                  if (selectedImage != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.file(
                        selectedImage!,
                        fit: BoxFit.contain,
                        width: double.infinity,
                        height: double.infinity,
                      ),
                    )
                  else if (existingImageUrl != null && existingImageUrl!.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: CachedNetworkImage(
                        imageUrl: existingImageUrl!,
                        cacheKey: existingImagePath,
                        fit: BoxFit.contain,
                        width: double.infinity,
                        placeholder: (final context, final url) => Center(
                          child: CircularProgressIndicator(
                            color: colorScheme.outline,
                            strokeWidth: 2,
                          ),
                        ),
                        errorWidget: (final context, final url, final error) => Center(
                          child: Icon(Icons.error_outline, color: colorScheme.error),
                        ),
                      ),
                    )
                  else
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_photo_alternate_rounded,
                            size: 40,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '點擊選擇圖片',
                            style: textTheme.labelLarge?.copyWith(
                              color: colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (selectedImage != null ||
                      (existingImageUrl != null && existingImageUrl!.isNotEmpty))
                    Positioned(
                      bottom: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: colorScheme.inverseSurface,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.edit_outlined,
                          color: colorScheme.onInverseSurface,
                          size: 18,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
