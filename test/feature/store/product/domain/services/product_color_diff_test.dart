import 'package:flutter_test/flutter_test.dart';
import 'package:tryzeon/feature/store/product/domain/entities/product.dart';
import 'package:tryzeon/feature/store/product/domain/services/product_color_diff.dart';

import '../../../../../support/product_color_fixtures.dart';

void main() {
  final black = productColorFixture(
    imagePaths: const ['a.jpg'],
  ).copyWith(name: '黑');
  final white = productColorFixture(
    imagePaths: const ['b.jpg'],
    position: 1,
  ).copyWith(name: '白');

  ColorTarget kept(final ProductColor color) => ExistingColorTarget(
    id: color.id,
    name: color.name,
    imagePaths: color.imagePaths,
  );

  test('unchanged colours produce an empty diff', () {
    expect(
      computeColorDiff([black, white], [kept(black), kept(white)]).isEmpty,
      isTrue,
    );
  });

  test('a new colour is added at its list position', () {
    final diff = computeColorDiff(
      [black],
      [
        kept(black),
        const NewColorTarget(name: '紅', imagePaths: ['c.jpg']),
      ],
    );

    expect(diff.toAdd.single.position, 1);
    expect(diff.toAdd.single.imagePaths, ['c.jpg']);
    expect(diff.toAdd.single.name, '紅');
    expect(diff.toUpdate, isEmpty);
  });

  test('moving the second colour first rewrites both positions', () {
    final diff = computeColorDiff([black, white], [kept(white), kept(black)]);

    expect(
      {
        for (final update in diff.toUpdate)
          update.target.id: update.target.position,
      },
      {white.id: 0, black.id: 1},
    );
    expect(diff.toAdd, isEmpty);
    expect(diff.idsToDelete, isEmpty);
  });

  test('an original colour missing from the target is deleted', () {
    final diff = computeColorDiff([black, white], [kept(black)]);

    expect(diff.idsToDelete, [white.id]);
    expect(diff.toUpdate, isEmpty);
  });

  test('names are trimmed and a blank name becomes null', () {
    final diff = computeColorDiff(
      [black, white],
      [
        ExistingColorTarget(
          id: black.id,
          name: ' 霧灰 ',
          imagePaths: black.imagePaths,
        ),
        ExistingColorTarget(
          id: white.id,
          name: '  ',
          imagePaths: white.imagePaths,
        ),
      ],
    );

    expect(
      {
        for (final update in diff.toUpdate)
          update.target.id: update.target.name,
      },
      {black.id: '霧灰', white.id: null},
    );
    expect(diff.toUpdate.first.original, black);
  });

  test('a target whose row is gone is skipped rather than re-inserted', () {
    final diff = computeColorDiff(
      [black],
      [
        kept(black),
        const ExistingColorTarget(id: 'gone', imagePaths: ['x.jpg']),
      ],
    );

    expect(diff.isEmpty, isTrue);
  });
}
