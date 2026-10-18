import 'package:auto_mappr_annotation/auto_mappr_annotation.dart';
import 'package:tryzeon/core/utils/public_image_url.dart';
import 'package:tryzeon/feature/common/store/data/collections/store_order_contact_embedded.dart';
import 'package:tryzeon/feature/common/store/data/dtos/store_order_contact_dto.dart';
import 'package:tryzeon/feature/common/store/data/mappers/order_contacts_converters.dart';
import 'package:tryzeon/feature/common/store/data/mappers/store_enum_cache_converters.dart';
import 'package:tryzeon/feature/common/store/domain/entities/order_contact_type.dart';
import 'package:tryzeon/feature/common/store/domain/entities/store_channel.dart';
import 'package:tryzeon/feature/store/profile/data/collections/store_profile_cache.dart';
import 'package:tryzeon/feature/store/profile/data/dtos/store_profile_dto.dart';
import 'package:tryzeon/feature/store/profile/data/mappers/store_profile_mappr.auto_mappr.dart';
import 'package:tryzeon/feature/store/profile/domain/entities/store_profile.dart';

@AutoMappr([
  MapType<StoreProfileDto, StoreProfile>(
    fields: [Field('logoUrl', custom: StoreProfileMapprHelper.logoUrlFromDto)],
    converters: [
      TypeConverter<List<StoreOrderContactDto>, Map<OrderContactType, String>>(
        OrderContactsConverters.fromDtos,
      ),
    ],
  ),
  MapType<StoreProfile, StoreProfileDto>(
    fields: [Field('channels', custom: StoreProfileMapprHelper.channelsToDto)],
    converters: [
      TypeConverter<Map<OrderContactType, String>, List<StoreOrderContactDto>>(
        OrderContactsConverters.toDtos,
      ),
    ],
  ),
  MapType<StoreProfile, StoreProfileCache>(
    fields: [Field('storeId', from: 'id')],
    converters: [
      TypeConverter<Set<StoreChannel>, List<String>>(
        StoreEnumCacheConverters.channelsToCache,
      ),
      TypeConverter<
        Map<OrderContactType, String>,
        List<StoreOrderContactEmbedded>
      >(OrderContactsConverters.toCache),
    ],
  ),
  MapType<StoreProfileCache, StoreProfile>(
    fields: [
      Field('id', from: 'storeId'),
      Field('logoUrl', custom: StoreProfileMapprHelper.logoUrlFromCache),
    ],
    converters: [
      TypeConverter<List<String>, Set<StoreChannel>>(
        StoreEnumCacheConverters.channelsFromCache,
      ),
      TypeConverter<
        List<StoreOrderContactEmbedded>,
        Map<OrderContactType, String>
      >(OrderContactsConverters.fromCache),
    ],
  ),
])
class StoreProfileMappr extends $StoreProfileMappr {
  const StoreProfileMappr();
}

class StoreProfileMapprHelper {
  static String? logoUrlFromDto(final StoreProfileDto source) =>
      PublicImageUrl.ofOrNull(source.logoPath);

  static String? logoUrlFromCache(final StoreProfileCache source) =>
      PublicImageUrl.ofOrNull(source.logoPath);

  static List<StoreChannel> channelsToDto(final StoreProfile source) =>
      StoreChannel.listFromSet(source.channels);
}
