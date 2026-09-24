import 'package:tryzeon/core/data/cache/decode_cached_enum.dart';
import 'package:tryzeon/feature/common/clothing_style/domain/entities/clothing_style.dart';

class ClothingStyleCacheConverters {
  static List<String>? listToCache(final List<ClothingStyle>? source) =>
      source?.map((final e) => e.value).toList();

  static List<ClothingStyle>? listFromCache(final List<String>? source) =>
      decodeCachedEnumList(source, ClothingStyle.tryFromString);
}
