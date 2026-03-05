import 'package:auto_mappr_annotation/auto_mappr_annotation.dart';

import '../../../../core/shared/measurements/data/mappers/measurements_mappr.dart';
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
/// Handles Product, StoreProfile, and ProductAnalyticsSummary mappings
/// Note: Measurements mappings are included via MeasurementsMappr
@AutoMappr(
  [
    // ProductSize nested object mappings
    MapType<ProductSizeModel, ProductSize>(),
    MapType<ProductSize, ProductSizeModel>(),
    MapType<ProductSizeModel, ProductSizeCollection>(),
    MapType<ProductSizeCollection, ProductSizeModel>(),

    // Product mappings
    MapType<ProductModel, Product>(),
    MapType<Product, ProductModel>(),
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
