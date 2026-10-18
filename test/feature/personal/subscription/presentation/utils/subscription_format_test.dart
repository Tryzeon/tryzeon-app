import 'package:flutter_test/flutter_test.dart';
import 'package:tryzeon/core/modules/revenue_cat/domain/entities/app_subscription_entitlement.dart';
import 'package:tryzeon/feature/personal/subscription/presentation/utils/subscription_format.dart';

AppSubscriptionEntitlement max(final String? expirationDate) =>
    AppSubscriptionEntitlement(
      tier: AppSubscriptionTier.max,
      expirationDate: expirationDate,
    );

void main() {
  test('the renewal date is the local calendar date', () {
    final renewsAt = DateTime(2027, 6, 17, 0, 30).toUtc().toIso8601String();

    expect(formatRenewalLine(max(renewsAt)), '2027/06/17 續訂');
  });

  test('a missing or unreadable date falls back to subscribed', () {
    expect(formatRenewalLine(max(null)), '訂閱中');
    expect(formatRenewalLine(max('not a date')), '訂閱中');
  });

  test('the free tier names the trial plan', () {
    expect(
      formatRenewalLine(
        const AppSubscriptionEntitlement(
          tier: AppSubscriptionTier.free,
          expirationDate: null,
        ),
      ),
      '免費試用方案',
    );
  });
}
