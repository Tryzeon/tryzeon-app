import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/config/app_constants.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/feature/auth/providers/auth_providers.dart';
import 'package:tryzeon/feature/common/garment_type/domain/entities/garment_type.dart';
import 'package:tryzeon/feature/personal/subscription/domain/entities/subscription_capabilities.dart';
import 'package:tryzeon/feature/personal/subscription/providers/subscription_capabilities_provider.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/outfit_piece.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_mode.dart';
import 'package:tryzeon/feature/personal/tryon/presentation/controllers/tryon_controller.dart';
import 'package:tryzeon/feature/personal/tryon/presentation/sheets/tryon_mode_sheet.dart';
import 'package:tryzeon/feature/personal/tryon/presentation/state/outfit_tray_controller.dart';
import 'package:tryzeon/feature/personal/tryon/presentation/state/tryon_outcome.dart';
import 'package:tryzeon/feature/personal/tryon/presentation/widgets/outfit_dock.dart';
import 'package:tryzeon/feature/personal/wardrobe/providers/wardrobe_providers.dart';

import '../../../../../support/wardrobe_test_doubles.dart';

class _RecordingTryonController extends TryonController {
  final calls = <(List<OutfitPiece>, TryonMode)>[];

  @override
  TryonOutcome? build() => null;

  @override
  Future<void> tryonFromOutfit(
    final List<OutfitPiece> pieces, {
    final TryonMode mode = TryonMode.image,
  }) async => calls.add((pieces, mode));
}

void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer(
      overrides: [
        isAuthenticatedProvider.overrideWithValue(true),
        wardrobeItemsProvider.overrideWith(
          () => FakeWardrobeItems([
            for (final id in ['a', 'b', 'c', 'd']) wardrobeItem(id),
          ]),
        ),
        wardrobeItemImageProvider.overrideWith(
          (final ref, final imagePath) => Completer<File>().future,
        ),
        subscriptionCapabilitiesProvider.overrideWith(
          (final ref) async => const SubscriptionCapabilities(
            wardrobeLimit: 100,
            dailyTryonLimit: 100,
            dailyChatLimit: 100,
            dailyVideoLimit: 100,
          ),
        ),
        tryonControllerProvider.overrideWith(_RecordingTryonController.new),
      ],
    );
    addTearDown(container.dispose);
  });

  Future<void> pumpDock(
    final WidgetTester tester, {
    final bool isVisible = true,
  }) {
    return tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Align(
              alignment: Alignment.bottomCenter,
              child: OutfitDock(isVisible: isVisible),
            ),
          ),
        ),
      ),
    );
  }

  OutfitTrayController tray() => container.read(outfitTrayProvider.notifier);

  testWidgets('hidden while closed or on a tab without a dock', (
    final tester,
  ) async {
    await pumpDock(tester);
    expect(find.byKey(const Key('outfit-dock')), findsNothing);

    tray().open();
    await tester.pump(AppDuration.standard);
    expect(find.byKey(const Key('outfit-dock')), findsOneWidget);

    await pumpDock(tester, isVisible: false);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('outfit-dock')), findsNothing);
  });

  testWidgets('empty dock shows the hint and disables launch', (
    final tester,
  ) async {
    tray().open();
    await pumpDock(tester);
    await tester.pump(AppDuration.standard);

    expect(
      find.text('點選衣物加入搭配，最多 ${AppConstants.maxTryonGarments} 件'),
      findsOneWidget,
    );
    final launch = tester.widget<FilledButton>(
      find.byKey(const Key('outfit-dock-launch')),
    );
    expect(launch.onPressed, isNull);
  });

  testWidgets('slots show type labels and remove on tap', (final tester) async {
    tray()
      ..open()
      ..add(wardrobePiece('a', GarmentType.top))
      ..add(wardrobePiece('b', GarmentType.pants));
    await pumpDock(tester);
    await tester.pump(AppDuration.standard);

    expect(find.text('上衣'), findsOneWidget);
    expect(find.text('褲子'), findsOneWidget);
    expect(find.byKey(const Key('outfit-slot-2')), findsOneWidget);

    await tester.tap(find.byKey(const Key('outfit-slot-remove-a')));
    await tester.pump(AppDuration.standard);

    expect(container.read(outfitTrayProvider).pieces.map((final p) => p.id), [
      'b',
    ]);
  });

  testWidgets('a refused fourth piece shows the cap line, then hides it', (
    final tester,
  ) async {
    tray()
      ..open()
      ..add(wardrobePiece('a', GarmentType.top))
      ..add(wardrobePiece('b', GarmentType.top))
      ..add(wardrobePiece('c', GarmentType.top));
    await pumpDock(tester);
    await tester.pump(AppDuration.standard);

    tray().add(wardrobePiece('d', GarmentType.top));
    await tester.pump();
    await tester.pump(AppDuration.slow);
    expect(
      find.text('已滿 ${AppConstants.maxTryonGarments} 件，先移除一件'),
      findsOneWidget,
    );

    await tester.pump(const Duration(seconds: 2));
    await tester.pump(AppDuration.standard);
    expect(
      find.text('已滿 ${AppConstants.maxTryonGarments} 件，先移除一件'),
      findsNothing,
    );
  });

  testWidgets('clear closes the dock', (final tester) async {
    tray()
      ..open()
      ..add(wardrobePiece('a', GarmentType.top));
    await pumpDock(tester);
    await tester.pump(AppDuration.standard);

    await tester.tap(find.byKey(const Key('outfit-dock-clear')));
    await tester.pump(AppDuration.standard);

    expect(container.read(outfitTrayProvider).isOpen, isFalse);
    expect(container.read(outfitTrayProvider).pieces, isEmpty);
  });

  testWidgets(
    'launch opens the mode sheet and hands the outfit to the coordinator',
    (final tester) async {
      tray()
        ..open()
        ..add(wardrobePiece('a', GarmentType.top))
        ..add(wardrobePiece('b', GarmentType.pants));
      await pumpDock(tester);
      await tester.pump(AppDuration.standard);

      await tester.tap(find.byKey(const Key('outfit-dock-launch')));
      await tester.pump();
      await tester.pump(AppDuration.standard);
      await tester.pump(AppDuration.standard);

      expect(find.byType(TryonModeSheet), findsOneWidget);

      await tester.tap(find.text('圖片試穿'));
      await tester.pump();
      await tester.pump(AppDuration.standard);
      await tester.pump(AppDuration.standard);

      expect(container.read(outfitTrayProvider).isOpen, isFalse);
      expect(container.read(outfitTrayProvider).pieces, isEmpty);

      final controller =
          container.read(tryonControllerProvider.notifier)
              as _RecordingTryonController;
      expect(controller.calls, hasLength(1));
      expect(controller.calls.single.$1.map((final p) => p.id), ['a', 'b']);
      expect(controller.calls.single.$2, TryonMode.image);
    },
  );
}
