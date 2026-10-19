import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tryzeon/core/modules/revenue_cat/domain/entities/app_subscription_entitlement.dart';
import 'package:tryzeon/feature/common/usage_quota/domain/entities/usage_quota.dart';
import 'package:tryzeon/feature/personal/subscription/presentation/widgets/subscription_usage_card.dart';

void main() {
  Future<void> pump(
    final WidgetTester tester, {
    required final AppSubscriptionTier tier,
    required final UsageQuota? quota,
  }) => tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SubscriptionUsageCard(
          entitlement: AppSubscriptionEntitlement(
            tier: tier,
            expirationDate: null,
          ),
          quota: quota,
          wardrobeCapacity: null,
          onTap: () {},
          onUpgrade: () {},
        ),
      ),
    ),
  );

  testWidgets('pro labels tiles by billing period with no reset text', (
    final tester,
  ) async {
    await pump(
      tester,
      tier: AppSubscriptionTier.pro,
      quota: UsageQuota(
        tier: AppSubscriptionTier.pro,
        period: QuotaPeriod.month,
        resetsAt: DateTime.utc(2026, 11, 4, 16),
        tryonImage: const FeatureQuota(used: 12, quota: 250),
        tryonVideo: const FeatureQuota(used: 1, quota: 3),
      ),
    );

    expect(find.text('本期試穿剩餘'), findsOneWidget);
    expect(find.text('本期影片剩餘'), findsOneWidget);
    expect(find.textContaining('重置'), findsNothing);
    expect(find.textContaining('聊天'), findsNothing);
  });

  testWidgets('free labels tiles as today with no reset text', (
    final tester,
  ) async {
    await pump(
      tester,
      tier: AppSubscriptionTier.free,
      quota: UsageQuota(
        tier: AppSubscriptionTier.free,
        period: QuotaPeriod.day,
        resetsAt: DateTime.utc(2026, 10, 19, 16),
        tryonImage: const FeatureQuota(used: 2, quota: 10),
        tryonVideo: const FeatureQuota(used: 0, quota: 0),
      ),
    );

    expect(find.text('今日試穿剩餘'), findsOneWidget);
    expect(find.text('今日影片剩餘'), findsOneWidget);
    expect(find.textContaining('重置'), findsNothing);
  });

  testWidgets('without a snapshot the tiles keep the plain labels', (
    final tester,
  ) async {
    await pump(tester, tier: AppSubscriptionTier.pro, quota: null);

    expect(find.text('試穿剩餘'), findsOneWidget);
    expect(find.text('影片剩餘'), findsOneWidget);
  });
}
