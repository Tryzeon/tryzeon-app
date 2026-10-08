enum MeasurementUnit {
  centimeter,
  cun,
  inch;

  String get label => switch (this) {
    MeasurementUnit.centimeter => '公分',
    MeasurementUnit.cun => '台寸',
    MeasurementUnit.inch => '英吋',
  };

  double get toCmFactor => switch (this) {
    MeasurementUnit.centimeter => 1.0,
    MeasurementUnit.cun => 3.03,
    MeasurementUnit.inch => 2.54,
  };
}
