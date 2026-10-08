import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/feature/auth/providers/auth_providers.dart';
import 'package:tryzeon/feature/common/garment_type/domain/entities/garment_type.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/outfit_piece.dart';
import 'package:tryzeon/feature/personal/tryon/presentation/state/outfit_tray_controller.dart';
import 'package:tryzeon/feature/personal/wardrobe/providers/wardrobe_providers.dart';

import '../../../../../support/wardrobe_test_doubles.dart';

const _product = OutfitPiece.product(
  productId: 'p1',
  imageUrl: 'https://x/p1.jpg',
  garmentType: GarmentType.top,
);

void main() {
  late FakeWardrobeItems items;
  late ProviderContainer container;

  setUp(() {
    items = FakeWardrobeItems([
      for (final id in ['a', 'b', 'c', 'd']) wardrobeItem(id),
    ]);
    container = ProviderContainer(
      overrides: [
        isAuthenticatedProvider.overrideWithValue(true),
        wardrobeItemsProvider.overrideWith(() => items),
      ],
    );
    addTearDown(container.dispose);
    container.listen(outfitTrayProvider, (_, _) {});
  });

  OutfitTrayController tray() => container.read(outfitTrayProvider.notifier);
  OutfitTrayState state() => container.read(outfitTrayProvider);

  test('starts closed and empty', () {
    expect(state().isOpen, isFalse);
    expect(state().pieces, isEmpty);
  });

  test('open and close; close also clears', () {
    tray()
      ..open()
      ..add(wardrobePiece('a'));
    expect(state().isOpen, isTrue);

    tray().close();
    expect(state().isOpen, isFalse);
    expect(state().pieces, isEmpty);
  });

  test('add keeps insertion order and ignores duplicates', () {
    tray()
      ..add(wardrobePiece('a'))
      ..add(_product)
      ..add(wardrobePiece('a'));
    expect(state().pieces.map((final p) => p.id), ['a', 'p1']);
  });

  test('a fourth piece is refused and counted', () {
    tray()
      ..add(wardrobePiece('a'))
      ..add(wardrobePiece('b'))
      ..add(wardrobePiece('c'));

    tray().add(wardrobePiece('d'));
    expect(state().pieces.map((final p) => p.id), ['a', 'b', 'c']);
    expect(state().isFull, isTrue);
    expect(state().rejectedCount, 1);
  });

  test('toggle removes a present piece and adds an absent one', () {
    tray().toggle(wardrobePiece('a'));
    expect(state().contains('a'), isTrue);

    tray().toggle(wardrobePiece('a'));
    expect(state().contains('a'), isFalse);
  });

  test('remove by id', () {
    tray()
      ..add(wardrobePiece('a'))
      ..add(wardrobePiece('b'))
      ..remove('a');
    expect(state().pieces.map((final p) => p.id), ['b']);
  });

  test('launch returns the pieces, clears and closes', () {
    tray()
      ..open()
      ..add(wardrobePiece('a'))
      ..add(_product);

    final launched = tray().launch();

    expect(launched.map((final p) => p.id), ['a', 'p1']);
    expect(state().pieces, isEmpty);
    expect(state().isOpen, isFalse);
  });

  test('replaceWith loads the pieces and opens', () {
    tray().replaceWith([wardrobePiece('a'), _product]);

    expect(state().isOpen, isTrue);
    expect(state().pieces.map((final p) => p.id), ['a', 'p1']);
  });
}
