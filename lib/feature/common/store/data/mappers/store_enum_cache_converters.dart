import 'package:tryzeon/core/data/cache/decode_cached_enum.dart';
import 'package:tryzeon/feature/common/store/domain/entities/store_channel.dart';
import 'package:tryzeon/feature/common/store/domain/entities/store_order_contact.dart';

class StoreEnumCacheConverters {
  static List<String> channelsToCache(final List<StoreChannel> source) =>
      source.map((final e) => e.code).toList();

  static List<StoreChannel> channelsFromCache(final List<String> source) => source
      .map((final e) => decodeCachedEnum(e, StoreChannel.fromCode, field: 'storeChannel'))
      .toList();

  static String orderContactTypeToCache(final OrderContactType source) => source.code;

  static OrderContactType orderContactTypeFromCache(final String source) =>
      decodeCachedEnum(source, OrderContactType.fromCode, field: 'orderContactType');
}
