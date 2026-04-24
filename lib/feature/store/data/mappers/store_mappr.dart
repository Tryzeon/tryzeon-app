import 'package:auto_mappr_annotation/auto_mappr_annotation.dart';

import '../../../../core/shared/measurements/data/mappers/measurements_mappr.dart';
import '../../../../feature/personal/profile/domain/entities/clothing_style.dart';
import '../../../../feature/store/products/domain/value_objects/product_attributes.dart';
import '../../analytics/data/collections/product_analytics_collection.dart';
import '../../analytics/data/models/product_analytics_summary_model.dart';
import '../../analytics/domain/entities/product_analytics_summary.dart';
import '../../products/data/collections/product_collection.dart';
import '../../products/data/models/product_model.dart';
import '../../products/domain/entities/product.dart';
import '../../profile/data/collections/store_profile_collection.dart';
import '../../profile/data/models/store_profile_model.dart';
import '../../profile/domain/entities/store_profile.dart';
import 'store_mappr.auto_mappr.dart';

/// AutoMappr configuration for Store feature
@AutoMappr(
  [
    // ProductSize mappings
    MapType<ProductSizeModel, ProductSize>(),
    MapType<ProductSize, ProductSizeModel>(),
    MapType<ProductSizeModel, ProductSizeCollection>(),
    MapType<ProductSizeCollection, ProductSizeModel>(),

    // Product mappings (String ↔ Enum conversion only at Model ↔ Entity boundary)
    MapType<ProductModel, Product>(
      fields: [
        Field('elasticity', custom: StoreMapprHelper.stringToElasticity),
        Field('fit', custom: StoreMapprHelper.stringToFit),
        Field('thickness', custom: StoreMapprHelper.stringToThickness),
        Field('styles', custom: StoreMapprHelper.stringsToStyles),
      ],
    ),
    MapType<Product, ProductModel>(
      fields: [
        Field('elasticity', custom: StoreMapprHelper.elasticityToString),
        Field('fit', custom: StoreMapprHelper.fitToString),
        Field('thickness', custom: StoreMapprHelper.thicknessToString),
        Field('styles', custom: StoreMapprHelper.stylesToStrings),
      ],
    ),

    // Collection mappings (String ↔ String, only field name mapping needed)
    MapType<ProductModel, ProductCollection>(fields: [Field('productId', from: 'id')]),
    MapType<ProductCollection, ProductModel>(fields: [Field('id', from: 'productId')]),

    // StoreProfile mappings
    MapType<StoreProfileModel, StoreProfile>(),
    MapType<StoreProfile, StoreProfileModel>(),
    MapType<StoreProfileModel, StoreProfileCollection>(
      fields: [Field('storeId', from: 'id')],
    ),
    MapType<StoreProfileCollection, StoreProfileModel>(
      fields: [Field('id', from: 'storeId')],
    ),

    // ProductAnalyticsSummary mappings
    MapType<ProductAnalyticsSummaryModel, ProductAnalyticsSummary>(),
    MapType<ProductAnalyticsSummaryModel, ProductAnalyticsCollection>(),
    MapType<ProductAnalyticsCollection, ProductAnalyticsSummaryModel>(),
  ],
  includes: [MeasurementsMappr()],
)
class StoreMappr extends $StoreMappr {
  const StoreMappr();
}

class StoreMapprHelper {
  // String to Enum conversions
  static ProductElasticity? stringToElasticity(final ProductModel source) =>
      ProductElasticity.tryFromString(source.elasticity);

  static ProductFit? stringToFit(final ProductModel source) =>
      ProductFit.tryFromString(source.fit);

  static ProductThickness? stringToThickness(final ProductModel source) =>
      ProductThickness.tryFromString(source.thickness);

  static List<ClothingStyle>? stringsToStyles(final ProductModel source) =>
      source.styles?.map(ClothingStyle.tryFromString).whereType<ClothingStyle>().toList();

  // Enum to String conversions
  static String? elasticityToString(final Product source) => source.elasticity?.value;

  static String? fitToString(final Product source) => source.fit?.value;

  static String? thicknessToString(final Product source) => source.thickness?.value;

  static List<String>? stylesToStrings(final Product source) =>
      source.styles?.map((final e) => e.value).toList();
}
