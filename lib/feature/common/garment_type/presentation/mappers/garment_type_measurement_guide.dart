import 'package:tryzeon/feature/common/garment_type/domain/entities/garment_type.dart';

const String _topGuide = 'assets/images/size_guide/top.webp';
const String _skirtGuide = 'assets/images/size_guide/skirt.webp';
const String _pantsGuide = 'assets/images/size_guide/pants.webp';

extension GarmentTypeMeasurementGuide on GarmentType {
  List<String> get measurementGuideAssets => switch (this) {
    GarmentType.top || GarmentType.outerwear => const [_topGuide],
    GarmentType.skirt => const [_skirtGuide],
    GarmentType.pants => const [_pantsGuide],
    GarmentType.onePiece => const [_topGuide, _pantsGuide],
    GarmentType.others => const [],
  };
}
