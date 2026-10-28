import 'package:flutter_test/flutter_test.dart';
import 'package:tryzeon/core/utils/public_image_url.dart';
import 'package:tryzeon/feature/common/product_color/data/collections/product_color_embedded.dart';
import 'package:tryzeon/feature/common/product_color/data/dtos/product_color_dto.dart';
import 'package:tryzeon/feature/common/product_color/data/mappers/product_color_mappr.dart';
import 'package:tryzeon/feature/common/product_color/domain/entities/product_color.dart';

void main() {
  const mappr = ProductColorMappr();

  Map<String, dynamic> row(final int position) => {
    'id': 'c$position',
    'product_id': 'p1',
    'store_id': 's1',
    'name': '色$position',
    'image_paths': ['p1/$position.jpg'],
    'position': position,
    'created_at': '2026-01-01T00:00:00Z',
    'updated_at': '2026-01-01T00:00:00Z',
  };

  test('image URLs are derived from image paths', () {
    final color = mappr.convert<ProductColorDto, ProductColor>(
      ProductColorDto.fromJson(row(0)),
    );

    expect(color.imageUrls, color.imagePaths.map(PublicImageUrl.of).toList());
    expect(color.imageUrls, isNotEmpty);
  });

  test('a missing image_paths column decodes as empty', () {
    final dto = ProductColorDto.fromJson({...row(0)}..remove('image_paths'));

    expect(dto.imagePaths, isEmpty);
  });

  test('toJson carries only the editable columns', () {
    final json = ProductColorDto.fromJson(row(3)).toJson();

    expect(json.keys.toSet(), {'name', 'image_paths', 'position'});
  });

  test('embedded round trip preserves the entity', () {
    final color = mappr.convert<ProductColorDto, ProductColor>(
      ProductColorDto.fromJson(row(1)),
    );

    final embedded = mappr.convert<ProductColor, ProductColorEmbedded>(color);
    final back = mappr.convert<ProductColorEmbedded, ProductColor>(embedded);

    expect(back, color);
  });
}
