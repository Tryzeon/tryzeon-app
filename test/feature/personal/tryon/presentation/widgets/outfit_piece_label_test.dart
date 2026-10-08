import 'package:flutter_test/flutter_test.dart';
import 'package:tryzeon/feature/common/garment_type/domain/entities/garment_type.dart';
import 'package:tryzeon/feature/common/garment_type/presentation/garment_type_display.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/outfit_piece.dart';
import 'package:tryzeon/feature/personal/tryon/presentation/widgets/outfit_piece_label.dart';

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

  test('typeLabel names the garment type, or 照片 for a picked photo', () {
    expect(wardrobe.typeLabel, GarmentType.top.displayName);
    expect(product.typeLabel, GarmentType.top.displayName);
    expect(local.typeLabel, '照片');
  });
}
