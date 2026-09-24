import 'package:tryzeon/core/data/cache/decode_cached_enum.dart';
import 'package:tryzeon/core/modules/revenue_cat/domain/entities/app_subscription_entitlement.dart';
import 'package:tryzeon/feature/common/clothing_style/domain/entities/clothing_style.dart';
import 'package:tryzeon/feature/common/garment_type/domain/entities/garment_type.dart';
import 'package:tryzeon/feature/common/product_attributes/domain/entities/product_attributes.dart';
import 'package:tryzeon/feature/common/store/domain/entities/store_channel.dart';
import 'package:tryzeon/feature/common/store/domain/entities/store_order_contact.dart';
import 'package:tryzeon/feature/personal/profile/domain/entities/age_range.dart';
import 'package:tryzeon/feature/personal/profile/domain/entities/gender.dart';

class CachedEnumConverters {
  static String subscriptionTierToCache(final AppSubscriptionTier source) => source.value;

  static AppSubscriptionTier subscriptionTierFromCache(final String source) =>
      decodeCachedEnum(source, AppSubscriptionTier.tryFromString, field: 'tier');

  static String garmentTypeToCache(final GarmentType source) => source.value;

  static GarmentType garmentTypeFromCache(final String source) =>
      decodeCachedEnum(source, GarmentType.tryFromString, field: 'garmentType');

  static String? productGenderToCache(final ProductGender? source) => source?.value;

  static ProductGender? productGenderFromCache(final String? source) =>
      decodeCachedEnumOrNull(source, ProductGender.tryFromString, field: 'gender');

  static String? productStatusToCache(final ProductStatus? source) => source?.value;

  static ProductStatus? productStatusFromCache(final String? source) =>
      decodeCachedEnumOrNull(source, ProductStatus.tryFromString, field: 'status');

  static String? productElasticityToCache(final ProductElasticity? source) =>
      source?.value;

  static ProductElasticity? productElasticityFromCache(final String? source) =>
      decodeCachedEnumOrNull(
        source,
        ProductElasticity.tryFromString,
        field: 'elasticity',
      );

  static String? productFitToCache(final ProductFit? source) => source?.value;

  static ProductFit? productFitFromCache(final String? source) =>
      decodeCachedEnumOrNull(source, ProductFit.tryFromString, field: 'fit');

  static String? productThicknessToCache(final ProductThickness? source) => source?.value;

  static ProductThickness? productThicknessFromCache(final String? source) =>
      decodeCachedEnumOrNull(source, ProductThickness.tryFromString, field: 'thickness');

  static List<String>? productSeasonsToCache(final List<ProductSeason>? source) =>
      source?.map((final e) => e.value).toList();

  static List<ProductSeason>? productSeasonsFromCache(final List<String>? source) =>
      decodeCachedEnumList(source, ProductSeason.tryFromString, field: 'season');

  static String? genderToCache(final Gender? source) => source?.value;

  static Gender? genderFromCache(final String? source) =>
      decodeCachedEnumOrNull(source, Gender.tryFromString, field: 'gender');

  static String? ageRangeToCache(final AgeRange? source) => source?.value;

  static AgeRange? ageRangeFromCache(final String? source) =>
      decodeCachedEnumOrNull(source, AgeRange.tryFromString, field: 'ageRange');

  static List<String>? clothingStylesToCache(final List<ClothingStyle>? source) =>
      source?.map((final e) => e.value).toList();

  static List<ClothingStyle>? clothingStylesFromCache(final List<String>? source) =>
      decodeCachedEnumList(source, ClothingStyle.tryFromString, field: 'clothingStyle');

  static List<String> storeChannelsToCache(final List<StoreChannel> source) =>
      source.map((final e) => e.code).toList();

  static List<StoreChannel> storeChannelsFromCache(final List<String> source) => source
      .map((final e) => decodeCachedEnum(e, StoreChannel.fromCode, field: 'storeChannel'))
      .toList();

  static String orderContactTypeToCache(final OrderContactType source) => source.code;

  static OrderContactType orderContactTypeFromCache(final String source) =>
      decodeCachedEnum(source, OrderContactType.fromCode, field: 'orderContactType');
}
