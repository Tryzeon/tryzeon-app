import 'package:tryzeon/core/data/cache/decode_cached_enum.dart';
import 'package:tryzeon/core/modules/revenue_cat/domain/entities/app_subscription_entitlement.dart';

class SubscriptionTierCacheConverters {
  static String toCache(final AppSubscriptionTier source) => source.value;

  static AppSubscriptionTier fromCache(final String source) =>
      decodeCachedEnum(source, AppSubscriptionTier.tryFromString, field: 'tier');
}
