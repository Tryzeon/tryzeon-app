import 'package:auto_mappr_annotation/auto_mappr_annotation.dart';

import '../../../../core/shared/measurements/collections/body_measurements_collection.dart';
import '../../../../core/shared/measurements/data/models/body_measurements_model.dart';
import '../../../../core/shared/measurements/entities/body_measurements.dart';
import '../../../../feature/store/data/mappers/store_mappr.dart';
import '../../profile/data/collections/user_profile_collection.dart';
import '../../profile/data/models/user_profile_model.dart';
import '../../profile/domain/entities/user_profile.dart';
import '../../shop/data/models/shop_product_model.dart';
import '../../shop/data/models/shop_store_info_model.dart';
import '../../shop/domain/entities/shop_product.dart';
import '../../shop/domain/entities/shop_store_info.dart';
import '../../subscription/data/collections/subscription_collection.dart';
import '../../subscription/data/models/subscription_model.dart';
import '../../subscription/domain/entities/subscription.dart';
import '../../wardrobe/data/collections/wardrobe_item_collection.dart';
import '../../wardrobe/data/models/wardrobe_item_model.dart';
import '../../wardrobe/domain/entities/wardrobe_category.dart';
import '../../wardrobe/domain/entities/wardrobe_item.dart';
import 'personal_mappr.auto_mappr.dart';

/// AutoMappr configuration for Personal feature
/// Handles UserProfile, WardrobeItem, Subscription, ShopProduct, ShopStoreInfo mappings
@AutoMappr(
  [
    // BodyMeasurements mappings (needed for UserProfile.measurements)
    MapType<BodyMeasurementsModel, BodyMeasurements>(),
    MapType<BodyMeasurements, BodyMeasurementsModel>(),
    MapType<BodyMeasurementsModel, BodyMeasurementsCollection>(),
    MapType<BodyMeasurementsCollection, BodyMeasurementsModel>(),

    // UserProfile mappings
    MapType<UserProfileModel, UserProfile>(),
    MapType<UserProfile, UserProfileModel>(),
    MapType<UserProfileModel, UserProfileCollection>(),
    MapType<UserProfileCollection, UserProfileModel>(
      converters: [TypeConverter<String?, String>(PersonalMappr.nullableStringToString)],
    ),

    // WardrobeItem mappings
    MapType<WardrobeItemModel, WardrobeItem>(),
    MapType<WardrobeItem, WardrobeItemModel>(),
    MapType<WardrobeItemModel, WardrobeItemCollection>(
      fields: [Field('itemId', from: 'id')],
      converters: [TypeConverter<String?, String>(PersonalMappr.nullableStringToString)],
    ),
    MapType<WardrobeItemCollection, WardrobeItemModel>(
      fields: [Field('id', from: 'itemId')],
    ),

    // Subscription mappings
    MapType<SubscriptionModel, Subscription>(),
    MapType<Subscription, SubscriptionModel>(),
    MapType<SubscriptionModel, SubscriptionCollection>(),
    MapType<SubscriptionCollection, SubscriptionModel>(),

    // ShopProduct mappings
    MapType<ShopProductModel, ShopProduct>(),
    MapType<ShopProduct, ShopProductModel>(),

    // ShopStoreInfo mappings
    MapType<ShopStoreInfoModel, ShopStoreInfo>(),
    MapType<ShopStoreInfo, ShopStoreInfoModel>(),
  ],
  includes: [
    StoreMappr(), // ShopProduct.sizes depends on ProductSize mapping
  ],
)
class PersonalMappr extends $PersonalMappr {
  const PersonalMappr();

  static String itemIdFromModel(final WardrobeItemModel model) => model.id ?? '';

  static String nullableStringToString(final String? value) => value ?? '';
}
