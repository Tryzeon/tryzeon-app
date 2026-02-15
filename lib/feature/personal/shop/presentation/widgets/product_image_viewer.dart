import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class ProductImageViewer extends StatelessWidget {
  const ProductImageViewer({required this.imageUrl, required this.imagePath, super.key});

  final String imageUrl;
  final String imagePath;

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (final context) => Scaffold(
              backgroundColor: Colors.black,
              appBar: AppBar(
                backgroundColor: Colors.black,
                iconTheme: const IconThemeData(color: Colors.white),
              ),
              body: Center(
                child: InteractiveViewer(
                  child: CachedNetworkImage(
                    imageUrl: imageUrl,
                    cacheKey: imagePath,
                    fit: BoxFit.contain,
                    width: double.infinity,
                    height: double.infinity,
                    placeholder: (final context, final url) =>
                        const Center(child: CircularProgressIndicator()),
                  ),
                ),
              ),
            ),
          ),
        );
      },
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          cacheKey: imagePath,
          width: double.infinity,
          height: 400,
          fit: BoxFit.cover,
          placeholder: (final context, final url) =>
              Center(child: CircularProgressIndicator(color: colorScheme.primary)),
          errorWidget: (final context, final url, final error) => Container(
            height: 400,
            color: colorScheme.surfaceContainer,
            child: const Icon(Icons.image_not_supported, size: 50),
          ),
        ),
      ),
    );
  }
}
