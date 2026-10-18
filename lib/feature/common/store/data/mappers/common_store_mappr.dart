import 'package:auto_mappr_annotation/auto_mappr_annotation.dart';
import 'package:tryzeon/feature/common/store/data/collections/store_order_contact_embedded.dart';
import 'package:tryzeon/feature/common/store/data/dtos/store_order_contact_dto.dart';
import 'package:tryzeon/feature/common/store/data/mappers/common_store_mappr.auto_mappr.dart';
import 'package:tryzeon/feature/common/store/data/mappers/order_contacts_converters.dart';
import 'package:tryzeon/feature/common/store/data/mappers/store_enum_cache_converters.dart';
import 'package:tryzeon/feature/common/store/domain/entities/order_contact_type.dart';
import 'package:tryzeon/feature/common/store/domain/entities/store_channel.dart';

@AutoMappr(
  [],
  converters: [
    TypeConverter<List<StoreOrderContactDto>, Map<OrderContactType, String>>(
      OrderContactsConverters.fromDtos,
    ),
    TypeConverter<Map<OrderContactType, String>, List<StoreOrderContactDto>>(
      OrderContactsConverters.toDtos,
    ),
    TypeConverter<
      List<StoreOrderContactEmbedded>,
      Map<OrderContactType, String>
    >(OrderContactsConverters.fromCache),
    TypeConverter<
      Map<OrderContactType, String>,
      List<StoreOrderContactEmbedded>
    >(OrderContactsConverters.toCache),
    TypeConverter<List<String>, Set<StoreChannel>>(
      StoreEnumCacheConverters.channelsFromCache,
    ),
    TypeConverter<Set<StoreChannel>, List<String>>(
      StoreEnumCacheConverters.channelsToCache,
    ),
  ],
)
class CommonStoreMappr extends $CommonStoreMappr {
  const CommonStoreMappr();
}
