import 'package:tryzeon/feature/common/garment_type/domain/entities/garment_type.dart';
import 'package:tryzeon/feature/common/product_size/presentation/mappers/garment_measurement_type_ui_mapper.dart';

extension GarmentTypeDisplay on GarmentType {
  String get displayName => switch (this) {
    GarmentType.top => '上衣',
    GarmentType.pants => '褲子',
    GarmentType.skirt => '裙子',
    GarmentType.dress => '洋裝',
    GarmentType.outerwear => '外套',
    GarmentType.others => '其他',
  };

  String get lengthLabel => switch (this) {
    GarmentType.top || GarmentType.outerwear || GarmentType.dress => '衣長',
    GarmentType.skirt => '裙長',
    GarmentType.pants => '褲長',
    GarmentType.others => '長度',
  };

  String measurementLabel(final GarmentMeasurementType type) =>
      type == GarmentMeasurementType.length ? lengthLabel : type.label;
}
