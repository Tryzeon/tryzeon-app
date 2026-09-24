import 'package:auto_mappr_annotation/auto_mappr_annotation.dart';
import 'package:tryzeon/core/data/cache/cached_enum_converters.dart';
import 'package:tryzeon/feature/common/garment_type/domain/entities/garment_type.dart';
import 'package:tryzeon/feature/common/store/data/collections/store_order_contact_embedded.dart';
import 'package:tryzeon/feature/common/store/data/models/store_order_contact_model.dart';
import 'package:tryzeon/feature/common/store/domain/entities/store_channel.dart';
import 'package:tryzeon/feature/common/store/domain/entities/store_order_contact.dart';

import '../../../../feature/common/clothing_style/domain/entities/clothing_style.dart';
import '../../../../feature/common/product_attributes/domain/entities/product_attributes.dart';
import '../../../../feature/common/product_size/data/collections/product_size_embedded.dart';
import '../../../../feature/common/product_size/data/mappers/body_measurement_ranges_mappr.dart';
import '../../../../feature/common/product_size/data/mappers/garment_measurements_mappr.dart';
import '../../analytics/data/collections/product_analytics_cache.dart';
import '../../analytics/data/models/product_analytics_summary_model.dart';
import '../../analytics/domain/entities/product_analytics_summary.dart';
import '../../product/data/collections/product_cache.dart';
import '../../product/data/models/product_model.dart';
import '../../product/domain/entities/product.dart';
import '../../profile/data/collections/store_profile_cache.dart';
import '../../profile/data/models/store_profile_model.dart';
import '../../profile/domain/entities/store_profile.dart';
import 'store_mappr.auto_mappr.dart';

@AutoMappr(
  [
    MapType<ProductSizeModel, ProductSize>(),
    MapType<ProductSize, ProductSizeModel>(),
    MapType<ProductSizeModel, ProductSizeEmbedded>(),
    MapType<ProductSizeEmbedded, ProductSizeModel>(),

    MapType<ProductModel, Product>(
      fields: [
        Field('status', custom: StoreMapprHelper.statusToEntity),
        Field('gender', custom: StoreMapprHelper.genderToEntity),
        Field('styles', custom: StoreMapprHelper.stylesToEntity),
        Field('seasons', custom: StoreMapprHelper.seasonsToEntity),
      ],
    ),
    MapType<Product, ProductModel>(
      fields: [
        Field('styles', custom: StoreMapprHelper.stylesToModel),
        Field('seasons', custom: StoreMapprHelper.seasonsToModel),
      ],
    ),

    MapType<ProductModel, ProductCache>(
      fields: [Field('productId', from: 'id')],
      converters: [
        TypeConverter<GarmentType, String>(CachedEnumConverters.garmentTypeToCache),
        TypeConverter<ProductStatus?, String?>(CachedEnumConverters.productStatusToCache),
        TypeConverter<ProductGender?, String?>(CachedEnumConverters.productGenderToCache),
        TypeConverter<ProductElasticity?, String?>(
          CachedEnumConverters.productElasticityToCache,
        ),
        TypeConverter<ProductFit?, String?>(CachedEnumConverters.productFitToCache),
        TypeConverter<ProductThickness?, String?>(
          CachedEnumConverters.productThicknessToCache,
        ),
        TypeConverter<List<ClothingStyle>?, List<String>?>(
          CachedEnumConverters.clothingStylesToCache,
        ),
        TypeConverter<List<ProductSeason>?, List<String>?>(
          CachedEnumConverters.productSeasonsToCache,
        ),
      ],
    ),
    MapType<ProductCache, ProductModel>(
      fields: [Field('id', from: 'productId')],
      converters: [
        TypeConverter<String, GarmentType>(CachedEnumConverters.garmentTypeFromCache),
        TypeConverter<String?, ProductStatus?>(
          CachedEnumConverters.productStatusFromCache,
        ),
        TypeConverter<String?, ProductGender?>(
          CachedEnumConverters.productGenderFromCache,
        ),
        TypeConverter<String?, ProductElasticity?>(
          CachedEnumConverters.productElasticityFromCache,
        ),
        TypeConverter<String?, ProductFit?>(CachedEnumConverters.productFitFromCache),
        TypeConverter<String?, ProductThickness?>(
          CachedEnumConverters.productThicknessFromCache,
        ),
        TypeConverter<List<String>?, List<ClothingStyle>?>(
          CachedEnumConverters.clothingStylesFromCache,
        ),
        TypeConverter<List<String>?, List<ProductSeason>?>(
          CachedEnumConverters.productSeasonsFromCache,
        ),
      ],
    ),

    MapType<StoreOrderContactModel, StoreOrderContact>(),
    MapType<StoreOrderContact, StoreOrderContactModel>(),
    MapType<StoreOrderContactModel, StoreOrderContactEmbedded>(
      converters: [
        TypeConverter<OrderContactType, String>(
          CachedEnumConverters.orderContactTypeToCache,
        ),
      ],
    ),
    MapType<StoreOrderContactEmbedded, StoreOrderContactModel>(
      converters: [
        TypeConverter<String, OrderContactType>(
          CachedEnumConverters.orderContactTypeFromCache,
        ),
      ],
    ),

    MapType<StoreProfileModel, StoreProfile>(
      fields: [Field('channels', custom: StoreMapprHelper.channelsToEntity)],
    ),
    MapType<StoreProfile, StoreProfileModel>(
      fields: [Field('channels', custom: StoreMapprHelper.channelsToModel)],
    ),
    MapType<StoreProfileModel, StoreProfileCache>(
      fields: [Field('storeId', from: 'id')],
      converters: [
        TypeConverter<List<StoreChannel>, List<String>>(
          CachedEnumConverters.storeChannelsToCache,
        ),
      ],
    ),
    MapType<StoreProfileCache, StoreProfileModel>(
      fields: [Field('id', from: 'storeId')],
      converters: [
        TypeConverter<List<String>, List<StoreChannel>>(
          CachedEnumConverters.storeChannelsFromCache,
        ),
      ],
    ),

    MapType<ProductAnalyticsSummaryModel, ProductAnalyticsSummary>(),
    MapType<ProductAnalyticsSummaryModel, ProductAnalyticsCache>(),
    MapType<ProductAnalyticsCache, ProductAnalyticsSummaryModel>(),
  ],
  includes: [GarmentMeasurementsMappr(), BodyMeasurementRangesMappr()],
)
class StoreMappr extends $StoreMappr {
  const StoreMappr();
}

class StoreMapprHelper {
  static ProductStatus statusToEntity(final ProductModel source) =>
      source.status ?? ProductStatus.active;

  static ProductGender genderToEntity(final ProductModel source) =>
      source.gender ?? ProductGender.unisex;

  static Set<ClothingStyle>? stylesToEntity(final ProductModel source) =>
      source.styles?.toSet();

  static Set<ProductSeason>? seasonsToEntity(final ProductModel source) =>
      source.seasons?.toSet();

  static List<ClothingStyle>? stylesToModel(final Product source) {
    final styles = source.styles;
    return styles == null ? null : ClothingStyle.listFromSet(styles);
  }

  static List<ProductSeason>? seasonsToModel(final Product source) {
    final seasons = source.seasons;
    return seasons == null ? null : ProductSeason.listFromSet(seasons);
  }

  static Set<StoreChannel> channelsToEntity(final StoreProfileModel source) =>
      source.channels.toSet();

  static List<StoreChannel> channelsToModel(final StoreProfile source) =>
      StoreChannel.listFromSet(source.channels);
}
