import 'package:tryzeon/core/data/cache/decode_cached_enum.dart';
import 'package:tryzeon/feature/common/product_attributes/domain/entities/product_attributes.dart';

class ProductAttributesCacheConverters {
  static String? genderToCache(final ProductGender? source) => source?.value;

  static ProductGender? genderFromCache(final String? source) =>
      decodeCachedEnumOrNull(source, ProductGender.tryFromString);

  static String? statusToCache(final ProductStatus? source) => source?.value;

  static ProductStatus? statusFromCache(final String? source) =>
      decodeCachedEnumOrNull(source, ProductStatus.tryFromString);

  static String? elasticityToCache(final ProductElasticity? source) => source?.value;

  static ProductElasticity? elasticityFromCache(final String? source) =>
      decodeCachedEnumOrNull(source, ProductElasticity.tryFromString);

  static String? fitToCache(final ProductFit? source) => source?.value;

  static ProductFit? fitFromCache(final String? source) =>
      decodeCachedEnumOrNull(source, ProductFit.tryFromString);

  static String? thicknessToCache(final ProductThickness? source) => source?.value;

  static ProductThickness? thicknessFromCache(final String? source) =>
      decodeCachedEnumOrNull(source, ProductThickness.tryFromString);

  static List<String>? seasonsToCache(final List<ProductSeason>? source) =>
      source?.map((final e) => e.value).toList();

  static List<ProductSeason>? seasonsFromCache(final List<String>? source) =>
      decodeCachedEnumList(source, ProductSeason.tryFromString);
}
