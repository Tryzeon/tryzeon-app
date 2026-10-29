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

OutfitPiece _productIn(final String colorId) => OutfitPiece.product(
  productId: 'p1',
  colorId: colorId,
  imageUrl: 'https://x/$colorId.jpg',
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
    expect(state().holds(wardrobePiece('a')), isTrue);

    tray().toggle(wardrobePiece('a'));
    expect(state().holds(wardrobePiece('a')), isFalse);
  });

  test('adding the same product in another colour replaces it in place', () {
    tray()
      ..add(_productIn('red'))
      ..add(wardrobePiece('a'))
      ..add(_productIn('blue'));
    expect(state().pieces, [_productIn('blue'), wardrobePiece('a')]);
  });

  test('replacing works on a full tray', () {
    tray()
      ..add(_productIn('red'))
      ..add(wardrobePiece('a'))
      ..add(wardrobePiece('b'))
      ..add(_productIn('blue'));
    expect(state().pieces, [
      _productIn('blue'),
      wardrobePiece('a'),
      wardrobePiece('b'),
    ]);
    expect(state().rejectedCount, 0);
  });

  test('toggle removes only the exact piece', () {
    tray()
      ..add(_productIn('red'))
      ..toggle(_productIn('blue'));
    expect(state().pieces, [_productIn('blue')]);

    tray().toggle(_productIn('blue'));
    expect(state().pieces, isEmpty);
  });

  test('holds is false for the same product in another colour', () {
    tray().add(_productIn('red'));
    expect(state().holds(_productIn('red')), isTrue);
    expect(state().holds(_productIn('blue')), isFalse);
  });

  test('statusOf tells an absent, held and other-colour piece apart', () {
    expect(state().statusOf(_productIn('red')), OutfitPieceStatus.absent);

    tray().add(_productIn('red'));

    expect(state().statusOf(_productIn('red')), OutfitPieceStatus.held);
    expect(
      state().statusOf(_productIn('blue')),
      OutfitPieceStatus.heldInOtherColor,
    );
    expect(state().statusOf(wardrobePiece('a')), OutfitPieceStatus.absent);
  });

  test('holds ignores incidental fields of the same product and colour', () {
    tray().add(_productIn('red'));
    const resized = OutfitPiece.product(
      productId: 'p1',
      colorId: 'red',
      imageUrl: 'https://x/other.jpg',
      garmentType: GarmentType.top,
      sizeId: 's2',
    );
    expect(state().holds(resized), isTrue);

    tray().toggle(resized);
    expect(state().pieces, isEmpty);
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
