import 'package:auto_mappr_annotation/auto_mappr_annotation.dart';

import '../../../../core/shared/measurements/data/mappers/measurements_mappr.dart';
import '../../../../feature/store/products/data/models/product_model.dart';
import '../../../../feature/store/products/domain/entities/product.dart';
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
import '../../wardrobe/domain/entities/wardrobe_item.dart';
import 'personal_mappr.auto_mappr.dart';

/// AutoMappr configuration for Personal feature
/// Handles UserProfile, WardrobeItem, Subscription, ShopProduct, ShopStoreInfo mappings
/// Note: ProductSize mappings are defined here directly for ShopProduct.sizes dependency
/// Note: Measurements mappings are included via MeasurementsMappr (for ProductSize.measurements)
@AutoMappr(
  [
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
    MapType<SubscriptionModel, SubscriptionCollection>(),
    MapType<SubscriptionCollection, SubscriptionModel>(),

    // ShopProduct mappings (read-only for consumer)
    MapType<ShopProductModel, ShopProduct>(),

    // ShopStoreInfo mappings (read-only for consumer)
    MapType<ShopStoreInfoModel, ShopStoreInfo>(),

    // ProductSize mappings (needed for ShopProduct.sizes)
    MapType<ProductSizeModel, ProductSize>(),
  ],
  includes: [
    MeasurementsMappr(), // ProductSize.measurements depends on Measurements mapping
  ],
)
class PersonalMappr extends $PersonalMappr {
  const PersonalMappr();

  static String itemIdFromModel(final WardrobeItemModel model) => model.id ?? '';

  static String nullableStringToString(final String? value) => value ?? '';
}
