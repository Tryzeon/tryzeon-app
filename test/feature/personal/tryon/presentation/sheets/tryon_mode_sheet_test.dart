import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/core/modules/revenue_cat/domain/entities/app_subscription_entitlement.dart';
import 'package:tryzeon/core/modules/revenue_cat/providers/revenue_cat_providers.dart';
import 'package:tryzeon/feature/common/usage_quota/domain/entities/usage_quota.dart';
import 'package:tryzeon/feature/personal/settings/domain/entities/tryon_preferences.dart';
import 'package:tryzeon/feature/personal/settings/providers/settings_providers.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_engine.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_mode.dart';
import 'package:tryzeon/feature/personal/tryon/presentation/sheets/tryon_mode_sheet.dart';
import 'package:tryzeon/feature/personal/usage/providers/usage_quota_providers.dart';
import 'package:typed_result/typed_result.dart';

import '../../../../../support/sheet_test_host.dart';

class _FakePreferences extends TryonPreferencesNotifier {
  _FakePreferences(this._initial);

  final TryonPreferences _initial;
  final saved = <TryonPreferences>[];

  @override
  Future<TryonPreferences> build() async => _initial;

  @override
  Future<Result<void, Failure>> save(final TryonPreferences preferences) async {
    saved.add(preferences);
    state = AsyncData(preferences);
    return const Ok(null);
  }
}

class _LoadingPreferences extends TryonPreferencesNotifier {
  @override
  Future<TryonPreferences> build() => Completer<TryonPreferences>().future;
}

class _FakeUsageQuota extends UsageQuotaNotifier {
  _FakeUsageQuota(this._load);

  final Future<UsageQuota> Function() _load;

  @override
  Future<UsageQuota> build() => _load();
}

