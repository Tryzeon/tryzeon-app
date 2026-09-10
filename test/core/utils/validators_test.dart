import 'package:flutter_test/flutter_test.dart';
import 'package:tryzeon/core/utils/validators.dart';

void main() {
  group('validateProductDescription', () {
    test('accepts null and blank because the field is optional', () {
      expect(AppValidators.validateProductDescription(null), isNull);
      expect(AppValidators.validateProductDescription('   '), isNull);
    });

    test('accepts a description at the length limit', () {
      final text = '字' * AppValidators.productDescriptionMaxLength;
      expect(AppValidators.validateProductDescription(text), isNull);
    });

    test('rejects a description over the length limit', () {
      final text = '字' * (AppValidators.productDescriptionMaxLength + 1);
      expect(
        AppValidators.validateProductDescription(text),
        '商品描述最多 ${AppValidators.productDescriptionMaxLength} 字',
      );
    });
  });
}
