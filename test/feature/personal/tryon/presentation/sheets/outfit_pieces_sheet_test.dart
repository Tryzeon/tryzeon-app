import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/feature/auth/providers/auth_providers.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_mode.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_result.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_subject.dart';
import 'package:tryzeon/feature/personal/tryon/presentation/actions/edit_outfit.dart';
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

  setUp(() async {
    container = ProviderContainer(
      overrides: [
        isAuthenticatedProvider.overrideWithValue(true),
        wardrobeItemsProvider.overrideWith(
          () => FakeWardrobeItems([wardrobeItem('a'), wardrobeItem('b')]),
        ),
        wardrobeItemImageProvider.overrideWith(
          (final ref, final imagePath) => Completer<File>().future,
        ),
      ],
    );
    addTearDown(container.dispose);
    await container.read(wardrobeItemsProvider.future);
  });

  Future<void> pumpHost(final WidgetTester tester) => tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: Consumer(
          builder: (final context, final ref, final _) => Scaffold(
            body: Center(
              child: ElevatedButton(
                key: const Key('open-sheet'),
                onPressed: () => showOutfitPieces(context, ref, entry),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    ),
  );

  testWidgets('編輯搭配 from the sheet replaces the dock once confirmed', (
    final tester,
  ) async {
    container.read(outfitTrayProvider.notifier).add(wardrobePiece('b'));
    await pumpHost(tester);

    await tester.tap(find.byKey(const Key('open-sheet')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    await tester.tap(find.text('編輯搭配'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('取代目前的搭配？'), findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, '取代').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));

    final tray = container.read(outfitTrayProvider);
    expect(tray.isOpen, isTrue);
    expect(tray.pieces.map((final p) => p.id), ['a']);
  });
}
