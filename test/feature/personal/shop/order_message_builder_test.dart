import 'package:flutter_test/flutter_test.dart';
import 'package:tryzeon/feature/common/garment_type/domain/entities/garment_type.dart';
import 'package:tryzeon/feature/personal/shop/domain/entities/fit_result.dart';
import 'package:tryzeon/feature/personal/shop/domain/entities/shop_product.dart';
import 'package:tryzeon/feature/personal/shop/domain/entities/shop_store_info.dart';
import 'package:tryzeon/feature/personal/shop/domain/services/order_message_builder.dart';

import '../../../support/product_color_fixtures.dart';

ShopProduct product({required final List<String> imageUrls}) => ShopProduct(
  storeInfo: const ShopStoreInfo(id: 's1', name: 'Store', channels: {}),
  name: 'White Tee',
  categoryId: 'c1',
  garmentType: GarmentType.top,
  price: 590,
  colors: [
    if (imageUrls.isNotEmpty)
      productColorFixture(imagePaths: const ['a.jpg'], imageUrls: imageUrls),
  ],
  id: 'p1',
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

void main() {
  // The link has to sit on its own line with no prefix so LINE's and Messenger's
  // linkifiers pick up the whole URL; without that there is no preview card, and
  // the preview card is the only reason this line exists.
  test('ends with the product web url on its own line', () {
    final message = OrderMessageBuilder.build(
      product: product(imageUrls: const ['https://img/a.jpg']),
      color: product(imageUrls: const []).colors.firstOrNull,
      fitResult: const FitResult(recommendedSize: 'M'),
    );
    expect(message.split('\n').last, 'https://tryzeon.com/product/p1');
  });

  test('includes the link even when the product has no images', () {
    final message = OrderMessageBuilder.build(
      product: product(imageUrls: const []),
      color: product(imageUrls: const []).colors.firstOrNull,
      fitResult: const FitResult(recommendedSize: 'M'),
    );
    expect(message.split('\n').last, 'https://tryzeon.com/product/p1');
  });

  group('colours', () {
    final twoColors = ShopProduct(
      storeInfo: const ShopStoreInfo(id: 's1', name: 'Store', channels: {}),
      name: 'White Tee',
      categoryId: 'c1',
      garmentType: GarmentType.top,
      price: 590,
      colors: [
        productColorFixture(imagePaths: const ['a.jpg'], name: '米白'),
        productColorFixture(
          imagePaths: const ['b.jpg'],
          position: 1,
          name: '霧灰',
        ),
      ],
      id: 'p1',
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );

    test('a chosen colour adds a colour line and the colour link', () {
      final message = OrderMessageBuilder.build(
        product: twoColors,
        color: twoColors.colors[1],
        fitResult: const FitResult(recommendedSize: 'M'),
      );
      final lines = message.split('\n');
      expect(lines[2], '顏色：霧灰');
      expect(lines[3], '尺寸：M');
      expect(lines.last, 'https://tryzeon.com/product/p1?color=color-p1-1');
    });

    test('a single named colour adds neither line nor query', () {
      final single = twoColors.copyWith(colors: [twoColors.colors[0]]);
      final message = OrderMessageBuilder.build(
        product: single,
        color: single.colors[0],
        fitResult: const FitResult(recommendedSize: 'M'),
      );
      expect(message, isNot(contains('顏色')));
      expect(message.split('\n').last, 'https://tryzeon.com/product/p1');
    });
  });
}
