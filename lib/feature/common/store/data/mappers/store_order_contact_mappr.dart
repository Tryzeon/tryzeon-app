import 'package:auto_mappr_annotation/auto_mappr_annotation.dart';
import 'package:tryzeon/feature/common/store/data/collections/store_order_contact_embedded.dart';
import 'package:tryzeon/feature/common/store/data/dtos/store_order_contact_dto.dart';
import 'package:tryzeon/feature/common/store/data/mappers/store_enum_cache_converters.dart';
import 'package:tryzeon/feature/common/store/data/mappers/store_order_contact_mappr.auto_mappr.dart';
import 'package:tryzeon/feature/common/store/domain/entities/store_order_contact.dart';

@AutoMappr([
  MapType<StoreOrderContactDto, StoreOrderContact>(),
  MapType<StoreOrderContact, StoreOrderContactDto>(),
  MapType<StoreOrderContact, StoreOrderContactEmbedded>(
    converters: [
      TypeConverter<OrderContactType, String>(
        StoreEnumCacheConverters.orderContactTypeToCache,
      ),
    ],
  ),
  MapType<StoreOrderContactEmbedded, StoreOrderContact>(
    converters: [
      TypeConverter<String, OrderContactType>(
        StoreEnumCacheConverters.orderContactTypeFromCache,
      ),
    ],
  ),
])
class StoreOrderContactMappr extends $StoreOrderContactMappr {
  const StoreOrderContactMappr();
}
