import 'package:tryzeon/core/modules/revenue_cat/domain/entities/app_subscription_entitlement.dart';

/// Display name for the plan badge.
String planName(final AppSubscriptionTier tier) => switch (tier) {
  AppSubscriptionTier.free => 'Free',
  AppSubscriptionTier.pro => 'Pro',
  AppSubscriptionTier.max => 'Max',
};

/// Format `used / limit`. `limit < 0` → unlimited, `limit == 0` → not available,
/// `used == null` (data unavailable) → em dash for the used count.
String formatUsage({required final int? used, required final int limit}) {
  if (limit == 0) return '未開通';
  final usedText = used?.toString() ?? '—';
  if (limit < 0) return '$usedText / ∞';
  return '$usedText / $limit';
}

/// Builds the second line shown under the plan name on Account page's
/// SubscriptionUsageCard and on Subscription page's plan summary card.
String formatRenewalLine(final AppSubscriptionEntitlement entitlement) {
  if (entitlement.tier == AppSubscriptionTier.free) {
    return '免費試用方案';
  }

  final raw = entitlement.expirationDate;
  if (raw == null || raw.isEmpty) {
    return '訂閱中';
  }

  final parsed = DateTime.tryParse(raw);
  if (parsed == null) {
    return '訂閱中';
  }

  final y = parsed.year.toString().padLeft(4, '0');
  final m = parsed.month.toString().padLeft(2, '0');
  final d = parsed.day.toString().padLeft(2, '0');
  return '$y/$m/$d 續訂';
}
