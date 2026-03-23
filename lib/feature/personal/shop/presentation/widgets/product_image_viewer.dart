import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class ProductImageViewer extends HookWidget {
  const ProductImageViewer({
    required this.imageUrls,
    required this.imagePaths,
    super.key,
  });

  final List<String> imageUrls;
  final List<String> imagePaths;

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final pageController = usePageController();
    final currentPage = useState(0);

    if (imageUrls.isEmpty) {
      return Container(
        height: 400,
        width: double.infinity,
        color: colorScheme.surfaceContainer,
        child: const Icon(Icons.image_not_supported, size: 50),
      );
    }

    return Stack(
      children: [
        SizedBox(
          height: 400,
          child: PageView.builder(
            controller: pageController,
            onPageChanged: (final index) => currentPage.value = index,
            itemCount: imageUrls.length,
            itemBuilder: (final context, final index) {
              final imageUrl = imageUrls[index];
              final imagePath = imagePaths.length > index ? imagePaths[index] : null;

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
                    placeholder: (final context, final url) => Center(
                      child: CircularProgressIndicator(color: colorScheme.primary),
                    ),
                    errorWidget: (final context, final url, final error) => Container(
                      height: 400,
                      color: colorScheme.surfaceContainer,
                      child: const Icon(Icons.image_not_supported, size: 50),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        if (imageUrls.length > 1)
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                imageUrls.length,
                (final index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: currentPage.value == index
                        ? colorScheme.primary
                        : Colors.white.withValues(alpha: 0.5),
                    border: Border.all(
                      color: Colors.black.withValues(alpha: 0.1),
                      width: 0.5,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
