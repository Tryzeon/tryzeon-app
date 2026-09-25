import 'package:auto_mappr_annotation/auto_mappr_annotation.dart';
import 'package:tryzeon/core/data/services/store_images_api.dart';
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
    MapType<ProductSize, ProductSizeEmbedded>(),
    MapType<ProductSizeEmbedded, ProductSize>(),

    MapType<ProductDto, Product>(
      fields: [
        Field('imageUrls', custom: StoreMapprHelper.imageUrlsFromDto),
        Field('status', custom: StoreMapprHelper.statusFromDto),
        Field('gender', custom: StoreMapprHelper.genderFromDto),
        Field('styles', custom: StoreMapprHelper.stylesFromDto),
        Field('seasons', custom: StoreMapprHelper.seasonsFromDto),
      ],
    ),
    MapType<Product, ProductDto>(
      fields: [
        Field('styles', custom: StoreMapprHelper.stylesToDto),
        Field('seasons', custom: StoreMapprHelper.seasonsToDto),
      ],
    ),

    MapType<Product, ProductCache>(
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
        TypeConverter<Set<ClothingStyle>?, List<String>?>(
          ClothingStyleCacheConverters.setToCache,
        ),
        TypeConverter<Set<ProductSeason>?, List<String>?>(
          ProductAttributesCacheConverters.seasonsToCache,
        ),
      ],
    ),
    MapType<ProductCache, Product>(
      fields: [
        Field('id', from: 'productId'),
        Field('imageUrls', custom: StoreMapprHelper.imageUrlsFromCache),
        Field('status', custom: StoreMapprHelper.statusFromCache),
        Field('gender', custom: StoreMapprHelper.genderFromCache),
      ],
      converters: [
        TypeConverter<String, GarmentType>(GarmentTypeCacheConverters.fromCache),
        TypeConverter<String?, ProductElasticity?>(
          ProductAttributesCacheConverters.elasticityFromCache,
        ),
        TypeConverter<String?, ProductFit?>(
          ProductAttributesCacheConverters.fitFromCache,
        ),
        TypeConverter<String?, ProductThickness?>(
          ProductAttributesCacheConverters.thicknessFromCache,
        ),
        TypeConverter<List<String>?, Set<ClothingStyle>?>(
          ClothingStyleCacheConverters.setFromCache,
        ),
        TypeConverter<List<String>?, Set<ProductSeason>?>(
          ProductAttributesCacheConverters.seasonsFromCache,
        ),
      ],
    ),

    MapType<StoreOrderContactDto, StoreOrderContact>(),
    MapType<StoreOrderContact, StoreOrderContactDto>(),
    MapType<StoreOrderContact, StoreOrderContactEmbedded>(
      converters: [
        TypeConverter<OrderContactType, String>(
          StoreEnumCacheConverters.orderContactTypeToCache,
        ),
      ],
    ),
    MapType<StoreOrderContactEmbedded, StoreOrderContact>(
      converters: [
        TypeConverter<String, OrderContactType>(
          StoreEnumCacheConverters.orderContactTypeFromCache,
        ),
      ],
    ),

    MapType<StoreProfileDto, StoreProfile>(
      fields: [
        Field('channels', custom: StoreMapprHelper.channelsToEntity),
        Field('logoUrl', custom: StoreMapprHelper.logoUrlFromDto),
      ],
    ),
    MapType<StoreProfile, StoreProfileDto>(
      fields: [Field('channels', custom: StoreMapprHelper.channelsToDto)],
    ),
    MapType<StoreProfile, StoreProfileCache>(
      fields: [Field('storeId', from: 'id')],
      converters: [
        TypeConverter<Set<StoreChannel>, List<String>>(
          StoreEnumCacheConverters.channelsToCache,
        ),
      ],
    ),
    MapType<StoreProfileCache, StoreProfile>(
      fields: [
        Field('id', from: 'storeId'),
        Field('logoUrl', custom: StoreMapprHelper.logoUrlFromCache),
      ],
      converters: [
        TypeConverter<List<String>, Set<StoreChannel>>(
          StoreEnumCacheConverters.channelsFromCache,
        ),
      ],
    ),

    MapType<ProductAnalyticsSummaryDto, ProductAnalyticsSummary>(),
    MapType<ProductAnalyticsSummary, ProductAnalyticsCache>(),
    MapType<ProductAnalyticsCache, ProductAnalyticsSummary>(),
  ],
  includes: [GarmentMeasurementsMappr(), BodyMeasurementRangesMappr()],
)
class StoreMappr extends $StoreMappr {
  const StoreMappr();
}

class StoreMapprHelper {
  static List<String> imageUrlsFromDto(final ProductDto source) =>
      source.imagePaths.map(StoreImagesApi.publicUrl).toList();

  static List<String> imageUrlsFromCache(final ProductCache source) =>
      source.imagePaths.map(StoreImagesApi.publicUrl).toList();

  static String? logoUrlFromDto(final StoreProfileDto source) =>
      StoreImagesApi.publicUrlOrNull(source.logoPath);

  static String? logoUrlFromCache(final StoreProfileCache source) =>
      StoreImagesApi.publicUrlOrNull(source.logoPath);

  static ProductStatus statusFromDto(final ProductDto source) =>
      source.status ?? ProductStatus.active;

  static ProductGender genderFromDto(final ProductDto source) =>
      source.gender ?? ProductGender.unisex;

  static Set<ClothingStyle>? stylesFromDto(final ProductDto source) =>
      source.styles?.toSet();

  static Set<ProductSeason>? seasonsFromDto(final ProductDto source) =>
      source.seasons?.toSet();

  static ProductStatus statusFromCache(final ProductCache source) =>
      ProductAttributesCacheConverters.statusFromCache(source.status) ??
      ProductStatus.active;

  static ProductGender genderFromCache(final ProductCache source) =>
      ProductAttributesCacheConverters.genderFromCache(source.gender) ??
      ProductGender.unisex;

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
