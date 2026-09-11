import 'package:flutter_test/flutter_test.dart';
import 'package:tryzeon/feature/common/product_size/domain/entities/measurement_range.dart';
import 'package:tryzeon/feature/personal/shop/domain/services/ease_table.dart';

void main() {
  test('an ease band turns a garment measurement into the body range it fits', () {
    const band = EaseBand(8, 15);
    expect(band.toBodyRange(100), const MeasurementRange(min: 85, max: 92));
  });
}
