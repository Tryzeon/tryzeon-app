import 'package:flutter_test/flutter_test.dart';
import 'package:tryzeon/core/utils/public_image_url.dart';
import 'package:tryzeon/feature/common/product_color/domain/entities/product_color.dart';
import 'package:tryzeon/feature/personal/shop/data/mappers/product_row_mapper.dart';

void main() {
  Map<String, dynamic> row({
    final List<Map<String, dynamic>>? colors,
    final String? logoPath,
    final List<String>? sizeNames,
  }) => {
    'id': 'p1',
    'name': '碎花洋裝',
    'category_id': 'c1',
    'garment_type': 'one_piece',
    'price': 1280,
    'product_colors': ?colors,
    'created_at': '2026-01-01T00:00:00Z',
    'updated_at': '2026-01-01T00:00:00Z',
    'store_profiles': {
      'id': 's1',
      'name': '小店',
      'channels': const <String>[],
      'logo_path': logoPath,
    },
    'product_sizes': [
      for (final (i, name) in (sizeNames ?? const <String>[]).indexed)
        {
          'id': 'size$i',
          'product_id': 'p1',
          'name': name,
          'created_at': '2026-01-01T00:00:00Z',
          'updated_at': '2026-01-01T00:00:00Z',
        },
    ],
  };

  Map<String, dynamic> colorRow(
    final int position,
    final List<String> imagePaths,
  ) => {
    'id': 'color$position',
    'product_id': 'p1',
    'name': null,
    'image_paths': imagePaths,
    'position': position,
    'created_at': '2026-01-01T00:00:00Z',
    'updated_at': '2026-01-01T00:00:00Z',
  };

  test('derives image and logo URLs from their storage paths', () {
    final product = decodeShopProductRow(
      row(
        colors: [
          colorRow(0, ['p1/a.jpg', 'p1/b.jpg']),
          colorRow(1, ['p1/c.jpg']),
        ],
        logoPath: 's1/logo.png',
      ),
    );

    expect(product.colors.map((final c) => c.position), [0, 1]);
    expect(product.colors.coverImageUrl, PublicImageUrl.of('p1/a.jpg'));
    expect(product.colors.first.imageUrls, [
      PublicImageUrl.of('p1/a.jpg'),
      PublicImageUrl.of('p1/b.jpg'),
    ]);
    expect(product.storeInfo.logoUrl, PublicImageUrl.of('s1/logo.png'));
  });

  test('a missing image list or blank logo path yields no URLs', () {
    final product = decodeShopProductRow(row(logoPath: ''));

    expect(product.colors, isEmpty);
    expect(product.storeInfo.logoUrl, isNull);
  });

  test('orders sizes by size label, not by row order', () {
    final product = decodeShopProductRow(
      row(sizeNames: ['均碼', 'L', '4XL', 'S', '3XL', 'M']),
    );

    expect(product.sizes!.map((final s) => s.name), [
      'S',
      'M',
      'L',
      '4XL',
      '3XL',
      '均碼',
    ]);
  });
}
