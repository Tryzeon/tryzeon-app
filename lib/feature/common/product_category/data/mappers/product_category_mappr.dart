import 'package:auto_mappr_annotation/auto_mappr_annotation.dart';
import 'package:tryzeon/core/data/cache/cached_enum_converters.dart';
import 'package:tryzeon/feature/common/garment_type/domain/entities/garment_type.dart';
import 'package:tryzeon/feature/common/product_attributes/domain/entities/product_attributes.dart';

import '../../domain/entities/product_category.dart';
import '../collections/product_category_cache.dart';
import '../models/product_category_model.dart';
import 'product_category_mappr.auto_mappr.dart';

@AutoMappr([
  MapType<ProductCategoryModel, ProductCategory>(
    fields: [Field('gender', custom: ProductCategoryMapprHelper.genderToEntity)],
  ),
  MapType<ProductCategoryModel, ProductCategoryCache>(
    fields: [Field('categoryId', from: 'id')],
    converters: [
      TypeConverter<GarmentType, String>(CachedEnumConverters.garmentTypeToCache),
      TypeConverter<ProductGender?, String?>(
        CachedEnumConverters.productGenderToCache,
      ),
    ],
  ),
  MapType<ProductCategoryCache, ProductCategoryModel>(
    fields: [Field('id', from: 'categoryId')],
    converters: [
      TypeConverter<String, GarmentType>(CachedEnumConverters.garmentTypeFromCache),
      TypeConverter<String?, ProductGender?>(
        CachedEnumConverters.productGenderFromCache,
      ),
    ],
  ),
])
class ProductCategoryMappr extends $ProductCategoryMappr {
  const ProductCategoryMappr();
}

class ProductCategoryMapprHelper {
  static ProductGender genderToEntity(final ProductCategoryModel source) =>
      source.gender ?? ProductGender.unisex;
}
