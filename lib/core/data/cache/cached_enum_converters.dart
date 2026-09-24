import 'package:tryzeon/core/data/cache/decode_cached_enum.dart';
import 'package:tryzeon/feature/common/garment_type/domain/entities/garment_type.dart';
import 'package:tryzeon/feature/common/product_attributes/domain/entities/product_attributes.dart';

class CachedEnumConverters {
  static String garmentTypeToCache(final GarmentType source) => source.value;

  static GarmentType garmentTypeFromCache(final String source) =>
      decodeCachedEnum(source, GarmentType.tryFromString, field: 'garmentType');

  static String? productGenderToCache(final ProductGender? source) => source?.value;

  static ProductGender? productGenderFromCache(final String? source) =>
      decodeCachedEnumOrNull(source, ProductGender.tryFromString, field: 'gender');
}
