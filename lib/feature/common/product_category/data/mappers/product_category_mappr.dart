import 'package:auto_mappr_annotation/auto_mappr_annotation.dart';
import 'package:tryzeon/core/utils/public_image_url.dart';
import 'package:tryzeon/feature/common/garment_type/data/mappers/garment_type_cache_converters.dart';
import 'package:tryzeon/feature/common/garment_type/domain/entities/garment_type.dart';
import 'package:tryzeon/feature/common/product_attributes/data/mappers/product_attributes_cache_converters.dart';
import 'package:tryzeon/feature/common/product_attributes/domain/entities/product_attributes.dart';
import 'package:tryzeon/feature/common/product_category/data/collections/product_category_cache.dart';
import 'package:tryzeon/feature/common/product_category/data/dtos/product_category_dto.dart';
import 'package:tryzeon/feature/common/product_category/data/mappers/product_category_mappr.auto_mappr.dart';
import 'package:tryzeon/feature/common/product_category/domain/entities/product_category.dart';

@AutoMappr([
  MapType<ProductCategoryDto, ProductCategory>(
    fields: [
      Field('gender', custom: ProductCategoryMapprHelper.genderFromDto),
      Field(
        'imageMaleUrl',
        custom: ProductCategoryMapprHelper.imageMaleUrlFromDto,
      ),
      Field(
        'imageFemaleUrl',
        custom: ProductCategoryMapprHelper.imageFemaleUrlFromDto,
      ),
    ],
  ),
  MapType<ProductCategory, ProductCategoryCache>(
    fields: [Field('categoryId', from: 'id')],
    converters: [
      TypeConverter<GarmentType, String>(GarmentTypeCacheConverters.toCache),
      TypeConverter<ProductGender?, String?>(
        ProductAttributesCacheConverters.genderToCache,
      ),
    ],
  ),
  MapType<ProductCategoryCache, ProductCategory>(
    fields: [
      Field('id', from: 'categoryId'),
      Field('gender', custom: ProductCategoryMapprHelper.genderFromCache),
    ],
    converters: [
      TypeConverter<String, GarmentType>(GarmentTypeCacheConverters.fromCache),
    ],
  ),
])
class ProductCategoryMappr extends $ProductCategoryMappr {
  const ProductCategoryMappr();
}

class ProductCategoryMapprHelper {
  static ProductGender genderFromDto(final ProductCategoryDto source) =>
      source.gender ?? ProductGender.unisex;

  static String? imageMaleUrlFromDto(final ProductCategoryDto source) =>
      PublicImageUrl.ofOrNull(source.imageMale);

  static String? imageFemaleUrlFromDto(final ProductCategoryDto source) =>
      PublicImageUrl.ofOrNull(source.imageFemale);

  static ProductGender genderFromCache(final ProductCategoryCache source) =>
      ProductAttributesCacheConverters.genderFromCache(source.gender) ??
      ProductGender.unisex;
}
