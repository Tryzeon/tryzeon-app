import 'package:flutter_test/flutter_test.dart';
import 'package:tryzeon/core/config/app_constants.dart';

void main() {
  test('storeWebUrl prefers the slug', () {
    expect(
      AppConstants.storeWebUrl(id: 'abc', slug: 'mia-select'),
      'https://tryzeon.com/store/mia-select',
    );
  });

  test('storeWebUrl falls back to the id without a slug', () {
    expect(
      AppConstants.storeWebUrl(id: 'abc'),
      'https://tryzeon.com/store/abc',
    );
  });
}
