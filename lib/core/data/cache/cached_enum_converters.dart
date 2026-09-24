import 'package:tryzeon/core/data/cache/decode_cached_enum.dart';
import 'package:tryzeon/feature/common/clothing_style/domain/entities/clothing_style.dart';
import 'package:tryzeon/feature/common/garment_type/domain/entities/garment_type.dart';
import 'package:tryzeon/feature/common/product_attributes/domain/entities/product_attributes.dart';
import 'package:tryzeon/feature/personal/profile/domain/entities/age_range.dart';
import 'package:tryzeon/feature/personal/profile/domain/entities/gender.dart';

class CachedEnumConverters {
  static String garmentTypeToCache(final GarmentType source) => source.value;

  static GarmentType garmentTypeFromCache(final String source) =>
      decodeCachedEnum(source, GarmentType.tryFromString, field: 'garmentType');

  static String? productGenderToCache(final ProductGender? source) => source?.value;

  static ProductGender? productGenderFromCache(final String? source) =>
      decodeCachedEnumOrNull(source, ProductGender.tryFromString, field: 'gender');

  static String? genderToCache(final Gender? source) => source?.value;

  static Gender? genderFromCache(final String? source) =>
      decodeCachedEnumOrNull(source, Gender.tryFromString, field: 'gender');

  static String? ageRangeToCache(final AgeRange? source) => source?.value;

  static AgeRange? ageRangeFromCache(final String? source) =>
      decodeCachedEnumOrNull(source, AgeRange.tryFromString, field: 'ageRange');

  static List<String>? clothingStylesToCache(final List<ClothingStyle>? source) =>
      source?.map((final e) => e.value).toList();

  static List<ClothingStyle>? clothingStylesFromCache(final List<String>? source) =>
      decodeCachedEnumList(source, ClothingStyle.tryFromString, field: 'clothingStyle');
}
