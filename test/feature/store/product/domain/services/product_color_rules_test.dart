import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tryzeon/feature/store/product/domain/services/product_color_rules.dart';
import 'package:tryzeon/feature/store/product/domain/value_objects/color_item.dart';
import 'package:tryzeon/feature/store/product/domain/value_objects/image_item.dart';

ColorItem _color(final String? name, final int images) => ColorItem.newColor(
  name: name,
  images: [for (var i = 0; i < images; i++) File('img$i.jpg')],
);

void main() {
  test('normalizeColorName trims and treats blank as null', () {
    expect(normalizeColorName('  黑 '), '黑');
    expect(normalizeColorName('   '), isNull);
    expect(normalizeColorName(null), isNull);
  });

  test('a lone colour may be unnamed', () {
    expect(colorNameIssue(null, otherNames: const []), isNull);
  });

  test('with other colours a name is required', () {
    expect(
      colorNameIssue(' ', otherNames: const ['白']),
      ColorIssue.missingName,
    );
  });

  test('names longer than 20 characters are rejected', () {
    expect(
      colorNameIssue('色' * 21, otherNames: const []),
      ColorIssue.nameTooLong,
    );
  });

  test('duplicates compare after trimming', () {
    expect(
      colorNameIssue('黑', otherNames: const ['黑 ']),
      ColorIssue.duplicateName,
    );
  });

  test('isValidColorSet enforces colour and image counts', () {
    expect(isValidColorSet(const []), isFalse);
    expect(
      isValidColorSet([for (var i = 0; i < 11; i++) _color('色$i', 1)]),
      isFalse,
    );
    expect(
      isValidColorSet([for (var i = 0; i < 10; i++) _color('色$i', 1)]),
      isTrue,
    );
    expect(isValidColorSet([_color('黑', 0), _color('白', 1)]), isFalse);
    expect(isValidColorSet([_color('黑', 4), _color('白', 1)]), isFalse);
    expect(isValidColorSet([_color('黑', 1), _color(null, 1)]), isFalse);
    expect(isValidColorSet([_color(null, 1)]), isTrue);
  });

  test('newImageFiles lists new files in colour order', () {
    final a = File('a.jpg');
    final b = File('b.jpg');
    final c = File('c.jpg');
    final colors = [
      ColorItem.existing(
        id: 'c1',
        images: [
          const ImageItem.existing(path: 'old.jpg', url: 'u'),
          ImageItem.newImage(file: a),
        ],
      ),
      ColorItem.newColor(images: [b, c]),
    ];

    expect(colors.newImageFiles, [a, b, c]);
  });

  test(
    'colorIssuesAt checks photos and the name against the other colours',
    () {
      final colors = [_color('黑', 0), _color('黑 ', 4), _color('白', 1)];

      expect(colorIssuesAt(colors, 0), [
        ColorIssue.missingImages,
        ColorIssue.duplicateName,
      ]);
      expect(colorIssuesAt(colors, 1), [
        ColorIssue.tooManyImages,
        ColorIssue.duplicateName,
      ]);
      expect(colorIssuesAt(colors, 2), isEmpty);
    },
  );
}
