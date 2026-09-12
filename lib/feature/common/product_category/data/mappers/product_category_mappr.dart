import 'package:auto_mappr_annotation/auto_mappr_annotation.dart';
import 'package:tryzeon/feature/common/garment_type/domain/entities/garment_type.dart';
import 'package:tryzeon/feature/common/product_attributes/domain/entities/product_attributes.dart';

import '../../domain/entities/product_category.dart';
import '../collections/product_category_cache.dart';
import '../models/product_category_model.dart';
import 'product_category_mappr.auto_mappr.dart';

@AutoMappr([
  MapType<ProductCategoryModel, ProductCategory>(
    fields: [
      Field(
        'defaultGarmentType',
        custom: ProductCategoryMapprHelper.stringToDefaultGarmentType,
      ),
      Field('gender', custom: ProductCategoryMapprHelper.stringToGender),
    ],
  ),
  MapType<ProductCategoryModel, ProductCategoryCache>(
    fields: [Field('categoryId', from: 'id')],
  ),
  MapType<ProductCategoryCache, ProductCategoryModel>(
    fields: [Field('id', from: 'categoryId')],
  ),
])
class ProductCategoryMappr extends $ProductCategoryMappr {
  const ProductCategoryMappr();
}

class ProductCategoryMapprHelper {
  static GarmentType stringToDefaultGarmentType(final ProductCategoryModel source) =>
      GarmentType.tryFromString(source.defaultGarmentType) ?? GarmentType.others;

  static ProductGender stringToGender(final ProductCategoryModel source) =>
      ProductGender.tryFromString(source.gender) ?? ProductGender.unisex;
}
