import 'package:flutter_test/flutter_test.dart';
import 'package:tryzeon/core/utils/public_image_url.dart';
import 'package:tryzeon/feature/common/garment_type/domain/entities/garment_type.dart';
import 'package:tryzeon/feature/store/product/data/dtos/create_product_request.dart';
import 'package:tryzeon/feature/store/product/data/dtos/create_product_size_request.dart';
import 'package:tryzeon/feature/store/product/data/dtos/product_dto.dart';
import 'package:tryzeon/feature/store/product/data/dtos/product_size_draft_dto.dart';
import 'package:tryzeon/feature/store/product/data/mappers/store_product_mappr.dart';
import 'package:tryzeon/feature/store/product/domain/entities/product.dart';
import 'package:tryzeon/feature/store/product/domain/value_objects/size_item.dart';

void main() {
  const mappr = StoreProductMappr();

  Map<String, dynamic> productRow({final List<String>? imagePaths}) => {
    'id': 'p1',
    'store_id': 's1',
    'name': '碎花洋裝',
    'category_id': 'c1',
    'garment_type': 'one_piece',
    'price': 1280,
    'image_paths': imagePaths,
    'created_at': '2026-01-01T00:00:00Z',
    'updated_at': '2026-01-01T00:00:00Z',
  };

  test('product image URLs are derived from image paths', () {
    final product = mappr.convert<ProductDto, Product>(
      ProductDto.fromJson(productRow(imagePaths: ['p1/a.jpg'])),
    );

    expect(product.imageUrls, [PublicImageUrl.of('p1/a.jpg')]);
  });

  test('a null image_paths column decodes as no images', () {
    final product = mappr.convert<ProductDto, Product>(
      ProductDto.fromJson(productRow()),
    );

    expect(product.imagePaths, isEmpty);
    expect(product.imageUrls, isEmpty);
  });

  test('update payloads leave out server-owned columns', () {
    final product = mappr.convert<ProductDto, Product>(
      ProductDto.fromJson({
        ...productRow(),
        'product_sizes': [
          {
            'id': 'm',
            'product_id': 'p1',
            'name': 'M',
            'created_at': '2026-01-01T00:00:00Z',
            'updated_at': '2026-01-01T00:00:00Z',
          },
        ],
      }),
    );

    final productJson = mappr.convert<Product, ProductDto>(product).toJson();
    final sizeJson = mappr
        .convert<ProductSize, ProductSizeDto>(product.sizes!.single)
        .toJson();

    expect(
      productJson.keys,
      isNot(anyOf(contains('id'), contains('store_id'))),
    );
    expect(sizeJson.keys, [
      'name',
      'garment_measurements',
      'body_measurement_ranges',
    ]);
  });

  test('a new product becomes one flat insert row', () {
    final request = mappr.convert<NewProduct, CreateProductRequest>(
      const NewProduct(
        id: 'p1',
        storeId: 's1',
        draft: ProductDraft(
          name: '碎花洋裝',
          categoryId: 'c1',
          garmentType: GarmentType.onePiece,
          price: 1280,
        ),
        imagePaths: ['p1.jpg'],
        sizes: [],
      ),
    );

    expect(request.toJson(), {
      'id': 'p1',
      'store_id': 's1',
      'image_paths': ['p1.jpg'],
      'name': '碎花洋裝',
      'category_id': 'c1',
      'garment_type': 'one_piece',
      'price': 1280.0,
      'gender': 'unisex',
      'purchase_link': null,
      'description': null,
      'material': null,
      'elasticity': null,
      'fit': null,
      'thickness': null,
      'styles': null,
      'seasons': null,
    });
  });

  test('a new size serializes its nested measurements', () {
    final request = mappr.convert<NewSizeItem, ProductSizeDraftDto>(
      const NewSizeItem(
        name: 'M',
        garmentMeasurements: GarmentMeasurements(chestCircumference: 96),
      ),
    );

    expect(request.toJson(), {
      'name': 'M',
      'garment_measurements': {'chest_circumference': 96.0},
      'body_measurement_ranges': null,
    });
  });

  test('a size create request flattens the size into the product row', () {
    const request = CreateProductSizeRequest(
      productId: 'p1',
      size: ProductSizeDraftDto(name: 'M'),
    );

    expect(request.toJson(), {
      'product_id': 'p1',
      'name': 'M',
      'garment_measurements': null,
      'body_measurement_ranges': null,
    });
  });
}
