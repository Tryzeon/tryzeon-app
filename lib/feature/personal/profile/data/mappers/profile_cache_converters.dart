import 'package:tryzeon/core/data/cache/decode_cached_enum.dart';
import 'package:tryzeon/feature/personal/profile/domain/entities/age_range.dart';
import 'package:tryzeon/feature/personal/profile/domain/entities/gender.dart';

class ProfileCacheConverters {
  static String? genderToCache(final Gender? source) => source?.value;

  static Gender? genderFromCache(final String? source) =>
      decodeCachedEnumOrNull(source, Gender.tryFromString, field: 'gender');

  static String? ageRangeToCache(final AgeRange? source) => source?.value;

  static AgeRange? ageRangeFromCache(final String? source) =>
      decodeCachedEnumOrNull(source, AgeRange.tryFromString, field: 'ageRange');
}