void main() {
  const customPreferences = TryonPreferences(
    scenePrompt: '都會街頭',
    engine: TryonEngine.experimental,
  );
  final taipeiNov5 = DateTime.utc(2026, 11, 4, 16);

  UsageQuota freeQuota({final int tryonImageUsed = 0}) => UsageQuota(
    tier: AppSubscriptionTier.free,
    period: QuotaPeriod.day,
    resetsAt: DateTime.utc(2026, 10, 19, 16),
    tryonImage: FeatureQuota(used: tryonImageUsed, quota: 10),
    tryonVideo: const FeatureQuota(used: 0, quota: 0),
  );

  UsageQuota proQuota({
    final int tryonImageUsed = 0,
    final int tryonVideoUsed = 0,
  }) => UsageQuota(
    tier: AppSubscriptionTier.pro,
    period: QuotaPeriod.month,
    resetsAt: taipeiNov5,
    tryonImage: FeatureQuota(used: tryonImageUsed, quota: 250),
    tryonVideo: FeatureQuota(used: tryonVideoUsed, quota: 3),
  );

  UsageQuota maxQuota({final int tryonImageUsed = 0}) => UsageQuota(
    tier: AppSubscriptionTier.max,
    period: QuotaPeriod.month,
    resetsAt: taipeiNov5,
    tryonImage: FeatureQuota(used: tryonImageUsed, quota: 600),
    tryonVideo: const FeatureQuota(used: 0, quota: 10),
  );

  late _FakePreferences preferences;

  Future<List<TryonMode>> open(
    final WidgetTester tester, {
    final Future<UsageQuota> Function()? quota,
    final AppSubscriptionTier? tier = AppSubscriptionTier.max,
    final TryonPreferences initial = const TryonPreferences(),
    final bool preferencesLoaded = true,
  }) async {
    preferences = _FakePreferences(initial);
    final picked = <TryonMode>[];
    await openSheet<void>(
      tester,
      (final context) =>
          TryonModeSheet.show(context: context, onModeSelected: picked.add),
      overrides: [
        tryonPreferencesProvider.overrideWith(
          () => preferencesLoaded ? preferences : _LoadingPreferences(),
        ),
        usageQuotaProvider.overrideWith(
          () => _FakeUsageQuota(quota ?? () async => maxQuota()),
        ),
        appSubscriptionEntitlementProvider.overrideWith(
          (final ref) => tier == null
              ? const Stream.empty()
              : Stream.value(
                  AppSubscriptionEntitlement(tier: tier, expirationDate: null),
                ),
        ),
      ],
    );
    return picked;
  }

  Future<void> openSettings(final WidgetTester tester) async {
    await tester.tap(find.byTooltip('試穿設定'));
    await settle(tester);
  }

  FilledButton saveButton(final WidgetTester tester) =>
      tester.widget<FilledButton>(find.widgetWithText(FilledButton, '儲存'));

  TextButton resetButton(final WidgetTester tester) =>
      tester.widget<TextButton>(find.widgetWithText(TextButton, '重置'));

  testWidgets('closes and reports the picked mode', (final tester) async {
    final picked = await open(tester);

    await tester.tap(find.text('圖片試穿'));
    await settle(tester);

    expect(find.byType(TryonModeSheet), findsNothing);
    expect(picked, [TryonMode.image]);
  });

  testWidgets('shows the daily remaining quota for free', (final tester) async {
    await open(
      tester,
      quota: () async => freeQuota(tryonImageUsed: 3),
      tier: AppSubscriptionTier.free,
    );

    expect(find.text('今日剩 7 次'), findsOneWidget);
  });

  testWidgets('shows the cycle remaining quota and reset date for pro', (
    final tester,
  ) async {
    await open(
      tester,
      quota: () async => proQuota(tryonImageUsed: 12, tryonVideoUsed: 1),
      tier: AppSubscriptionTier.pro,
    );

    expect(find.text('本期剩 238 次 · 11/5 重置'), findsOneWidget);
    expect(find.text('本期剩 2 次 · 11/5 重置'), findsOneWidget);
  });

  testWidgets('offers an upgrade instead of a locked video mode', (
    final tester,
  ) async {
    final picked = await open(
      tester,
      quota: () async => freeQuota(),
      tier: AppSubscriptionTier.free,
    );

    expect(find.byIcon(Icons.lock_rounded), findsOneWidget);
    expect(find.text('升級方案解鎖'), findsOneWidget);
    expect(picked, isEmpty);
  });

  testWidgets('mode sheet stays open while quota is loading', (
    final tester,
  ) async {
    final picked = await open(
      tester,
      quota: () => Completer<UsageQuota>().future,
      tier: AppSubscriptionTier.free,
    );

    expect(find.byIcon(Icons.lock_rounded), findsNothing);

    await tester.tap(find.text('圖片試穿'));
    await settle(tester);
    await tester.tap(find.text('open'));
    await settle(tester);
    await tester.tap(find.text('影片試穿'));
    await settle(tester);

    expect(picked, [TryonMode.image, TryonMode.video]);
  });

  testWidgets('keeps video open when quota fails to load', (
    final tester,
  ) async {
    final picked = await open(
      tester,
      quota: () => Future.error(Exception('quota unavailable')),
      tier: AppSubscriptionTier.free,
    );

    await tester.tap(find.text('影片試穿'));
    await settle(tester);

    expect(picked, [TryonMode.video]);
  });

  testWidgets('blocks an exhausted cycle on pro and offers more quota', (
    final tester,
  ) async {
    final picked = await open(
      tester,
      quota: () async => proQuota(tryonImageUsed: 250),
      tier: AppSubscriptionTier.pro,
    );

    expect(find.text('本期次數已用完，11/5 重置'), findsOneWidget);
    expect(find.text('升級方案取得更多次數'), findsOneWidget);
    expect(picked, isEmpty);
  });

  testWidgets('blocks an exhausted cycle on the top tier without an upsell', (
    final tester,
  ) async {
    final picked = await open(
      tester,
      quota: () async => maxQuota(tryonImageUsed: 600),
    );

    await tester.tap(find.text('圖片試穿'));
    await settle(tester);

    expect(find.text('本期次數已用完，11/5 重置'), findsOneWidget);
    expect(find.text('升級方案取得更多次數'), findsNothing);
    expect(picked, isEmpty);
  });

  testWidgets('blocks an exhausted day on free and offers more quota', (
    final tester,
  ) async {
    await open(
      tester,
      quota: () async => freeQuota(tryonImageUsed: 10),
      tier: AppSubscriptionTier.free,
    );

    expect(find.text('今日次數已用完'), findsOneWidget);
    expect(find.text('升級方案取得更多次數'), findsOneWidget);
  });

  testWidgets(
    'offers no upsell for an exhausted mode before the tier is known',
    (final tester) async {
      await open(
        tester,
        quota: () async => freeQuota(tryonImageUsed: 10),
        tier: null,
      );

      expect(find.text('今日次數已用完'), findsOneWidget);
      expect(find.text('升級方案取得更多次數'), findsNothing);
    },
  );

  testWidgets('opens settings within the same sheet and goes back', (
    final tester,
  ) async {
    await open(tester);

    await openSettings(tester);

    expect(find.text('試穿設定'), findsOneWidget);
    expect(find.byType(BottomSheet), findsOneWidget);

    await tester.tap(find.byTooltip('返回'));
    await settle(tester);

    expect(find.text('選擇試穿方式'), findsOneWidget);
  });

  testWidgets('keeps settings closed until preferences load', (
    final tester,
  ) async {
    await open(tester, preferencesLoaded: false);

    final settingsButton = find.ancestor(
      of: find.byTooltip('試穿設定'),
      matching: find.byType(IconButton),
    );
    expect(tester.widget<IconButton>(settingsButton).onPressed, isNull);
  });

  testWidgets('system back from settings returns to the modes', (
    final tester,
  ) async {
    await open(tester);
    await openSettings(tester);

    await tester.binding.handlePopRoute();
    await settle(tester);

    expect(find.byType(TryonModeSheet), findsOneWidget);
    expect(find.text('選擇試穿方式'), findsOneWidget);
  });

  testWidgets('summarizes shared settings above the modes', (
    final tester,
  ) async {
    await open(tester, initial: customPreferences);

    expect(find.text('場景：都會街頭、實驗模型'), findsOneWidget);
  });

  testWidgets('shows the transition on the video card only', (
    final tester,
  ) async {
    await open(
      tester,
      initial: const TryonPreferences(transitionPrompt: '一鏡到底'),
    );

    expect(find.text('轉場：一鏡到底'), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right_rounded), findsNothing);
  });

  testWidgets('shows no summary without custom settings', (final tester) async {
    await open(tester);

    expect(find.textContaining('場景：'), findsNothing);
  });

  testWidgets('offers the transition setting with video access', (
    final tester,
  ) async {
    await open(tester);
    await openSettings(tester);

    expect(find.text('轉場'), findsOneWidget);
  });

  testWidgets('shows the transition setting while quota loads', (
    final tester,
  ) async {
    await open(tester, quota: () => Completer<UsageQuota>().future);
    await openSettings(tester);

    expect(find.text('轉場'), findsOneWidget);
  });

  testWidgets('saves nothing until there is a change', (final tester) async {
    await open(tester);
    await openSettings(tester);

    expect(saveButton(tester).onPressed, isNull);
  });

  testWidgets('keeps edits local until saved', (final tester) async {
    await open(tester);
    await openSettings(tester);

    await tester.tap(find.text('都會街頭'));
    await settle(tester);
    expect(preferences.saved, isEmpty);

    await tester.tap(find.byTooltip('返回'));
    await settle(tester);

    expect(preferences.saved, isEmpty);
    expect(find.textContaining('場景：'), findsNothing);
  });

  testWidgets('save persists the draft and returns to the modes', (
    final tester,
  ) async {
    await open(tester);
    await openSettings(tester);

    await tester.tap(find.text('都會街頭'));
    await settle(tester);
    await tester.tap(find.text('儲存'));
    await settle(tester);

    expect(preferences.saved, [const TryonPreferences(scenePrompt: '都會街頭')]);
    expect(find.text('選擇試穿方式'), findsOneWidget);
    expect(find.text('場景：都會街頭'), findsOneWidget);
  });

  testWidgets('offers no reset when already on defaults', (final tester) async {
    await open(tester);
    await openSettings(tester);

    expect(resetButton(tester).onPressed, isNull);
  });

  testWidgets('reset restores defaults without saving', (final tester) async {
    await open(tester, initial: customPreferences);
    await openSettings(tester);

    await tester.tap(find.text('重置'));
    await settle(tester);

    expect(preferences.saved, isEmpty);
    expect(resetButton(tester).onPressed, isNull);

    await tester.tap(find.text('儲存'));
    await settle(tester);

    expect(preferences.saved, [const TryonPreferences()]);
  });
}
