import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/router/shells/personal_tab.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/feature/auth/providers/auth_providers.dart';
import 'package:tryzeon/feature/common/garment_type/domain/entities/garment_type.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/outfit_piece.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_mode.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_result.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_subject.dart';
import 'package:tryzeon/feature/personal/tryon/presentation/actions/edit_outfit.dart';
import 'package:tryzeon/feature/personal/tryon/presentation/coordinators/tryon_coordinator.dart';
import 'package:tryzeon/feature/personal/tryon/presentation/state/outfit_tray_controller.dart';
import 'package:tryzeon/feature/personal/tryon/presentation/state/tryon_gallery_entry.dart';
import 'package:tryzeon/feature/personal/wardrobe/providers/wardrobe_providers.dart';

import '../../../../../support/wardrobe_test_doubles.dart';

void main() {
  final entry = FinishedTryonEntry(
    const TryonResult(id: 'r', mode: TryonMode.image, imageUrl: 'u'),
    TryonSubject.generate(
      pieces: [wardrobePiece('a'), wardrobePiece('gone')],
      mode: TryonMode.image,
    ),
  );

  late ProviderContainer container;
  late WidgetRef capturedRef;
  late BuildContext capturedContext;
  final navigations = <PersonalTab>[];

  setUp(() async {
    navigations.clear();
    container = ProviderContainer(
      overrides: [
        isAuthenticatedProvider.overrideWithValue(true),
        wardrobeItemsProvider.overrideWith(() => FakeWardrobeItems([wardrobeItem('a')])),
      ],
    );
    addTearDown(container.dispose);
    container.read(tryonCoordinatorProvider).bindNavigation(navigations.add);
    await container.read(wardrobeItemsProvider.future);
  });

  Future<void> pump(final WidgetTester tester) => tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: Consumer(
          builder: (final context, final ref, final _) {
            capturedRef = ref;
            capturedContext = context;
            return const SizedBox();
          },
        ),
      ),
    ),
  );

  testWidgets('loads the live pieces into the dock and goes to the wardrobe', (
    final tester,
  ) async {
    await pump(tester);

    await editOutfit(capturedContext, capturedRef, entry);
    await tester.pump();

    final tray = container.read(outfitTrayProvider);
    expect(tray.isOpen, isTrue);
    expect(tray.pieces.map((final p) => p.id), ['a']);
    expect(navigations, [PersonalTab.wardrobe]);
  });

  testWidgets('asks before replacing a non-empty dock and keeps it on 取消', (
    final tester,
  ) async {
    container.read(outfitTrayProvider.notifier).add(wardrobePiece('a'));
    await pump(tester);

    final pending = editOutfit(capturedContext, capturedRef, entry);
    await tester.pumpAndSettle();
    expect(find.text('取代目前的搭配？'), findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, '取消').last);
    await tester.pumpAndSettle();
    await pending;

    expect(container.read(outfitTrayProvider).isOpen, isFalse);
    expect(navigations, isEmpty);
  });

  testWidgets('a pure shop outfit is edited in the shop', (final tester) async {
    await pump(tester);
    final shopEntry = FinishedTryonEntry(
      entry.result,
      const TryonSubject.generate(
        pieces: [
          OutfitPiece.product(
            productId: 'p1',
            name: 'Tee',
            imageUrl: 'u',
            garmentType: GarmentType.top,
          ),
        ],
        mode: TryonMode.image,
      ),
    );

    await editOutfit(capturedContext, capturedRef, shopEntry);
    await tester.pump();

    expect(navigations, [PersonalTab.shop]);
  });

  test('outfitHasLivePiece is false when every wardrobe piece is gone', () {
    final ids = container.read(wardrobeItemIdsProvider);
    final gone = FinishedTryonEntry(
      entry.result,
      TryonSubject.generate(pieces: [wardrobePiece('gone')], mode: TryonMode.image),
    );
    expect(outfitHasLivePiece(ids, gone), isFalse);
    expect(outfitHasLivePiece(ids, entry), isTrue);
  });
}
