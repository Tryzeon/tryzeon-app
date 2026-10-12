import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/feature/store/account/presentation/widgets/store_account_header.dart';
import 'package:tryzeon/feature/store/profile/domain/entities/store_profile.dart';
import 'package:tryzeon/feature/store/profile/providers/store_profile_providers.dart';

import '../../../../../support/store_test_doubles.dart';

Future<void> pump(
  final WidgetTester tester,
  final Future<StoreProfile?> Function() load,
) async {
  useNarrowScreen(tester);

  await tester.pumpWidget(
    ProviderScope(
      retry: (final _, final _) => null,
      overrides: [
        storeProfileProvider.overrideWith(() => FakeStoreProfile(load)),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: const Scaffold(body: StoreAccountHeader()),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows name, channels and share for a loaded profile', (
    final tester,
  ) async {
    await pump(tester, () async => storeProfile());

    expect(find.text('Mia Select 選物'), findsOneWidget);
    expect(find.text('實體店面 · 線上店家'), findsOneWidget);
    expect(find.text('分享'), findsOneWidget);
  });

  testWidgets('omits the channel line when there are no channels', (
    final tester,
  ) async {
    await pump(tester, () async => storeProfile(channels: const {}));

    expect(find.textContaining('實體店面'), findsNothing);
    expect(find.textContaining('線上店家'), findsNothing);
  });

  testWidgets('a missing profile has no share button', (final tester) async {
    await pump(tester, () async => null);

    expect(find.text('尚未建立店家資料'), findsOneWidget);
    expect(find.text('分享'), findsNothing);
  });

  testWidgets('a failed load says so and has no share button', (
    final tester,
  ) async {
    await pump(tester, () async => throw const UnknownFailure('boom'));

    expect(find.text('載入店家資料失敗'), findsOneWidget);
    expect(find.text('分享'), findsNothing);
  });

  testWidgets('a very long name ellipsizes on a narrow screen', (
    final tester,
  ) async {
    await pump(tester, () async => storeProfile(name: '超' * 80));

    expect(tester.takeException(), isNull);
  });

  testWidgets('share anchors the share sheet to the button for iPad', (
    final tester,
  ) async {
    const channel = MethodChannel('dev.fluttercommunity.plus/share');
    Map<Object?, Object?>? args;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
      final call,
    ) async {
      args = call.arguments as Map<Object?, Object?>;
      return 'dev.fluttercommunity.plus/share/unavailable';
    });
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        null,
      ),
    );
    await pump(tester, () async => storeProfile());

    await tester.tap(find.text('分享'));
    await tester.pumpAndSettle();

    expect(args?['text'], 'https://tryzeon.com/store/s1');
    expect(args?['originWidth'], greaterThan(0));
  });
}
