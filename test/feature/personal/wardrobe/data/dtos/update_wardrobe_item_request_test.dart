import 'package:flutter_test/flutter_test.dart';
import 'package:tryzeon/feature/common/garment_type/domain/entities/garment_type.dart';
import 'package:tryzeon/feature/personal/wardrobe/data/dtos/update_wardrobe_item_request.dart';

void main() {
  test('sends only the fields being changed', () {
    expect(const UpdateWardrobeItemRequest(garmentType: GarmentType.onePiece).toJson(), {
      'garment_type': 'one_piece',
    });
    expect(const UpdateWardrobeItemRequest(tags: ['denim']).toJson(), {
      'tags': ['denim'],
    });
  });
}
