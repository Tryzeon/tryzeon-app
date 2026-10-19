import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:toastification/toastification.dart';
import 'package:tryzeon/core/modules/revenue_cat/domain/entities/app_subscription_entitlement.dart';
import 'package:tryzeon/core/modules/revenue_cat/providers/revenue_cat_providers.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/feature/common/usage_quota/domain/entities/usage_quota.dart';
import 'package:tryzeon/feature/personal/tryon/presentation/actions/tryon_outcome_feedback.dart';
import 'package:tryzeon/feature/personal/tryon/presentation/controllers/tryon_controller.dart';
import 'package:tryzeon/feature/personal/tryon/presentation/state/tryon_outcome.dart';

import '../../../../../support/sheet_test_host.dart';

class _EmittingTryonController extends TryonController {
  @override
  TryonOutcome? build() => null;

  // ignore: use_setters_to_change_properties
  void emit(final TryonOutcome outcome) => state = outcome;
}

class _Listening extends ConsumerWidget {
  const _Listening();

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    listenToTryonOutcomes(context, ref);
    return const Scaffold();
  }
}

void main() {
  late ProviderContainer container;

  UsageQuota quotaOf(final AppSubscriptionTier tier) => UsageQuota(
    tier: tier,
    period: tier == AppSubscriptionTier.free
        ? QuotaPeriod.day
        : QuotaPeriod.month,
    resetsAt: DateTime.utc(2026, 11, 4, 16),
    tryonImage: const FeatureQuota(used: 10, quota: 10),
    tryonVideo: const FeatureQuota(used: 3, quota: 3),
  );

  Future<void> pumpFeedback(
    final WidgetTester tester, {
    final AppSubscriptionTier? tier = AppSubscriptionTier.free,
  }) async {
    container = ProviderContainer(
      overrides: [
        tryonControllerProvider.overrideWith(_EmittingTryonController.new),
        appSubscriptionEntitlementProvider.overrideWith(
          (final ref) => tier == null
              ? const Stream.empty()
              : Stream.value(
                  AppSubscriptionEntitlement(tier: tier, expirationDate: null),
                ),
        ),
      ],
    );
    addTearDown(container.dispose);
    container.listen(appSubscriptionEntitlementProvider, (final _, final _) {});
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const _Listening(),
        ),
      ),
    );
    await tester.pump();
  }

  void emit(final TryonOutcome outcome) =>
      (container.read(tryonControllerProvider.notifier)
              as _EmittingTryonController)
          .emit(outcome);

  testWidgets('a free daily limit offers the upgrade', (final tester) async {
    await pumpFeedback(tester);

    emit(
      TryonQuotaExceeded(
        'r1',
        isVideo: false,
        quota: quotaOf(AppSubscriptionTier.free),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('試穿次數已達上限'), findsOneWidget);
    expect(find.text('今日試穿次數已用完\n升級方案可以拿到更多次數！'), findsOneWidget);
  });

  testWidgets('a pro cycle limit names the reset date and offers the upgrade', (
    final tester,
  ) async {
    await pumpFeedback(tester, tier: AppSubscriptionTier.pro);

    emit(
      TryonQuotaExceeded(
        'r1',
        isVideo: true,
        quota: quotaOf(AppSubscriptionTier.pro),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('影片試穿次數已達上限'), findsOneWidget);
    expect(find.text('本期影片試穿次數已用完，11/5 重置\n升級方案可以拿到更多次數！'), findsOneWidget);
  });

  testWidgets('a max cycle limit notifies without an upgrade', (
    final tester,
  ) async {
    await pumpFeedback(tester, tier: AppSubscriptionTier.max);

    emit(
      TryonQuotaExceeded(
        'r1',
        isVideo: false,
        quota: quotaOf(AppSubscriptionTier.max),
      ),
    );
    await settle(tester);

    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('本期試穿次數已用完，11/5 重置'), findsOneWidget);

    toastification.dismissAll(delayForAnimation: false);
    await settle(tester);
  });

  testWidgets('a limit without a snapshot offers the upgrade without a date', (
    final tester,
  ) async {
    await pumpFeedback(tester);

    emit(const TryonQuotaExceeded('r1', isVideo: false));
    await tester.pumpAndSettle();

    expect(find.text('試穿次數已用完\n升級方案可以拿到更多次數！'), findsOneWidget);
  });

  testWidgets('a max limit without a snapshot notifies without an upgrade', (
    final tester,
  ) async {
    await pumpFeedback(tester, tier: AppSubscriptionTier.max);

    emit(const TryonQuotaExceeded('r1', isVideo: true));
    await settle(tester);

    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('影片試穿次數已用完'), findsOneWidget);

    toastification.dismissAll(delayForAnimation: false);
    await settle(tester);
  });

  testWidgets('a max snapshot wins over a lagging entitlement', (
    final tester,
  ) async {
    await pumpFeedback(tester);

    emit(
      TryonQuotaExceeded(
        'r1',
        isVideo: false,
        quota: quotaOf(AppSubscriptionTier.max),
      ),
    );
    await settle(tester);

    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('本期試穿次數已用完，11/5 重置'), findsOneWidget);

    toastification.dismissAll(delayForAnimation: false);
    await settle(tester);
  });

  testWidgets('a max snapshot notifies while the entitlement is unknown', (
    final tester,
  ) async {
    await pumpFeedback(tester, tier: null);

    emit(
      TryonQuotaExceeded(
        'r1',
        isVideo: false,
        quota: quotaOf(AppSubscriptionTier.max),
      ),
    );
    await settle(tester);

    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('本期試穿次數已用完，11/5 重置'), findsOneWidget);

    toastification.dismissAll(delayForAnimation: false);
    await settle(tester);
  });

  testWidgets('a cancelled run stays silent', (final tester) async {
    await pumpFeedback(tester);

    emit(const TryonCancelled('r1'));
    await tester.pumpAndSettle();

    expect(find.byType(Dialog), findsNothing);
    expect(find.byType(AlertDialog), findsNothing);
  });
}
