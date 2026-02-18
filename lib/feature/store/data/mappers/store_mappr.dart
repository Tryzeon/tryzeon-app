import 'package:auto_mappr_annotation/auto_mappr_annotation.dart';

import '../../../../core/shared/measurements/collections/size_measurements_collection.dart';
import '../../../../core/shared/measurements/data/models/size_measurements_model.dart';
import '../../../../core/shared/measurements/entities/size_measurements.dart';
import '../../analytics/data/collections/store_analytics_collection.dart';
import '../../analytics/data/models/store_analytics_summary_model.dart';
import '../../analytics/domain/entities/store_analytics_summary.dart';
import '../../products/data/collections/product_collection.dart';
import '../../products/data/models/product_model.dart';
import '../../products/domain/entities/product.dart';
import '../../profile/data/collections/store_profile_collection.dart';
import '../../profile/data/models/store_profile_model.dart';
import '../../profile/domain/entities/store_profile.dart';
import 'store_mappr.auto_mappr.dart';

/// AutoMappr configuration for Store feature
/// Handles Product, StoreProfile, and StoreAnalyticsSummary mappings
@AutoMappr([
  // SizeMeasurements mappings (needed for ProductSize.measurements)
  MapType<SizeMeasurementsModel, SizeMeasurements>(),
  MapType<SizeMeasurements, SizeMeasurementsModel>(),
  MapType<SizeMeasurementsModel, SizeMeasurementsCollection>(),
  MapType<SizeMeasurementsCollection, SizeMeasurementsModel>(),

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

  // StoreAnalyticsSummary mappings
  MapType<StoreAnalyticsSummaryModel, StoreAnalyticsSummary>(),
  MapType<StoreAnalyticsCollection, StoreAnalyticsSummaryModel>(),
  MapType<StoreAnalyticsSummaryModel, StoreAnalyticsCollection>(),
])
class StoreMappr extends $StoreMappr {
  const StoreMappr();
}
