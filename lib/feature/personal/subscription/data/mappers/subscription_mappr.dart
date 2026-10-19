import 'package:auto_mappr_annotation/auto_mappr_annotation.dart';
import 'package:tryzeon/feature/personal/subscription/data/collections/subscription_tier_cache.dart';
import 'package:tryzeon/feature/personal/subscription/data/dtos/subscription_tier_dto.dart';
import 'package:tryzeon/feature/personal/subscription/data/mappers/subscription_mappr.auto_mappr.dart';
import 'package:tryzeon/feature/personal/subscription/domain/entities/subscription_capabilities.dart';

@AutoMappr([
  MapType<SubscriptionTierDto, SubscriptionCapabilities>(),
  MapType<SubscriptionCapabilities, SubscriptionTierCache>(),
  MapType<SubscriptionTierCache, SubscriptionCapabilities>(),
])
class SubscriptionMappr extends $SubscriptionMappr {
  const SubscriptionMappr();
}
