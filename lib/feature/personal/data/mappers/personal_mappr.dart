import 'package:auto_mappr_annotation/auto_mappr_annotation.dart';
import 'package:tryzeon/core/data/cache/cached_enum_converters.dart';
import 'package:tryzeon/feature/common/garment_type/domain/entities/garment_type.dart';

import '../../../../feature/common/body_measurements/data/mappers/body_measurements_mappr.dart';
import '../../../../feature/common/clothing_style/domain/entities/clothing_style.dart';
import '../../../../feature/common/product_size/data/mappers/body_measurement_ranges_mappr.dart';
import '../../../../feature/common/product_size/data/mappers/garment_measurements_mappr.dart';
import '../../../../feature/common/product_size/domain/entities/product_size.dart';
import '../../../../feature/store/product/data/models/product_model.dart';
import '../../../common/store/data/models/store_order_contact_model.dart';
import '../../../common/store/domain/entities/store_channel.dart';
import '../../../common/store/domain/entities/store_order_contact.dart';
import '../../profile/data/collections/user_profile_cache.dart';
import '../../profile/data/models/user_profile_model.dart';
import '../../profile/domain/entities/age_range.dart';
import '../../profile/domain/entities/gender.dart';
import '../../profile/domain/entities/user_profile.dart';
import '../../shop/data/models/shop_product_model.dart';
import '../../shop/data/models/shop_store_info_model.dart';
import '../../shop/domain/entities/shop_product.dart';
import '../../shop/domain/entities/shop_store_info.dart';
import '../../subscription/data/collections/subscription_tier_cache.dart';
import '../../subscription/data/models/subscription_tier_model.dart';
import '../../wardrobe/data/collections/wardrobe_item_cache.dart';
import '../../wardrobe/data/models/wardrobe_item_model.dart';
import '../../wardrobe/domain/entities/wardrobe_item.dart';
import 'personal_mappr.auto_mappr.dart';

@AutoMappr(
  [
    MapType<UserProfileModel, UserProfile>(),
    MapType<UserProfile, UserProfileModel>(),
    MapType<UserProfileModel, UserProfileCache>(
      converters: [
        TypeConverter<Gender?, String?>(CachedEnumConverters.genderToCache),
        TypeConverter<AgeRange?, String?>(CachedEnumConverters.ageRangeToCache),
        TypeConverter<List<ClothingStyle>?, List<String>?>(
          CachedEnumConverters.clothingStylesToCache,
        ),
      ],
    ),
    MapType<UserProfileCache, UserProfileModel>(
      converters: [
        TypeConverter<String?, Gender?>(CachedEnumConverters.genderFromCache),
        TypeConverter<String?, AgeRange?>(CachedEnumConverters.ageRangeFromCache),
        TypeConverter<List<String>?, List<ClothingStyle>?>(
          CachedEnumConverters.clothingStylesFromCache,
        ),
      ],
    ),

    MapType<WardrobeItemModel, WardrobeItem>(),
    MapType<WardrobeItem, WardrobeItemModel>(),
    MapType<WardrobeItemModel, WardrobeItemCache>(
      fields: [Field('itemId', from: 'id')],
      converters: [TypeConverter<GarmentType, String>(CachedEnumConverters.garmentTypeToCache)],
    ),
    MapType<WardrobeItemCache, WardrobeItemModel>(
      fields: [Field('id', from: 'itemId')],
      converters: [TypeConverter<String, GarmentType>(CachedEnumConverters.garmentTypeFromCache)],
    ),
    MapType<ShopProductModel, ShopProduct>(),

    MapType<StoreOrderContactModel, StoreOrderContact>(
      fields: [Field('type', custom: ShopStoreInfoMapprHelper.codeToOrderContactType)],
    ),

    MapType<ShopStoreInfoModel, ShopStoreInfo>(
      fields: [Field('channels', custom: ShopStoreInfoMapprHelper.codesToChannelSet)],
    ),

    MapType<ProductSizeModel, ProductSize>(),

    MapType<SubscriptionTierModel, SubscriptionTierCache>(
      fields: [Field('tier', from: 'id')],
    ),
    MapType<SubscriptionTierCache, SubscriptionTierModel>(
      fields: [Field('id', from: 'tier')],
    ),
  ],
  includes: [
    BodyMeasurementsMappr(), // UserProfile.measurements
    GarmentMeasurementsMappr(), // ProductSize.measurements
    BodyMeasurementRangesMappr(), // ProductSize.bodyMeasurementRanges
  ],
)
class PersonalMappr extends $PersonalMappr {
  const PersonalMappr();
}

class ShopStoreInfoMapprHelper {
  static Set<StoreChannel> codesToChannelSet(final ShopStoreInfoModel source) =>
      StoreChannel.setFromCodes(source.channels);

  static OrderContactType codeToOrderContactType(final StoreOrderContactModel source) =>
      OrderContactType.fromCode(source.type) ?? OrderContactType.line;
}
