import 'package:flutter_test/flutter_test.dart';
import 'package:tryzeon/core/utils/public_image_url.dart';
import 'package:tryzeon/feature/common/product_category/data/dtos/product_category_dto.dart';
import 'package:tryzeon/feature/common/product_category/data/mappers/product_category_mappr.dart';
import 'package:tryzeon/feature/common/product_category/domain/entities/product_category.dart';

void main() {
  test('image keys become public URLs, and a blank key means no image', () {
    final category = const ProductCategoryMappr()
        .convert<ProductCategoryDto, ProductCategory>(
          ProductCategoryDto.fromJson({
            'id': 'c1',
            'code': 'tops',
            'name': '上衣',
            'default_garment_type': 'top',
            'image_male': 'categories/tops_m.jpg',
            'image_female': '',
          }),
        );

    expect(category.imageMaleUrl, PublicImageUrl.of('categories/tops_m.jpg'));
    expect(category.imageFemaleUrl, isNull);
  });
}
