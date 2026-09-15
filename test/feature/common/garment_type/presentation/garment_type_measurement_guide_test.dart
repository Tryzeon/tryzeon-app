import 'package:flutter_test/flutter_test.dart';
import 'package:tryzeon/feature/common/garment_type/domain/entities/garment_type.dart';
import 'package:tryzeon/feature/common/garment_type/presentation/garment_type_measurement_guide.dart';

void main() {
  group('GarmentType.measurementGuideAssets', () {
    const top = 'assets/images/size_guide/top.webp';
    const skirt = 'assets/images/size_guide/skirt.webp';
    const pants = 'assets/images/size_guide/pants.webp';

    test('top and outerwear use the top guide', () {
      expect(GarmentType.top.measurementGuideAssets, const [top]);
      expect(GarmentType.outerwear.measurementGuideAssets, const [top]);
    });

    test('skirt and pants use their own guide', () {
      expect(GarmentType.skirt.measurementGuideAssets, const [skirt]);
      expect(GarmentType.pants.measurementGuideAssets, const [pants]);
    });

    test('dress shows the top guide followed by the pants guide', () {
      expect(GarmentType.dress.measurementGuideAssets, const [top, pants]);
    });

    test('others has no guide', () {
      expect(GarmentType.others.measurementGuideAssets, isEmpty);
    });
  });
}
