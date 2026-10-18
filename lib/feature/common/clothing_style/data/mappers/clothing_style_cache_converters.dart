import 'package:tryzeon/core/data/cache/decode_cached_enum.dart';
import 'package:tryzeon/feature/common/clothing_style/domain/entities/clothing_style.dart';

class ClothingStyleCacheConverters {
  static List<String>? setToCache(final Set<ClothingStyle>? source) =>
      source == null
      ? null
      : ClothingStyle.listFromSet(source).map((final e) => e.value).toList();

  static Set<ClothingStyle>? setFromCache(final List<String>? source) =>
      decodeCachedEnumList(source, ClothingStyle.tryFromString)?.toSet();
}
