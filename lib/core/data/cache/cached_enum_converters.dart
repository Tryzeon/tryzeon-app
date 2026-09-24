import 'package:tryzeon/core/data/cache/decode_cached_enum.dart';
import 'package:tryzeon/feature/common/garment_type/domain/entities/garment_type.dart';

class CachedEnumConverters {
  static String garmentTypeToCache(final GarmentType source) => source.value;

  static GarmentType garmentTypeFromCache(final String source) =>
      decodeCachedEnum(source, GarmentType.tryFromString, field: 'garmentType');
}
