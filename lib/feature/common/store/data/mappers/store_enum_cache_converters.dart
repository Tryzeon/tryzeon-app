import 'package:tryzeon/core/data/cache/decode_cached_enum.dart';
import 'package:tryzeon/feature/common/store/domain/entities/store_channel.dart';
import 'package:tryzeon/feature/common/store/domain/entities/store_order_contact.dart';

class StoreEnumCacheConverters {
  static List<String> channelsToCache(final Set<StoreChannel> source) =>
      StoreChannel.codesFromSet(source);

  static Set<StoreChannel> channelsFromCache(final List<String> source) =>
      source
          .map((final e) => decodeCachedEnum(e, StoreChannel.fromCode))
          .toSet();

  static String orderContactTypeToCache(final OrderContactType source) =>
      source.code;

  static OrderContactType orderContactTypeFromCache(final String source) =>
      decodeCachedEnum(source, OrderContactType.fromCode);
}
