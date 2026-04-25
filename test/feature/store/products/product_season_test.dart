import 'package:flutter_test/flutter_test.dart';
import 'package:tryzeon/feature/store/products/domain/value_objects/product_attributes.dart';
import 'package:tryzeon/feature/store/products/presentation/extensions/product_attributes_extension.dart';

void main() {
  group('ProductSeason', () {
    test('parses persisted values', () {
      expect(ProductSeason.tryFromString('spring'), ProductSeason.spring);
      expect(ProductSeason.tryFromString('winter'), ProductSeason.winter);
      expect(ProductSeason.tryFromString('unknown'), isNull);
      expect(ProductSeason.tryFromString(null), isNull);
    });

    test('exposes localized labels for the UI', () {
      expect(ProductSeason.spring.label, '春');
      expect(ProductSeason.summer.label, '夏');
      expect(ProductSeason.autumn.label, '秋');
      expect(ProductSeason.winter.label, '冬');
    });
  });
}
