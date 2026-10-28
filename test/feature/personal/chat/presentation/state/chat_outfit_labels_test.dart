import 'package:flutter_test/flutter_test.dart';
import 'package:tryzeon/feature/common/garment_type/domain/entities/garment_type.dart';
import 'package:tryzeon/feature/personal/chat/presentation/state/chat_outfit_labels.dart';
import 'package:tryzeon/feature/personal/chat/presentation/state/chat_timeline.dart';
import 'package:tryzeon/feature/personal/shop/domain/entities/shop_product.dart';
import 'package:tryzeon/feature/personal/shop/domain/entities/shop_store_info.dart';
import 'package:tryzeon/feature/personal/wardrobe/domain/entities/wardrobe_item.dart';

ResolvedItem _product(
  final String id,
  final double price, {
  final GarmentType garmentType = GarmentType.top,
}) => ResolvedItem.product(
  ShopProduct(
    id: id,
    storeInfo: const ShopStoreInfo(id: 's1', name: 'Store', channels: {}),
    name: id,
    categoryId: 'c',
    garmentType: garmentType,
    price: price,
    colors: const [],
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  ),
);

ResolvedItem _wardrobe(
  final String id, {
  final GarmentType garmentType = GarmentType.top,
}) => ResolvedItem.wardrobe(
  WardrobeItem(
    id: id,
    imagePath: 'w.jpg',
    garmentType: garmentType,
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  ),
);

void main() {
  test('the purchase counts and totals only the pieces left to buy', () {
    expect(
      outfitPurchase([
        _product('a', 1280),
        _product('b', 599),
        _product('c', 699),
      ]),
      (count: 3, total: 2578.0),
    );
    expect(
      outfitPurchase([_wardrobe('w'), _product('b', 1380), _product('c', 780)]),
      (count: 2, total: 2160.0),
    );
  });

  test('a wardrobe-only look has nothing to buy', () {
    expect(outfitPurchase([_wardrobe('a'), _wardrobe('b')]), isNull);
  });

  test('a look all for sale counts its pieces; a mixed one, what is left', () {
    expect(outfitPurchaseCountLabel((count: 3, total: 2578), 3), '共 3 件');
    expect(outfitPurchaseCountLabel((count: 2, total: 2160), 3), '再買 2 件');
  });

  group('outfitCollageOrder', () {
    test('moves the outerwear to the lead and keeps the rest in order', () {
      final top = _product('top', 1280);
      final pants = _wardrobe('pants', garmentType: GarmentType.pants);
      final coat = _product('coat', 2480, garmentType: GarmentType.outerwear);

      expect(outfitCollageOrder([top, pants, coat]), [coat, top, pants]);
    });

    test('leaves a look with no outerwear, or already led by it, as it is', () {
      final plain = [
        _product('top', 1280),
        _product('skirt', 990, garmentType: GarmentType.skirt),
      ];
      final led = [
        _product('coat', 2480, garmentType: GarmentType.outerwear),
        _product('dress', 1980, garmentType: GarmentType.onePiece),
      ];

      expect(outfitCollageOrder(plain), same(plain));
      expect(outfitCollageOrder(led), same(led));
    });
  });
}
