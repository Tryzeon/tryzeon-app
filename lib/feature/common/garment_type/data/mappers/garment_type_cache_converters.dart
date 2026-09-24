import 'package:tryzeon/core/data/cache/decode_cached_enum.dart';
import 'package:tryzeon/feature/common/garment_type/domain/entities/garment_type.dart';

class GarmentTypeCacheConverters {
  static String toCache(final GarmentType source) => source.value;

  static GarmentType fromCache(final String source) =>
      decodeCachedEnum(source, GarmentType.tryFromString);
}
