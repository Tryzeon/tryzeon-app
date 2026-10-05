import 'package:flutter_test/flutter_test.dart';
import 'package:tryzeon/core/data/services/store_images_api.dart';
import 'package:tryzeon/feature/store/data/mappers/store_mappr.dart';
import 'package:tryzeon/feature/store/product/data/dtos/product_dto.dart';
import 'package:tryzeon/feature/store/product/domain/entities/product.dart';
import 'package:tryzeon/feature/store/profile/data/collections/store_profile_cache.dart';
import 'package:tryzeon/feature/store/profile/data/dtos/store_profile_dto.dart';
import 'package:tryzeon/feature/store/profile/domain/entities/store_profile.dart';

void main() {
  const mappr = StoreMappr();

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

  Map<String, dynamic> profileRow({final String? logoPath}) => {
    'id': 's1',
    'owner_id': 'u1',
    'name': '小店',
    'channels': const <String>[],
    'logo_path': logoPath,
    'created_at': '2026-01-01T00:00:00Z',
    'updated_at': '2026-01-01T00:00:00Z',
  };

  test('product image URLs are derived from image paths', () {
    final product = mappr.convert<ProductDto, Product>(
      ProductDto.fromJson(productRow(imagePaths: ['p1/a.jpg'])),
    );

    expect(product.imageUrls, [StoreImagesApi.publicUrl('p1/a.jpg')]);
  });

  test('a null image_paths column decodes as no images', () {
    final product = mappr.convert<ProductDto, Product>(
      ProductDto.fromJson(productRow()),
    );

    expect(product.imagePaths, isEmpty);
    expect(product.imageUrls, isEmpty);
  });

  test('store logo URL is derived from the logo path', () {
    final profile = mappr.convert<StoreProfileDto, StoreProfile>(
      StoreProfileDto.fromJson(profileRow(logoPath: 's1/logo.png')),
    );

    expect(profile.logoUrl, StoreImagesApi.publicUrl('s1/logo.png'));
  });

  test('a blank logo path yields no logo URL', () {
    final fromDto = mappr.convert<StoreProfileDto, StoreProfile>(
      StoreProfileDto.fromJson(profileRow(logoPath: '')),
    );
    final fromCache = mappr.convert<StoreProfileCache, StoreProfile>(
      StoreProfileCache()
        ..storeId = 's1'
        ..ownerId = 'u1'
        ..name = '小店'
        ..channels = []
        ..createdAt = DateTime(2026)
        ..updatedAt = DateTime(2026),
    );

    expect(fromDto.logoUrl, isNull);
    expect(fromCache.logoUrl, isNull);
  });

  test('entity to DTO serializes the path, never a URL', () {
    final profile = mappr.convert<StoreProfileDto, StoreProfile>(
      StoreProfileDto.fromJson(profileRow(logoPath: 's1/logo.png')),
    );

    final json = mappr.convert<StoreProfile, StoreProfileDto>(profile).toJson();

    expect(json['logo_path'], 's1/logo.png');
    expect(json.containsKey('logo_url'), isFalse);
  });
}
