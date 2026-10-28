import 'package:flutter_test/flutter_test.dart';
import 'package:tryzeon/feature/common/product_color/domain/entities/product_color.dart';

void main() {
  ProductColor color(final int position, final List<String> paths) =>
      ProductColor(
        id: 'c$position',
        productId: 'p1',
        imagePaths: paths,
        imageUrls: paths.map((final p) => 'https://cdn/$p').toList(),
        position: position,
        createdAt: DateTime.utc(2026),
        updatedAt: DateTime.utc(2026),
      );

  test('the cover is the first colour as delivered', () {
    final colors = [
      color(1, ['k1', 'k2']),
      color(0, ['k0']),
    ];

    expect(colors.cover?.position, 1);
    expect(colors.coverImagePath, 'k1');
    expect(colors.coverImageUrl, 'https://cdn/k1');
  });

  test('an empty list has no cover', () {
    expect(<ProductColor>[].cover, isNull);
    expect(<ProductColor>[].coverImageUrl, isNull);
    expect(<ProductColor>[].coverImagePath, isNull);
  });
}
