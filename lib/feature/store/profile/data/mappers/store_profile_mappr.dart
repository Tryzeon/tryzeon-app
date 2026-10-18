import 'package:auto_mappr_annotation/auto_mappr_annotation.dart';
import 'package:tryzeon/core/utils/public_image_url.dart';
import 'package:tryzeon/feature/common/store/data/mappers/common_store_mappr.dart';
import 'package:tryzeon/feature/common/store/domain/entities/store_channel.dart';
import 'package:tryzeon/feature/store/profile/data/collections/store_profile_cache.dart';
import 'package:tryzeon/feature/store/profile/data/dtos/store_profile_dto.dart';
import 'package:tryzeon/feature/store/profile/data/mappers/store_profile_mappr.auto_mappr.dart';
import 'package:tryzeon/feature/store/profile/domain/entities/store_profile.dart';

@AutoMappr(
  [
    MapType<StoreProfileDto, StoreProfile>(
      fields: [
        Field('logoUrl', custom: StoreProfileMapprHelper.logoUrlFromDto),
      ],
    ),
    MapType<StoreProfile, StoreProfileDto>(
      fields: [
        Field('channels', custom: StoreProfileMapprHelper.channelsToDto),
      ],
    ),
    MapType<StoreProfile, StoreProfileCache>(
      fields: [Field('storeId', from: 'id')],
    ),
    MapType<StoreProfileCache, StoreProfile>(
      fields: [
        Field('id', from: 'storeId'),
        Field('logoUrl', custom: StoreProfileMapprHelper.logoUrlFromCache),
      ],
    ),
  ],
  includes: [CommonStoreMappr()],
)
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
