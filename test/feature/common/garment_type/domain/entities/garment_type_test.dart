import 'package:flutter_test/flutter_test.dart';
import 'package:tryzeon/feature/common/garment_type/domain/entities/garment_type.dart';

void main() {
  group('GarmentType.tryFromString', () {
    test('parses one_piece', () {
      expect(GarmentType.tryFromString('one_piece'), GarmentType.onePiece);
    });

    test('no longer recognises the retired dress value', () {
      expect(GarmentType.tryFromString('dress'), isNull);
    });
  });
}
