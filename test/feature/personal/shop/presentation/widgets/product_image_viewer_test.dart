import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/feature/personal/shop/presentation/widgets/product_image_viewer.dart';

void main() {
  testWidgets('builds the next image before it is swiped to', (
    final tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const Scaffold(
          body: ProductImageViewer(
            imageUrls: [
              'https://cdn/a.jpg',
              'https://cdn/b.jpg',
              'https://cdn/c.jpg',
            ],
          ),
        ),
      ),
    );

    final built = tester
        .widgetList<CachedNetworkImage>(
          find.byType(CachedNetworkImage, skipOffstage: false),
        )
        .map((final image) => image.imageUrl);
    expect(built, ['https://cdn/a.jpg', 'https://cdn/b.jpg']);
  });
}
