import 'package:tryzeon/feature/common/garment_type/domain/entities/garment_type.dart';

extension GarmentTypeDisplay on GarmentType {
  String get displayName => switch (this) {
    GarmentType.top => '上衣',
    GarmentType.pants => '褲子',
    GarmentType.skirt => '裙子',
    GarmentType.dress => '洋裝',
    GarmentType.outerwear => '外套',
    GarmentType.others => '其他',
  };
}
