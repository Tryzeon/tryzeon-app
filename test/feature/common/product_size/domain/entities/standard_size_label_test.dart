import 'package:collection/collection.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tryzeon/feature/common/product_size/domain/entities/standard_size_label.dart';

void main() {
  group('StandardSizeLabel.tryParse', () {
    test('recognizes the standard spellings, ignoring case and whitespace', () {
      expect(StandardSizeLabel.tryParse('M'), StandardSizeLabel.m);
      expect(StandardSizeLabel.tryParse(' m '), StandardSizeLabel.m);
      expect(StandardSizeLabel.tryParse('xl'), StandardSizeLabel.xl);
      expect(StandardSizeLabel.tryParse('2XL'), StandardSizeLabel.xxl);
    });

    test('does not fold aliases: XXL is a custom size, not 2XL', () {
      expect(StandardSizeLabel.tryParse('XXL'), isNull);
      expect(StandardSizeLabel.xxl.display, '2XL');
    });

    test(
      'free size matches the literal only; F/free are always custom sizes',
      () {
        expect(StandardSizeLabel.tryParse('均碼'), StandardSizeLabel.free);
        expect(StandardSizeLabel.tryParse('F'), isNull);
        expect(StandardSizeLabel.tryParse('free'), isNull);
        expect(StandardSizeLabel.tryParse('One Size'), isNull);
      },
    );

    test('an unrecognized name returns null, meaning a custom size', () {
      expect(StandardSizeLabel.tryParse('4XL'), isNull);
      expect(StandardSizeLabel.tryParse('US 10'), isNull);
      expect(StandardSizeLabel.tryParse(''), isNull);
    });
  });

  group('StandardSizeLabel.matchKeyOf', () {
    test(
      'only trims and upper-cases, so case differences are the same size',
      () {
        expect(StandardSizeLabel.matchKeyOf(' m '), 'M');
        expect(StandardSizeLabel.matchKeyOf('us 10'), 'US 10');
      },
    );

    test('aliases are no longer folded: XXL and 2XL are different keys', () {
      expect(
        StandardSizeLabel.matchKeyOf('XXL'),
        isNot(StandardSizeLabel.matchKeyOf('2XL')),
      );
    });
  });

  group('compareSizeLabels', () {
    test('orders standard sizes, then custom sizes, then free size', () {
      final labels = ['均碼', '4XL', 'L', 'XS', '2XL', 'M']
        ..sort(compareSizeLabels);

      expect(labels, ['XS', 'M', 'L', '2XL', '4XL', '均碼']);
    });

    test('custom sizes compare as equal', () {
      expect(compareSizeLabels('4XL', 'US 10'), 0);
    });

    test('a stable sort keeps custom sizes in their existing order', () {
      final labels = ['US 10', '均碼', '5XL', 'S', 'XXL', '4XL'];
      mergeSort(labels, compare: compareSizeLabels);

      expect(labels, ['S', 'US 10', '5XL', 'XXL', '4XL', '均碼']);
    });
  });
}
