import 'package:flutter_test/flutter_test.dart';
import 'package:tryzeon/feature/common/garment_type/domain/entities/garment_type.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/outfit_piece.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_garment.dart';

void main() {
  const wardrobe = OutfitPiece.wardrobe(
    wardrobeItemId: 'w1',
    imagePath: 'u/w1.jpg',
    garmentType: GarmentType.top,
  );
  const product = OutfitPiece.product(
    productId: 'p1',
    imageUrl: 'https://x/p1.jpg',
    garmentType: GarmentType.top,
    sizeId: 'M',
  );
  const local = OutfitPiece.local(path: '/tmp/x.jpg');

  test('id is the source id', () {
    expect(wardrobe.id, 'w1');
    expect(product.id, 'p1');
    expect(local.id, '/tmp/x.jpg');
  });

  test('garment maps referenced pieces and leaves local for the launcher', () {
    expect(wardrobe.garment, const TryonGarment.wardrobe(wardrobeItemId: 'w1'));
    expect(
      product.garment,
      const TryonGarment.product(productId: 'p1', sizeId: 'M'),
    );
    expect(local.garment, isNull);
  });
}
