import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/config/app_constants.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/feature/auth/providers/auth_providers.dart';
import 'package:tryzeon/feature/personal/tryon/tryon.dart';
import 'package:tryzeon/feature/personal/wardrobe/domain/entities/wardrobe_item.dart';
import 'package:tryzeon/feature/personal/wardrobe/presentation/pages/wardrobe_page.dart';
import 'package:tryzeon/feature/personal/wardrobe/presentation/widgets/wardrobe_item_card.dart';
import 'package:tryzeon/feature/personal/wardrobe/providers/wardrobe_providers.dart';

import '../../../../../support/wardrobe_test_doubles.dart';

ProviderContainer _makeContainer(final List<WardrobeItem> items) {
  return ProviderContainer(
    overrides: [
      isAuthenticatedProvider.overrideWithValue(true),
      wardrobeItemsProvider.overrideWith(() => FakeWardrobeItems(items)),
      for (final item in items)
        wardrobeItemImageProvider(
          item.imagePath,
        ).overrideWith((final ref) => Completer<File>().future),
    ],
  );
}

Widget _harness(final ProviderContainer container) {
  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      theme: AppTheme.lightTheme,
      home: const Scaffold(
        body: Stack(
          children: [
            WardrobePage(),
            Align(alignment: Alignment.bottomCenter, child: OutfitDock(isVisible: true)),
          ],
        ),
      ),
    ),
  );
}

Future<ProviderContainer> pumpPage(final WidgetTester tester) async {
  tester.view.physicalSize = const Size(800, 1400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final items = [
    for (final id in ['a', 'b', 'c', 'd']) wardrobeItem(id),
  ];
  final container = _makeContainer(items);
  addTearDown(container.dispose);
  await tester.pumpWidget(_harness(container));
  await tester.pump(AppDuration.slow);
  return container;
}

Future<void> pumpDockTransition(final WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    await tester.pump(AppDuration.standard);
  }
}

void main() {
  testWidgets('header chip enters and leaves compose mode', (final tester) async {
    await pumpPage(tester);

    await tester.tap(find.byKey(const Key('wardrobe-compose-chip')));
    await tester.pump(AppDuration.standard);
    expect(find.text('搭配中'), findsOneWidget);
    expect(find.byKey(const Key('outfit-dock')), findsOneWidget);

    await tester.tap(find.byKey(const Key('wardrobe-compose-chip')));
    await pumpDockTransition(tester);
    expect(find.text('搭配試穿'), findsOneWidget);
    expect(find.byKey(const Key('outfit-dock')), findsNothing);
  });

  testWidgets('long-press adds the card and opens the dock; tap toggles', (
    final tester,
  ) async {
    await pumpPage(tester);

    await tester.longPress(find.byType(WardrobeItemCard).at(0));
    await tester.pump(AppDuration.standard);
    expect(find.byKey(const Key('wardrobe-card-selected-badge')), findsOneWidget);
    expect(find.byKey(const Key('outfit-dock')), findsOneWidget);

    await tester.tap(find.byType(WardrobeItemCard).at(1));
    await tester.pump(AppDuration.standard);
    expect(find.byKey(const Key('wardrobe-card-selected-badge')), findsNWidgets(2));

    await tester.tap(find.byType(WardrobeItemCard).at(1));
    await tester.pump(AppDuration.standard);
    expect(find.byKey(const Key('wardrobe-card-selected-badge')), findsOneWidget);
  });

  testWidgets('a fourth card is refused inside the dock', (final tester) async {
    await pumpPage(tester);

    await tester.longPress(find.byType(WardrobeItemCard).at(0));
    await tester.pump(AppDuration.standard);
    for (final i in [1, 2, 3]) {
      await tester.tap(find.byType(WardrobeItemCard).at(i));
      await tester.pump(AppDuration.standard);
    }
    await tester.pump(AppDuration.slow);

    expect(find.byKey(const Key('wardrobe-card-selected-badge')), findsNWidgets(3));
    expect(find.text('已滿 ${AppConstants.maxTryonGarments} 件，先移除一件'), findsOneWidget);
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('dock clear exits compose mode and restores the FAB', (final tester) async {
    await pumpPage(tester);

    await tester.longPress(find.byType(WardrobeItemCard).at(0));
    await tester.pump(AppDuration.standard);
    await tester.tap(find.byKey(const Key('outfit-dock-clear')));
    await tester.pump(AppDuration.standard);

    expect(find.byKey(const Key('wardrobe-card-selected-badge')), findsNothing);
    expect(find.text('搭配試穿'), findsOneWidget);
    final fab = tester.widget<AnimatedScale>(
      find.ancestor(
        of: find.byType(FloatingActionButton),
        matching: find.byType(AnimatedScale),
      ),
    );
    expect(fab.scale, 1);
  });

  testWidgets('system back exits compose mode instead of popping the page', (
    final tester,
  ) async {
    final container = await pumpPage(tester);

    await tester.longPress(find.byType(WardrobeItemCard).at(0));
    await tester.pump(AppDuration.standard);
    expect(container.read(outfitTrayProvider).isOpen, isTrue);

    await tester.binding.handlePopRoute();
    await tester.pump(AppDuration.standard);

    expect(container.read(outfitTrayProvider).isOpen, isFalse);
    expect(find.byKey(const Key('wardrobe-card-selected-badge')), findsNothing);
    expect(find.byType(WardrobePage), findsOneWidget);
  });
}
