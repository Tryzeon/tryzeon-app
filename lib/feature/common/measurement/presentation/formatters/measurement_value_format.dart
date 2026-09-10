/// One decimal at most, and none when the value is whole: `42`, `42.5`.
String formatMeasurementValue(final double value) =>
    value.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '');
