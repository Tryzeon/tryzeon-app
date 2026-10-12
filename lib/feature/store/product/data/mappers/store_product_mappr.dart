import 'package:auto_mappr_annotation/auto_mappr_annotation.dart';
import 'package:tryzeon/core/utils/public_image_url.dart';
import 'package:tryzeon/feature/common/clothing_style/data/mappers/clothing_style_cache_converters.dart';
import 'package:tryzeon/feature/common/clothing_style/domain/entities/clothing_style.dart';
import 'package:tryzeon/feature/common/garment_type/data/mappers/garment_type_cache_converters.dart';
import 'package:tryzeon/feature/common/garment_type/domain/entities/garment_type.dart';
import 'package:tryzeon/feature/common/product_attributes/data/mappers/product_attributes_cache_converters.dart';
import 'package:tryzeon/feature/common/product_attributes/domain/entities/product_attributes.dart';
import 'package:tryzeon/feature/common/product_size/data/dtos/body_measurement_ranges_dto.dart';
import 'package:tryzeon/feature/common/product_size/data/mappers/product_size_mappr.dart';
import 'package:tryzeon/feature/store/product/data/collections/product_cache.dart';
import 'package:tryzeon/feature/store/product/data/dtos/create_product_request.dart';
import 'package:tryzeon/feature/store/product/data/dtos/parse_size_voice_response_dto.dart';
import 'package:tryzeon/feature/store/product/data/dtos/product_analysis_result_dto.dart';
import 'package:tryzeon/feature/store/product/data/dtos/product_draft_dto.dart';
import 'package:tryzeon/feature/store/product/data/dtos/product_dto.dart';
import 'package:tryzeon/feature/store/product/data/dtos/product_size_draft_dto.dart';
import 'package:tryzeon/feature/store/product/data/mappers/store_product_mappr.auto_mappr.dart';
import 'package:tryzeon/feature/store/product/domain/entities/parsed_size.dart';
import 'package:tryzeon/feature/store/product/domain/entities/product.dart';
import 'package:tryzeon/feature/store/product/domain/entities/product_analysis_result.dart';
import 'package:tryzeon/feature/store/product/domain/value_objects/size_item.dart';

@AutoMappr(
  [
    MapType<ProductAnalysisResultDto, ProductAnalysisResult>(),
    MapType<ParsedMeasurementDto, ParsedMeasurement>(),
    MapType<ParsedSizeDto, ParsedSize>(
      fields: [
        Field(
          'garmentMeasurements',
          custom: StoreProductMapprHelper.parsedGarmentMeasurementsFromDto,
        ),
        Field(
          'bodyMeasurementRanges',
          custom: StoreProductMapprHelper.parsedBodyMeasurementRangesFromDto,
        ),
      ],
    ),

    MapType<ProductDto, Product>(
      fields: [
        Field('imageUrls', custom: StoreProductMapprHelper.imageUrlsFromDto),
        Field('status', custom: StoreProductMapprHelper.statusFromDto),
        Field('gender', custom: StoreProductMapprHelper.genderFromDto),
        Field('styles', custom: StoreProductMapprHelper.stylesFromDto),
        Field('seasons', custom: StoreProductMapprHelper.seasonsFromDto),
      ],
    ),
    MapType<Product, ProductDto>(
      fields: [
        Field('styles', custom: StoreProductMapprHelper.stylesToDto),
        Field('seasons', custom: StoreProductMapprHelper.seasonsToDto),
      ],
    ),

    MapType<NewProduct, CreateProductRequest>(),
    MapType<ProductDraft, ProductDraftDto>(
      fields: [
        Field('styles', custom: StoreProductMapprHelper.draftStylesToDto),
        Field('seasons', custom: StoreProductMapprHelper.draftSeasonsToDto),
      ],
    ),
    MapType<NewSizeItem, ProductSizeDraftDto>(),

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
        TypeConverter<ProductFit?, String?>(
          ProductAttributesCacheConverters.fitToCache,
        ),
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
        Field('imageUrls', custom: StoreProductMapprHelper.imageUrlsFromCache),
        Field('status', custom: StoreProductMapprHelper.statusFromCache),
        Field('gender', custom: StoreProductMapprHelper.genderFromCache),
      ],
      converters: [
        TypeConverter<String, GarmentType>(
          GarmentTypeCacheConverters.fromCache,
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
        TypeConverter<List<String>?, Set<ClothingStyle>?>(
          ClothingStyleCacheConverters.setFromCache,
        ),
        TypeConverter<List<String>?, Set<ProductSeason>?>(
          ProductAttributesCacheConverters.seasonsFromCache,
        ),
      ],
    ),
  ],
  includes: [ProductSizeMappr()],
)
class StoreProductMappr extends $StoreProductMappr {
  const StoreProductMappr();
}

class StoreProductMapprHelper {
  static Map<GarmentMeasurementType, ParsedMeasurement>
  parsedGarmentMeasurementsFromDto(final ParsedSizeDto source) => {
    // A `?key:` null-aware element around this const constructor call crashes
    // the Dart 3.13 front end (iOS CI builds without widget-creation tracking).
    for (final MapEntry(:key, :value) in source.garmentMeasurements.entries)
      // ignore: use_null_aware_elements
      if (GarmentMeasurementType.values
              .where((final t) => t.value == key)
              .firstOrNull
          case final type?)
        type: const StoreProductMappr()
            .convert<ParsedMeasurementDto, ParsedMeasurement>(value),
  };

  static Map<BodyMeasurementType, MeasurementRange>
  parsedBodyMeasurementRangesFromDto(final ParsedSizeDto source) {
    final ranges = const StoreProductMappr()
        .convert<BodyMeasurementRangesDto, BodyMeasurementRanges>(
          source.bodyMeasurementRanges,
        );
    return {for (final type in BodyMeasurementType.values) type: ?ranges[type]};
  }

  static List<String> imageUrlsFromDto(final ProductDto source) =>
      source.imagePaths.map(PublicImageUrl.of).toList();

  static List<String> imageUrlsFromCache(final ProductCache source) =>
      source.imagePaths.map(PublicImageUrl.of).toList();

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

  static List<ClothingStyle>? draftStylesToDto(final ProductDraft source) {
    final styles = source.styles;
    return styles == null ? null : ClothingStyle.listFromSet(styles);
  }

  static List<ProductSeason>? draftSeasonsToDto(final ProductDraft source) {
    final seasons = source.seasons;
    return seasons == null ? null : ProductSeason.listFromSet(seasons);
  }

  static List<ClothingStyle>? stylesToDto(final Product source) {
    final styles = source.styles;
    return styles == null ? null : ClothingStyle.listFromSet(styles);
  }

  static List<ProductSeason>? seasonsToDto(final Product source) {
    final seasons = source.seasons;
    return seasons == null ? null : ProductSeason.listFromSet(seasons);
  }
}
