import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/core/modules/revenue_cat/domain/entities/app_subscription_entitlement.dart';
import 'package:tryzeon/core/modules/revenue_cat/providers/revenue_cat_providers.dart';
import 'package:tryzeon/feature/personal/settings/domain/entities/tryon_preferences.dart';
import 'package:tryzeon/feature/personal/settings/providers/settings_providers.dart';
import 'package:tryzeon/feature/personal/subscription/domain/entities/subscription_capabilities.dart';
import 'package:tryzeon/feature/personal/subscription/providers/subscription_capabilities_provider.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_engine.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_mode.dart';
import 'package:tryzeon/feature/personal/tryon/presentation/sheets/tryon_mode_sheet.dart';
import 'package:tryzeon/feature/personal/usage/domain/entities/daily_usage.dart';
import 'package:tryzeon/feature/personal/usage/providers/daily_usage_providers.dart';
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

class _FakeUsage extends DailyUsageToday {
  _FakeUsage({required this.tryonCount, required this.videoCount});

  final int tryonCount;
  final int videoCount;

  @override
  Future<DailyUsage> build() async => DailyUsage(
    userId: 'u1',
    usageDate: DateTime(2026),
    tryonCount: tryonCount,
    chatCount: 0,
    videoCount: videoCount,
  );
}

void main() {
  const customPreferences = TryonPreferences(
    scenePrompt: '都會街頭',
    engine: TryonEngine.experimental,
  );

  late _FakePreferences preferences;

  Future<List<TryonMode>> open(
    final WidgetTester tester, {
    final bool hasVideoAccess = true,
    final Future<SubscriptionCapabilities> Function()? capabilities,
    final int tryonCount = 0,
    final int videoCount = 0,
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
        dailyUsageTodayProvider.overrideWith(
          () => _FakeUsage(tryonCount: tryonCount, videoCount: videoCount),
        ),
        appSubscriptionEntitlementProvider.overrideWith(
          (final ref) => tier == null
              ? const Stream.empty()
              : Stream.value(
                  AppSubscriptionEntitlement(tier: tier, expirationDate: null),
                ),
        ),
        subscriptionCapabilitiesProvider.overrideWith(
          (final ref) =>
              capabilities?.call() ??
              Future.value(
                SubscriptionCapabilities(
                  wardrobeLimit: 10,
                  dailyTryonLimit: 10,
                  dailyChatLimit: 10,
                  dailyVideoLimit: hasVideoAccess ? 2 : 0,
                ),
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

  testWidgets('shows the remaining quota per mode', (final tester) async {
    await open(tester, tryonCount: 3, videoCount: 1);

    expect(find.text('今日剩 7 次'), findsOneWidget);
    expect(find.text('今日剩 1 次'), findsOneWidget);
  });

  testWidgets('offers an upgrade instead of a locked video mode', (
    final tester,
  ) async {
    final picked = await open(
      tester,
      hasVideoAccess: false,
      tier: AppSubscriptionTier.free,
    );

    expect(find.text('升級至 Max 方案解鎖'), findsOneWidget);
    expect(picked, isEmpty);
  });

  testWidgets('keeps video open while capabilities load', (final tester) async {
    final picked = await open(
      tester,
      capabilities: () => Completer<SubscriptionCapabilities>().future,
    );

    await tester.tap(find.text('影片試穿'));
    await settle(tester);

    expect(picked, [TryonMode.video]);
  });

  testWidgets('keeps video open when capabilities fail to load', (
    final tester,
  ) async {
    final picked = await open(
      tester,
      capabilities: () => Future.error(Exception('capabilities unavailable')),
    );

    await tester.tap(find.text('影片試穿'));
    await settle(tester);

    expect(picked, [TryonMode.video]);
  });

  testWidgets('blocks an exhausted mode and offers more quota', (
    final tester,
  ) async {
    await open(tester, tryonCount: 10, tier: AppSubscriptionTier.pro);

    expect(find.text('今日次數已用完'), findsOneWidget);
    expect(find.text('升級方案取得更多次數'), findsOneWidget);
  });

  testWidgets('blocks an exhausted mode on the top tier without an upsell', (
    final tester,
  ) async {
    final picked = await open(tester, tryonCount: 10);

    await tester.tap(find.text('圖片試穿'));
    await settle(tester);

    expect(find.text('今日次數已用完，明天再來試試'), findsOneWidget);
    expect(find.text('升級方案取得更多次數'), findsNothing);
    expect(picked, isEmpty);
  });

  testWidgets(
    'offers no upsell for an exhausted mode before the tier is known',
    (final tester) async {
      await open(tester, tryonCount: 10, tier: null);

      expect(find.text('今日次數已用完，明天再來試試'), findsOneWidget);
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
