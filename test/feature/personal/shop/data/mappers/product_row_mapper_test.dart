import 'package:flutter_test/flutter_test.dart';
import 'package:tryzeon/core/utils/public_image_url.dart';
import 'package:tryzeon/feature/personal/shop/data/mappers/product_row_mapper.dart';

void main() {
  Map<String, dynamic> row({
    final List<String>? imagePaths,
    final String? logoPath,
    final List<String>? sizeNames,
  }) => {
    'id': 'p1',
    'name': '碎花洋裝',
    'category_id': 'c1',
    'garment_type': 'one_piece',
    'price': 1280,
    'image_paths': imagePaths,
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

  test('derives image and logo URLs from their storage paths', () {
    final product = decodeShopProductRow(
      row(imagePaths: ['p1/a.jpg', 'p1/b.jpg'], logoPath: 's1/logo.png'),
    );

    expect(product.imagePaths, ['p1/a.jpg', 'p1/b.jpg']);
    expect(product.imageUrls, [
      PublicImageUrl.of('p1/a.jpg'),
      PublicImageUrl.of('p1/b.jpg'),
    ]);
    expect(product.storeInfo.logoUrl, PublicImageUrl.of('s1/logo.png'));
  });

  test('a missing image list or blank logo path yields no URLs', () {
    final product = decodeShopProductRow(row(logoPath: ''));

    expect(product.imagePaths, isEmpty);
    expect(product.imageUrls, isEmpty);
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
