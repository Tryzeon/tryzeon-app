import 'package:flutter_test/flutter_test.dart';
import 'package:tryzeon/feature/common/product_attributes/domain/entities/product_attributes.dart';
import 'package:tryzeon/feature/common/store/domain/entities/store_channel.dart';
import 'package:tryzeon/feature/personal/shop/domain/entities/shop_filter.dart';

void main() {
  group('ShopFilter.normalized', () {
    test('an empty query or selection equals no filter', () {
      const filter = ShopFilter(
        searchQuery: '',
        categories: {},
        channels: {},
        materials: {},
        elasticities: {},
        fits: {},
        thicknesses: {},
        styles: {},
        seasons: {},
      );

      expect(filter.normalized(), const ShopFilter());
    });

    test('keeps picked values, an all-channels pick included', () {
      final filter = ShopFilter(
        searchQuery: '洋裝',
        fits: const {ProductFit.regular},
        channels: StoreChannel.values.toSet(),
      );

      expect(filter.normalized(), filter);
    });
  });
}
