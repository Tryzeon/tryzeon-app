import 'package:auto_mappr_annotation/auto_mappr_annotation.dart';
import 'package:tryzeon/feature/common/clothing_style/data/mappers/clothing_style_cache_converters.dart';
import 'package:tryzeon/feature/common/garment_type/data/mappers/garment_type_cache_converters.dart';
import 'package:tryzeon/feature/common/garment_type/domain/entities/garment_type.dart';
import 'package:tryzeon/feature/common/product_attributes/data/mappers/product_attributes_cache_converters.dart';
import 'package:tryzeon/feature/common/store/data/collections/store_order_contact_embedded.dart';
import 'package:tryzeon/feature/common/store/data/dtos/store_order_contact_dto.dart';
import 'package:tryzeon/feature/common/store/data/mappers/store_enum_cache_converters.dart';
import 'package:tryzeon/feature/common/store/domain/entities/store_channel.dart';
import 'package:tryzeon/feature/common/store/domain/entities/store_order_contact.dart';

import '../../../../feature/common/clothing_style/domain/entities/clothing_style.dart';
import '../../../../feature/common/product_attributes/domain/entities/product_attributes.dart';
import '../../../../feature/common/product_size/data/collections/product_size_embedded.dart';
import '../../../../feature/common/product_size/data/mappers/body_measurement_ranges_mappr.dart';
import '../../../../feature/common/product_size/data/mappers/garment_measurements_mappr.dart';
import '../../analytics/data/collections/product_analytics_cache.dart';
import '../../analytics/data/dtos/product_analytics_summary_dto.dart';
import '../../analytics/domain/entities/product_analytics_summary.dart';
import '../../product/data/collections/product_cache.dart';
import '../../product/data/dtos/product_dto.dart';
import '../../product/domain/entities/product.dart';
import '../../profile/data/collections/store_profile_cache.dart';
import '../../profile/data/dtos/store_profile_dto.dart';
import '../../profile/domain/entities/store_profile.dart';
import 'store_mappr.auto_mappr.dart';

