import 'package:flutter_test/flutter_test.dart';
import 'package:tryzeon/feature/common/garment_type/domain/entities/garment_type.dart';
import 'package:tryzeon/feature/personal/wardrobe/data/dtos/create_wardrobe_item_request.dart';

void main() {
  test('serializes garment_type with the database enum label', () {
    const request = CreateWardrobeItemRequest(
      imagePath: 'u/one_piece/a.jpg',
      garmentType: GarmentType.onePiece,
    );

    expect(request.toJson()['garment_type'], 'one_piece');
  });
}
