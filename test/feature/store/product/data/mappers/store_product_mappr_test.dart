import 'package:flutter_test/flutter_test.dart';
import 'package:tryzeon/core/utils/public_image_url.dart';
import 'package:tryzeon/feature/common/garment_type/domain/entities/garment_type.dart';
import 'package:tryzeon/feature/common/product_attributes/domain/entities/product_attributes.dart';
import 'package:tryzeon/feature/store/product/data/collections/product_cache.dart';
import 'package:tryzeon/feature/store/product/data/dtos/create_product_request.dart';
import 'package:tryzeon/feature/store/product/data/dtos/create_product_size_request.dart';
import 'package:tryzeon/feature/store/product/data/dtos/product_analysis_result_dto.dart';
import 'package:tryzeon/feature/store/product/data/dtos/product_dto.dart';
import 'package:tryzeon/feature/store/product/data/dtos/product_size_draft_dto.dart';
import 'package:tryzeon/feature/store/product/data/mappers/create_product_color_requests.dart';
import 'package:tryzeon/feature/store/product/data/mappers/store_product_mappr.dart';
import 'package:tryzeon/feature/store/product/domain/entities/product.dart';
import 'package:tryzeon/feature/store/product/domain/entities/product_analysis_result.dart';
import 'package:tryzeon/feature/store/product/domain/value_objects/size_item.dart';

void main() {
  const mappr = StoreProductMappr();

  Map<String, dynamic> colorRow({
    required final String id,
    required final int position,
    required final List<String> imagePaths,
  }) => {
    'id': id,
    'product_id': 'p1',
    'store_id': 's1',
    'name': null,
    'image_paths': imagePaths,
    'position': position,
    'created_at': '2026-01-01T00:00:00Z',
    'updated_at': '2026-01-01T00:00:00Z',
  };

  Map<String, dynamic> productRow({final List<Map<String, dynamic>>? colors}) =>
      {
        'id': 'p1',
        'store_id': 's1',
        'name': '碎花洋裝',
        'category_id': 'c1',
        'garment_type': 'one_piece',
        'price': 1280,
        'product_colors': colors,
        'created_at': '2026-01-01T00:00:00Z',
        'updated_at': '2026-01-01T00:00:00Z',
      };

  test('embedded colours keep the queried order and gain image URLs', () {
    final product = mappr.convert<ProductDto, Product>(
      ProductDto.fromJson(
        productRow(
          colors: [
            colorRow(id: 'navy', position: 1, imagePaths: ['p1/navy.jpg']),
            colorRow(id: 'black', position: 0, imagePaths: ['p1/black.jpg']),
          ],
        ),
      ),
    );

    expect(product.colors.map((final c) => c.id), ['navy', 'black']);
    expect(product.colors.first.imageUrls, [PublicImageUrl.of('p1/navy.jpg')]);
  });

  test('a row without embedded colours decodes as no colours', () {
    final product = mappr.convert<ProductDto, Product>(
      ProductDto.fromJson(productRow()),
    );

    expect(product.colors, isEmpty);
  });

  test('colours survive a round trip through the cache', () {
    final product = mappr.convert<ProductDto, Product>(
      ProductDto.fromJson(
        productRow(
          colors: [
            colorRow(id: 'black', position: 0, imagePaths: ['p1/black.jpg']),
            colorRow(id: 'navy', position: 1, imagePaths: ['p1/navy.jpg']),
          ],
        ),
      ),
    );

    final cached = mappr.convert<Product, ProductCache>(product);

    expect(mappr.convert<ProductCache, Product>(cached), product);
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
      isNot(
        anyOf(
          contains('id'),
          contains('store_id'),
          contains('image_paths'),
          contains('product_colors'),
        ),
      ),
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
        colors: [
          NewProductColor(imagePaths: ['p1.jpg']),
        ],
        sizes: [],
      ),
    );

    expect(request.toJson(), {
      'id': 'p1',
      'store_id': 's1',
      'name': '碎花洋裝',
      'category_id': 'c1',
      'garment_type': 'one_piece',
      'price': 1280.0,
      'gender': 'unisex',
      'status': 'active',
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

  test('a new product saved unlisted sends its status', () {
    final request = mappr.convert<NewProduct, CreateProductRequest>(
      const NewProduct(
        id: 'p1',
        storeId: 's1',
        draft: ProductDraft(
          name: '碎花洋裝',
          categoryId: 'c1',
          garmentType: GarmentType.onePiece,
          price: 1280,
          status: ProductStatus.archived,
        ),
        colors: [
          NewProductColor(imagePaths: ['p1.jpg']),
        ],
        sizes: [],
      ),
    );

    expect(request.toJson()['status'], 'archived');
  });

  test("a new product's colours become insert rows numbered by order", () {
    final requests = toCreateProductColorRequests(
      const NewProduct(
        id: 'p1',
        storeId: 's1',
        draft: ProductDraft(
          name: '碎花洋裝',
          categoryId: 'c1',
          garmentType: GarmentType.onePiece,
          price: 1280,
        ),
        colors: [
          NewProductColor(name: '黑', imagePaths: ['p1/black.jpg']),
          NewProductColor(imagePaths: ['p1/navy.jpg']),
        ],
        sizes: [],
      ),
    );

    expect(requests.map((final r) => r.toJson()), [
      {
        'product_id': 'p1',
        'store_id': 's1',
        'name': '黑',
        'image_paths': ['p1/black.jpg'],
        'position': 0,
      },
      {
        'product_id': 'p1',
        'store_id': 's1',
        'name': null,
        'image_paths': ['p1/navy.jpg'],
        'position': 1,
      },
    ]);
  });

  test('an analysis result carries the inferred colour', () {
    final result = mappr
        .convert<ProductAnalysisResultDto, ProductAnalysisResult>(
          ProductAnalysisResultDto.fromJson(const {
            'color': '霧灰',
            'styles': <String>[],
            'seasons': <String>[],
          }),
        );

    expect(result.color, '霧灰');
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
