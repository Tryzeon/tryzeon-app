import 'package:json_annotation/json_annotation.dart';
import 'package:tryzeon/feature/common/measurement/domain/entities/measurement_unit.dart';

@JsonEnum(valueField: 'value')
enum SpokenUnit {
  centimeter('centimeter'),
  cun('cun'),
  inch('inch'),
  cunAmbiguous('cun_ambiguous'),
  unspecified('unspecified');

  const SpokenUnit(this.value);

  final String value;

  /// A bare 寸 and 吋 sound the same, so the parser cannot tell 台寸 from
  /// 英吋; on a centimeter form it is 英吋, the unit Taiwanese apparel listings
  /// mean by it.
  MeasurementUnit resolve({required final MeasurementUnit formUnit}) =>
      switch (this) {
        SpokenUnit.centimeter => MeasurementUnit.centimeter,
        SpokenUnit.cun => MeasurementUnit.cun,
        SpokenUnit.inch => MeasurementUnit.inch,
        SpokenUnit.cunAmbiguous =>
          formUnit == MeasurementUnit.centimeter
              ? MeasurementUnit.inch
              : formUnit,
        SpokenUnit.unspecified => formUnit,
      };
}
