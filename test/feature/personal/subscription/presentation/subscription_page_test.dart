import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/modules/revenue_cat/domain/entities/app_subscription_entitlement.dart';
import 'package:tryzeon/core/modules/revenue_cat/providers/revenue_cat_providers.dart';
import 'package:tryzeon/feature/common/usage_quota/domain/entities/usage_quota.dart';
import 'package:tryzeon/feature/personal/subscription/domain/entities/subscription_capabilities.dart';
import 'package:tryzeon/feature/personal/subscription/presentation/pages/subscription_page.dart';
import 'package:tryzeon/feature/personal/subscription/providers/subscription_capabilities_provider.dart';
import 'package:tryzeon/feature/personal/usage/providers/usage_quota_providers.dart';
import 'package:tryzeon/feature/personal/wardrobe/domain/entities/wardrobe_item.dart';
import 'package:tryzeon/feature/personal/wardrobe/providers/wardrobe_providers.dart';

class _FakeUsageQuota extends UsageQuotaNotifier {
  _FakeUsageQuota(this._quota);

  final UsageQuota _quota;

  @override
  Future<UsageQuota> build() async => _quota;
}

class _FakeWardrobe extends WardrobeItemsNotifier {
  @override
  Future<List<WardrobeItem>> build() async => const [];
}

void main() {
  final taipeiNov5 = DateTime.utc(2026, 11, 4, 16);

  final proQuota = UsageQuota(
    tier: AppSubscriptionTier.pro,
    period: QuotaPeriod.month,
    resetsAt: taipeiNov5,
    tryonImage: const FeatureQuota(used: 12, quota: 250),
    tryonVideo: const FeatureQuota(used: 1, quota: 3),
  );
  final freeQuota = UsageQuota(
    tier: AppSubscriptionTier.free,
    period: QuotaPeriod.day,
    resetsAt: DateTime.utc(2026, 10, 19, 16),
    tryonImage: const FeatureQuota(used: 2, quota: 10),
    tryonVideo: const FeatureQuota(used: 0, quota: 0),
  );

  Future<void> pump(final WidgetTester tester, final UsageQuota quota) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appSubscriptionEntitlementProvider.overrideWith(
            (final ref) => Stream.value(
              AppSubscriptionEntitlement(
                tier: quota.tier,
                expirationDate: null,
              ),
            ),
          ),
          subscriptionCapabilitiesProvider.overrideWith(
            (final ref) async =>
                const SubscriptionCapabilities(wardrobeLimit: 50),
          ),
          usageQuotaProvider.overrideWith(() => _FakeUsageQuota(quota)),
          wardrobeItemsProvider.overrideWith(_FakeWardrobe.new),
        ],
        child: const MaterialApp(home: SubscriptionPage()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('pro shows the billing-period usage with the reset date', (
    final tester,
  ) async {
    await pump(tester, proQuota);

    expect(find.text('本期用量（11/5 重置）'), findsOneWidget);
    expect(find.text('試穿'), findsOneWidget);
    expect(find.text('12 / 250'), findsOneWidget);
    expect(find.text('影片'), findsOneWidget);
    expect(find.text('1 / 3'), findsOneWidget);
    expect(find.textContaining('今日'), findsNothing);
  });

  testWidgets('chat is a fair-use benefit, never a usage row', (
    final tester,
  ) async {
    await pump(tester, proQuota);

    expect(find.text('聊天'), findsOneWidget);
    expect(find.text('不限次數＊'), findsOneWidget);
    expect(find.text('＊適用合理使用政策'), findsOneWidget);
    expect(find.text('今日聊天'), findsNothing);
  });

  testWidgets('free shows the daily usage title', (final tester) async {
    await pump(tester, freeQuota);

    expect(find.text('今日用量'), findsOneWidget);
    expect(find.textContaining('重置'), findsNothing);
    expect(find.text('2 / 10'), findsOneWidget);
    expect(find.text('未開通'), findsOneWidget);
  });
}