@AutoMappr(
  [
    MapType<ProductSizeDto, ProductSize>(),
    MapType<ProductSize, ProductSizeDto>(),
    MapType<ProductSizeDto, ProductSizeEmbedded>(),
    MapType<ProductSizeEmbedded, ProductSizeDto>(),

    MapType<ProductDto, Product>(
      fields: [
        Field('status', custom: StoreMapprHelper.statusToEntity),
        Field('gender', custom: StoreMapprHelper.genderToEntity),
        Field('styles', custom: StoreMapprHelper.stylesToEntity),
        Field('seasons', custom: StoreMapprHelper.seasonsToEntity),
      ],
    ),
    MapType<Product, ProductDto>(
      fields: [
        Field('styles', custom: StoreMapprHelper.stylesToDto),
        Field('seasons', custom: StoreMapprHelper.seasonsToDto),
      ],
    ),

    MapType<ProductDto, ProductCache>(
      fields: [Field('productId', from: 'id')],
      converters: [
        TypeConverter<GarmentType, String>(GarmentTypeCacheConverters.toCache),
        TypeConverter<ProductStatus?, String?>(
          ProductAttributesCacheConverters.statusToCache,
        ),
        TypeConverter<ProductGender?, String?>(
          ProductAttributesCacheConverters.genderToCache,
        ),
        TypeConverter<ProductElasticity?, String?>(
          ProductAttributesCacheConverters.elasticityToCache,
        ),
        TypeConverter<ProductFit?, String?>(ProductAttributesCacheConverters.fitToCache),
        TypeConverter<ProductThickness?, String?>(
          ProductAttributesCacheConverters.thicknessToCache,
        ),
        TypeConverter<List<ClothingStyle>?, List<String>?>(
          ClothingStyleCacheConverters.listToCache,
        ),
        TypeConverter<List<ProductSeason>?, List<String>?>(
          ProductAttributesCacheConverters.seasonsToCache,
        ),
      ],
    ),
    MapType<ProductCache, ProductDto>(
      fields: [Field('id', from: 'productId')],
      converters: [
        TypeConverter<String, GarmentType>(GarmentTypeCacheConverters.fromCache),
        TypeConverter<String?, ProductStatus?>(
          ProductAttributesCacheConverters.statusFromCache,
        ),
        TypeConverter<String?, ProductGender?>(
          ProductAttributesCacheConverters.genderFromCache,
        ),
        TypeConverter<String?, ProductElasticity?>(
          ProductAttributesCacheConverters.elasticityFromCache,
        ),
        TypeConverter<String?, ProductFit?>(
          ProductAttributesCacheConverters.fitFromCache,
        ),
        TypeConverter<String?, ProductThickness?>(
          ProductAttributesCacheConverters.thicknessFromCache,
        ),
        TypeConverter<List<String>?, List<ClothingStyle>?>(
          ClothingStyleCacheConverters.listFromCache,
        ),
        TypeConverter<List<String>?, List<ProductSeason>?>(
          ProductAttributesCacheConverters.seasonsFromCache,
        ),
      ],
    ),

    MapType<StoreOrderContactDto, StoreOrderContact>(),
    MapType<StoreOrderContact, StoreOrderContactDto>(),
    MapType<StoreOrderContactDto, StoreOrderContactEmbedded>(
      converters: [
        TypeConverter<OrderContactType, String>(
          StoreEnumCacheConverters.orderContactTypeToCache,
        ),
      ],
    ),
    MapType<StoreOrderContactEmbedded, StoreOrderContactDto>(
      converters: [
        TypeConverter<String, OrderContactType>(
          StoreEnumCacheConverters.orderContactTypeFromCache,
        ),
      ],
    ),

    MapType<StoreProfileDto, StoreProfile>(
      fields: [Field('channels', custom: StoreMapprHelper.channelsToEntity)],
    ),
    MapType<StoreProfile, StoreProfileDto>(
      fields: [Field('channels', custom: StoreMapprHelper.channelsToDto)],
    ),
    MapType<StoreProfileDto, StoreProfileCache>(
      fields: [Field('storeId', from: 'id')],
      converters: [
        TypeConverter<List<StoreChannel>, List<String>>(
          StoreEnumCacheConverters.channelsToCache,
        ),
      ],
    ),
    MapType<StoreProfileCache, StoreProfileDto>(
      fields: [Field('id', from: 'storeId')],
      converters: [
        TypeConverter<List<String>, List<StoreChannel>>(
          StoreEnumCacheConverters.channelsFromCache,
        ),
      ],
    ),

    MapType<ProductAnalyticsSummaryDto, ProductAnalyticsSummary>(),
    MapType<ProductAnalyticsSummaryDto, ProductAnalyticsCache>(),
    MapType<ProductAnalyticsCache, ProductAnalyticsSummaryDto>(),
  ],
  includes: [GarmentMeasurementsMappr(), BodyMeasurementRangesMappr()],
)
class StoreMappr extends $StoreMappr {
  const StoreMappr();
}

class StoreMapprHelper {
  static ProductStatus statusToEntity(final ProductDto source) =>
      source.status ?? ProductStatus.active;

  static ProductGender genderToEntity(final ProductDto source) =>
      source.gender ?? ProductGender.unisex;

  static Set<ClothingStyle>? stylesToEntity(final ProductDto source) =>
      source.styles?.toSet();

  static Set<ProductSeason>? seasonsToEntity(final ProductDto source) =>
      source.seasons?.toSet();

  static List<ClothingStyle>? stylesToDto(final Product source) {
    final styles = source.styles;
    return styles == null ? null : ClothingStyle.listFromSet(styles);
  }

  static List<ProductSeason>? seasonsToDto(final Product source) {
    final seasons = source.seasons;
    return seasons == null ? null : ProductSeason.listFromSet(seasons);
  }

  static Set<StoreChannel> channelsToEntity(final StoreProfileDto source) =>
      source.channels.toSet();

  static List<StoreChannel> channelsToDto(final StoreProfile source) =>
      StoreChannel.listFromSet(source.channels);
}
